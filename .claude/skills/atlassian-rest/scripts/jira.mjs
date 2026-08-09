#!/usr/bin/env node

// Jira REST API v3 CLI — Node.js 18+

import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { markdownToAdf } from 'marklassian';
import { loadEnv } from './loadEnv.mjs';

loadEnv();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function checkEnv() {
  const required = ['ATLASSIAN_API_TOKEN', 'ATLASSIAN_EMAIL', 'ATLASSIAN_DOMAIN'];
  const missing = required.filter((k) => !process.env[k]);
  if (missing.length) {
    console.error(
      `Missing required environment variables:\n${missing.map((k) => `  - ${k}`).join('\n')}\n\n` +
        'Options:\n' +
        '  1. Create a .env file at the project root or skill directory:\n' +
        '       ATLASSIAN_EMAIL=you@example.com\n' +
        '       ATLASSIAN_DOMAIN=yoursite.atlassian.net\n' +
        '       ATLASSIAN_API_TOKEN=your-api-token\n' +
        '  2. Export in your shell:\n' +
        '       export ATLASSIAN_EMAIL="you@example.com"\n' +
        '       export ATLASSIAN_DOMAIN="yoursite.atlassian.net"\n' +
        '       export ATLASSIAN_API_TOKEN="your-api-token"\n' +
        'Run `node setup.mjs` for step-by-step instructions.'
    );
    process.exit(1);
  }
}

function baseUrl() {
  return `https://${process.env.ATLASSIAN_DOMAIN}/rest/api/3`;
}

function authHeader() {
  const cred = Buffer.from(
    `${process.env.ATLASSIAN_EMAIL}:${process.env.ATLASSIAN_API_TOKEN}`
  ).toString('base64');
  return `Basic ${cred}`;
}

async function request(path, { method = 'GET', body, query } = {}) {
  let url = `${baseUrl()}${path}`;
  if (query) {
    const params = new URLSearchParams(query);
    url += `?${params.toString()}`;
  }

  const opts = {
    method,
    headers: {
      Authorization: authHeader(),
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
  };

  if (body) {
    opts.body = JSON.stringify(body);
  }

  const res = await fetch(url, opts);

  if (!res.ok) {
    let detail = '';
    try {
      detail = await res.text();
    } catch {
      // ignore
    }
    console.error(`HTTP ${res.status} ${res.statusText} — ${method} ${url}`);
    if (detail) console.error(detail);
    process.exit(1);
  }

  // Some endpoints return 204 No Content
  if (res.status === 204) return null;

  return res.json();
}

/**
 * Convert text to ADF via marklassian.
 * Handles literal \n sequences from shell arguments.
 */
function toAdf(text) {
  const normalized = (text || '').replace(/\\n/g, '\n');
  return markdownToAdf(normalized);
}

/**
 * Read content from a --<field>-file flag, falling back to the inline --<field> flag.
 */
function readContentFlag(flags, fieldName) {
  const fileFlag = `${fieldName}-file`;
  if (flags[fileFlag]) {
    return readFileSync(flags[fileFlag], 'utf-8');
  }
  return flags[fieldName] || null;
}

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) {
        flags[key] = true;
        i += 1;
      } else {
        flags[key] = next;
        i += 2;
      }
    } else {
      positional.push(arg);
      i += 1;
    }
  }
  return { positional, flags };
}

function requirePositional(positional, index, label) {
  if (positional[index] === undefined) {
    console.error(`Missing required argument: <${label}>`);
    process.exit(1);
  }
  return positional[index];
}

// ---------------------------------------------------------------------------
// Subcommands
// ---------------------------------------------------------------------------

async function cmdSearch(positional, flags) {
  const jql = requirePositional(positional, 0, 'JQL');
  const maxResults = parseInt(flags.max, 10) || 50;

  const data = await request('/search/jql', {
    method: 'POST',
    body: { jql, maxResults, fields: ['summary', 'status', 'assignee', 'priority'] },
  });

  const issues = (data.issues || []).map((i) => ({
    key: i.key,
    summary: i.fields.summary,
    status: i.fields.status?.name,
    assignee: i.fields.assignee?.displayName || null,
    priority: i.fields.priority?.name,
  }));

  console.log(JSON.stringify({ total: data.total, issues }, null, 2));
}

async function cmdGet(positional, flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const query = {};
  if (flags.fields) {
    query.fields = flags.fields;
  }

  const data = await request(`/issue/${key}`, { query });
  console.log(JSON.stringify(data, null, 2));
}

async function cmdCreate(_positional, flags) {
  const project = flags.project;
  const type = flags.type;
  const summary = flags.summary;

  if (!project || !type || !summary) {
    console.error('Required flags: --project, --type, --summary');
    process.exit(1);
  }

  const fields = {
    project: { key: project },
    issuetype: { name: type },
    summary,
  };

  const description = readContentFlag(flags, 'description');
  if (description) {
    fields.description = toAdf(description);
  }
  if (flags.priority) {
    fields.priority = { name: flags.priority };
  }
  if (flags.assignee) {
    fields.assignee = { id: flags.assignee };
  }
  if (flags.parent) {
    fields.parent = { key: flags.parent };
  }
  if (flags.labels) {
    fields.labels = flags.labels.split(',').map((l) => l.trim());
  }
  if (flags.components) {
    fields.components = flags.components.split(',').map((c) => ({ name: c.trim() }));
  }

  const data = await request('/issue', { method: 'POST', body: { fields } });
  console.log(JSON.stringify({ key: data.key, self: data.self }, null, 2));
}

async function cmdEdit(positional, flags) {
  const key = requirePositional(positional, 0, 'issueKey');

  const fields = {};
  if (flags.summary) fields.summary = flags.summary;
  const editDesc = readContentFlag(flags, 'description');
  if (editDesc) fields.description = toAdf(editDesc);
  if (flags.priority) fields.priority = { name: flags.priority };
  if (flags.assignee) fields.assignee = { id: flags.assignee };
  if (flags.labels) fields.labels = flags.labels.split(',').map((l) => l.trim());
  if (flags.components) fields.components = flags.components.split(',').map((c) => ({ name: c.trim() }));

  if (Object.keys(fields).length === 0) {
    console.error('Provide at least one field to update: --summary, --description, --priority, --assignee, --labels, --components');
    process.exit(1);
  }

  await request(`/issue/${key}`, { method: 'PUT', body: { fields } });
  console.log(JSON.stringify({ updated: key }, null, 2));
}

async function cmdComment(positional, flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const body = readContentFlag(flags, 'body') || positional[1];

  if (!body) {
    console.error('Missing required argument: <body> or --body-file');
    process.exit(1);
  }

  const data = await request(`/issue/${key}/comment`, {
    method: 'POST',
    body: { body: toAdf(body) },
  });

  console.log(JSON.stringify({ id: data.id, created: data.created }, null, 2));
}

async function cmdTransitions(positional, _flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const data = await request(`/issue/${key}/transitions`);
  console.log(JSON.stringify(data.transitions, null, 2));
}

async function cmdTransition(positional, _flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const transitionId = requirePositional(positional, 1, 'transitionId');

  await request(`/issue/${key}/transitions`, {
    method: 'POST',
    body: { transition: { id: transitionId } },
  });

  console.log(JSON.stringify({ transitioned: key, transitionId }, null, 2));
}

async function cmdProjects(_positional, _flags) {
  const data = await request('/project/search');
  console.log(JSON.stringify(data.values, null, 2));
}

async function cmdIssueTypes(positional, _flags) {
  const projectKey = requirePositional(positional, 0, 'projectKey');
  const data = await request(`/issue/createmeta/${projectKey}/issuetypes`);
  console.log(JSON.stringify(data.values || data, null, 2));
}

async function cmdLink(positional, flags) {
  const fromKey = requirePositional(positional, 0, 'fromKey');
  const toKey = requirePositional(positional, 1, 'toKey');
  const type = flags.type;

  if (!type) {
    console.error('Required flag: --type (link type name)');
    process.exit(1);
  }

  await request('/issueLink', {
    method: 'POST',
    body: {
      type: { name: type },
      inwardIssue: { key: fromKey },
      outwardIssue: { key: toKey },
    },
  });

  console.log(JSON.stringify({ linked: `${fromKey} -> ${toKey}`, type }, null, 2));
}

async function cmdLinkTypes(_positional, _flags) {
  const data = await request('/issueLinkType');
  console.log(JSON.stringify(data.issueLinkTypes, null, 2));
}

async function cmdLookupUser(positional, _flags) {
  const query = requirePositional(positional, 0, 'query');
  const data = await request('/user/search', { query: { query } });
  console.log(JSON.stringify(data, null, 2));
}

async function cmdWorklog(positional, flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const timeSpent = flags.time;

  if (!timeSpent) {
    console.error('Required flag: --time (e.g. "2h", "30m", "1d")');
    process.exit(1);
  }

  const body = { timeSpent };
  const comment = readContentFlag(flags, 'comment');
  if (comment) {
    body.comment = toAdf(comment);
  }

  const data = await request(`/issue/${key}/worklog`, { method: 'POST', body });
  console.log(JSON.stringify({ id: data.id, timeSpent: data.timeSpent }, null, 2));
}

// ---------------------------------------------------------------------------
// Attachments
// ---------------------------------------------------------------------------

async function requestRaw(path, { method = 'GET', body, extraHeaders } = {}) {
  const url = `${baseUrl()}${path}`;
  const headers = {
    Authorization: authHeader(),
    Accept: 'application/json',
    ...extraHeaders,
  };

  const res = await fetch(url, { method, headers, body });

  if (!res.ok) {
    let detail = '';
    try {
      detail = await res.text();
    } catch {
      // ignore
    }
    console.error(`HTTP ${res.status} ${res.statusText} — ${method} ${url}`);
    if (detail) console.error(detail);
    process.exit(1);
  }

  if (res.status === 204) return null;
  return res.json();
}

async function cmdAttach(positional, flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const filePath = requirePositional(positional, 1, 'filePath');

  const fileData = readFileSync(filePath);
  const blob = new Blob([fileData]);
  const form = new FormData();
  form.append('file', blob, basename(filePath));

  const data = await requestRaw(`/issue/${key}/attachments`, {
    method: 'POST',
    body: form,
    extraHeaders: { 'X-Atlassian-Token': 'no-check' },
  });

  const results = (Array.isArray(data) ? data : [data]).map((a) => ({
    id: a.id,
    filename: a.filename,
    mimeType: a.mimeType || null,
    size: a.size || null,
  }));

  console.log(JSON.stringify(results.length === 1 ? results[0] : results, null, 2));
}

async function cmdListAttachments(positional, _flags) {
  const key = requirePositional(positional, 0, 'issueKey');
  const data = await request(`/issue/${key}`, { query: { fields: 'attachment' } });
  const attachments = (data.fields?.attachment || []).map((a) => ({
    id: a.id,
    filename: a.filename,
    mimeType: a.mimeType || null,
    size: a.size || null,
    created: a.created || null,
  }));
  console.log(JSON.stringify(attachments, null, 2));
}

// ---------------------------------------------------------------------------
// Usage
// ---------------------------------------------------------------------------

function printUsage() {
  console.log(`Usage: jira.mjs <command> [args] [--flags]

Commands:
  search <JQL> [--max N]                         Search issues via JQL
  get <issueKey> [--fields f1,f2]                Get issue details
  create --project P --type T --summary S        Create issue
         [--description D | --description-file F]
         [--priority P] [--assignee A] [--parent EPIC]
         [--labels L1,L2] [--components C1,C2]
  edit <issueKey> [--summary S]                  Update issue
       [--description D | --description-file F]
       [--priority P] [--assignee A]
       [--labels L1,L2] [--components C1,C2]
  comment <issueKey> <body>                      Add comment
  comment <issueKey> --body-file F               Add comment from file
  transitions <issueKey>                         List available transitions
  transition <issueKey> <transitionId>           Transition issue
  projects                                       List visible projects
  issue-types <projectKey>                       Get issue types for project
  link <fromKey> <toKey> --type T                Link two issues
  link-types                                     Get available link types
  lookup-user <query>                            Find user account ID
  worklog <issueKey> --time T                    Add worklog entry
         [--comment C | --comment-file F]
  attach <issueKey> <filePath>                   Attach file to issue
  list-attachments <issueKey>                    List issue attachments

File flags (--*-file) read content from a file instead of a shell argument.
Use for long content or content with special characters (backticks, quotes, $).

Environment variables (required):
  ATLASSIAN_EMAIL    Your Atlassian account email
  ATLASSIAN_API_TOKEN  API token from https://id.atlassian.com/manage-profile/security/api-tokens
  ATLASSIAN_DOMAIN   e.g. yoursite.atlassian.net`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const COMMANDS = {
  search: cmdSearch,
  get: cmdGet,
  create: cmdCreate,
  edit: cmdEdit,
  comment: cmdComment,
  transitions: cmdTransitions,
  transition: cmdTransition,
  projects: cmdProjects,
  'issue-types': cmdIssueTypes,
  link: cmdLink,
  'link-types': cmdLinkTypes,
  'lookup-user': cmdLookupUser,
  worklog: cmdWorklog,
  attach: cmdAttach,
  'list-attachments': cmdListAttachments,
};

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    printUsage();
    process.exit(0);
  }

  const command = args[0];
  const handler = COMMANDS[command];

  if (!handler) {
    console.error(`Unknown command: ${command}`);
    printUsage();
    process.exit(1);
  }

  checkEnv();

  const { positional, flags } = parseArgs(args.slice(1));
  await handler(positional, flags);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
