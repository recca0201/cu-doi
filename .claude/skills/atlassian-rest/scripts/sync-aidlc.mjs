#!/usr/bin/env node

// AIDLC Document ↔ Jira/Confluence Sync Engine — Node.js 18+

import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, unlinkSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { resolve, dirname, basename, join } from 'node:path';
import { createInterface } from 'node:readline';
import { markdownToAdf as mdToAdf } from 'marklassian';
import { markdownToStorage, storageToMarkdown } from './confluence-format.mjs';
import { loadEnv } from './loadEnv.mjs';

loadEnv();

// ---------------------------------------------------------------------------
// Helpers (shared patterns from jira.mjs / confluence.mjs)
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
        '  2. Run: node <skill-path>/scripts/setup.mjs'
    );
    process.exit(1);
  }
}

function jiraBaseUrl() {
  return `https://${process.env.ATLASSIAN_DOMAIN}/rest/api/3`;
}

function confluenceBaseUrl(version = 'v2') {
  const domain = process.env.ATLASSIAN_DOMAIN;
  return version === 'v1'
    ? `https://${domain}/wiki/rest/api`
    : `https://${domain}/wiki/api/v2`;
}

function authHeader() {
  const cred = Buffer.from(
    `${process.env.ATLASSIAN_EMAIL}:${process.env.ATLASSIAN_API_TOKEN}`
  ).toString('base64');
  return `Basic ${cred}`;
}

async function request(url, { method = 'GET', body, query } = {}) {
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
  if (body) opts.body = JSON.stringify(body);

  const res = await fetch(url, opts);
  if (!res.ok) {
    let detail = '';
    try { detail = await res.text(); } catch { /* ignore */ }
    console.error(`HTTP ${res.status} ${res.statusText} — ${method} ${url}`);
    if (detail) console.error(detail);
    process.exit(1);
  }
  if (res.status === 204) return null;
  return res.json();
}

async function deleteIssue(issueKey) {
  const url = `${jiraBaseUrl()}/issue/${issueKey}`;
  const res = await fetch(url, {
    method: 'DELETE',
    headers: { Authorization: authHeader(), Accept: 'application/json' },
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`Failed to delete ${issueKey}: ${res.status} ${res.statusText} ${detail}`);
  }
}

function askConfirmation(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase() === 'y');
    });
  });
}

// ---------------------------------------------------------------------------
// Argument parsing (same as jira.mjs)
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
// Paths — resolve relative to this script's directory
// ---------------------------------------------------------------------------

const SCRIPT_DIR = dirname(new URL(import.meta.url).pathname);
const SKILL_DIR = resolve(SCRIPT_DIR, '..');
const MEMORY_DIR = join(SKILL_DIR, 'memory');
const SYNC_STATE_DIR = join(MEMORY_DIR, 'sync-state');

function ensureDir(dir) {
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
}

function writeTempContent(content, label) {
  const tmpFile = join(SYNC_STATE_DIR, `_tmp_${label}_${Date.now()}.md`);
  ensureDir(SYNC_STATE_DIR);
  writeFileSync(tmpFile, content, 'utf8');
  return tmpFile;
}

function cleanupTemp(tmpFile) {
  try { unlinkSync(tmpFile); } catch { /* ignore */ }
}

// ---------------------------------------------------------------------------
// Simple YAML parser (flat key-value: strings, arrays, booleans)
// ---------------------------------------------------------------------------

function parseSimpleYaml(text) {
  const result = {};
  const lines = text.split('\n');
  let currentKey = null;
  let inArray = false;
  let arrayValues = [];

  for (const line of lines) {
    // Skip comments and empty lines
    if (/^\s*#/.test(line) || /^\s*$/.test(line)) continue;

    // Array item (  - value)
    if (inArray && /^\s+-\s+(.*)/.test(line)) {
      const val = line.match(/^\s+-\s+(.*)/)[1].trim();
      arrayValues.push(unquote(val));
      continue;
    }

    // If we were in an array but hit a non-array line, save it
    if (inArray) {
      result[currentKey] = arrayValues;
      inArray = false;
      arrayValues = [];
      currentKey = null;
    }

    // Key-value pair
    const kvMatch = line.match(/^(\w[\w-]*)\s*:\s*(.*)/);
    if (kvMatch) {
      const key = kvMatch[1].trim();
      const rawVal = kvMatch[2].trim();

      if (rawVal === '' || rawVal === '[]') {
        // Could be start of array block or empty value
        currentKey = key;
        if (rawVal === '[]') {
          result[key] = [];
        } else {
          inArray = true;
          arrayValues = [];
        }
      } else {
        result[key] = parseYamlValue(rawVal);
      }
    }
  }

  // Flush trailing array
  if (inArray && currentKey) {
    result[currentKey] = arrayValues;
  }

  return result;
}

function unquote(s) {
  if ((s.startsWith("'") && s.endsWith("'")) || (s.startsWith('"') && s.endsWith('"'))) {
    return s.slice(1, -1);
  }
  return s;
}

function quoteYamlValue(str) {
  // Use double quotes if value contains single quotes, otherwise use single quotes
  if (str.includes("'")) {
    return `"${str.replace(/"/g, '\\"')}"`;
  }
  return `'${str}'`;
}

function parseYamlValue(raw) {
  if (raw === 'true') return true;
  if (raw === 'false') return false;
  if (raw === 'null') return null;
  // Inline array: [a, b, c]
  if (raw.startsWith('[') && raw.endsWith(']')) {
    return raw.slice(1, -1).split(',').map((v) => unquote(v.trim())).filter(Boolean);
  }
  return unquote(raw);
}

// ---------------------------------------------------------------------------
// BMAD Document Parser
// ---------------------------------------------------------------------------

function parseBmadDoc(content) {
  const lines = content.split('\n');
  let i = 0;
  let frontmatter = {};
  let hasFrontmatter = false;

  // Parse frontmatter
  if (lines[0]?.trim() === '---') {
    hasFrontmatter = true;
    i = 1;
    const fmLines = [];
    while (i < lines.length && lines[i].trim() !== '---') {
      fmLines.push(lines[i]);
      i++;
    }
    i++; // skip closing ---
    frontmatter = parseSimpleYaml(fmLines.join('\n'));
  }

  // Parse sections by heading level
  const sections = [];
  let currentSection = null;
  let preamble = '';

  for (; i < lines.length; i++) {
    const headingMatch = lines[i].match(/^(#{1,6})\s+(.*)/);
    if (headingMatch) {
      currentSection = {
        level: headingMatch[1].length,
        title: headingMatch[2].trim(),
        content: '',
        line: i,
      };
      sections.push(currentSection);
    } else if (currentSection) {
      currentSection.content += lines[i] + '\n';
    } else {
      preamble += lines[i] + '\n';
    }
  }

  // Trim trailing newlines from section content
  for (const s of sections) {
    s.content = s.content.replace(/\n+$/, '');
  }

  return { frontmatter, hasFrontmatter, sections, preamble: preamble.trim(), raw: content };
}

// ---------------------------------------------------------------------------
// Document type detection
// ---------------------------------------------------------------------------

function normalizeLinkedTitle(title) {
  return title?.replace(/^\[[A-Z]+-\d+\]\s+/, '') || '';
}

function detectDocType(parsed) {
  const { frontmatter, sections } = parsed;

  if (frontmatter.workflowType === 'prd') return 'prd';
  if (frontmatter.tech_stack || frontmatter.files_to_modify || frontmatter.code_patterns) return 'story';

  const h1 = sections.find((s) => s.level === 1);
  const title = normalizeLinkedTitle(h1?.title || '');
  const userStorySections = sections.filter((s) => s.level === 2 && /^US-\d+[:\s-]/i.test(s.title));

  if (/user stories/i.test(title) && userStorySections.length > 1) return 'story';
  if (userStorySections.length > 1) return 'story';
  if (userStorySections.length === 1) return 'story';
  if (/^Tech-Spec:/i.test(title)) return 'story';

  const hasArchHeading = sections.some((s) => /^(Technical Design|Architecture|System Design|Infrastructure)/i.test(s.title));
  if (hasArchHeading) return 'architecture';

  return null;
}

function targetForDocType(docType) {
  if (docType === 'story') return 'jira';
  if (docType === 'prd' || docType === 'architecture') return 'confluence';
  return null;
}

function isStoryBundle(parsed, state = null) {
  if (state?.bundleMode === 'story-artifact') return true;
  return extractStories(parsed.sections).length > 1;
}

function getSectionLinkId(childLink) {
  return childLink?.sourceSectionId || childLink?.bmadSectionId || null;
}

// ---------------------------------------------------------------------------
// Hashing
// ---------------------------------------------------------------------------

function computeHash(content) {
  return 'sha256:' + createHash('sha256').update(content, 'utf8').digest('hex');
}

function computeSectionHashes(sections) {
  const hashes = {};
  for (const s of sections) {
    const key = s.title;
    hashes[key] = computeHash(s.content);
  }
  return hashes;
}

function computeDocHash(content) {
  return computeHash(content);
}

// ---------------------------------------------------------------------------
// Sync State persistence
// ---------------------------------------------------------------------------

function stateFileName(filePath) {
  const absPath = resolve(filePath);
  const hash = createHash('sha256').update(absPath, 'utf8').digest('hex').slice(0, 16);
  return `${hash}.json`;
}

function loadSyncState(filePath) {
  ensureDir(SYNC_STATE_DIR);
  const statePath = join(SYNC_STATE_DIR, stateFileName(filePath));
  if (!existsSync(statePath)) return null;
  return JSON.parse(readFileSync(statePath, 'utf8'));
}

function saveSyncState(filePath, state) {
  ensureDir(SYNC_STATE_DIR);
  const statePath = join(SYNC_STATE_DIR, stateFileName(filePath));
  writeFileSync(statePath, JSON.stringify(state, null, 2) + '\n', 'utf8');
}

// ---------------------------------------------------------------------------
// Field Mapping persistence
// ---------------------------------------------------------------------------

function mappingFileName(docType) {
  const target = targetForDocType(docType);
  return `${target}-aidlc-${docType}-field-mapping.json`;
}

function loadFieldMapping(docType) {
  ensureDir(MEMORY_DIR);
  const mapPath = join(MEMORY_DIR, mappingFileName(docType));
  if (!existsSync(mapPath)) return null;
  return JSON.parse(readFileSync(mapPath, 'utf8'));
}

function saveFieldMapping(docType, mapping) {
  ensureDir(MEMORY_DIR);
  const mapPath = join(MEMORY_DIR, mappingFileName(docType));
  writeFileSync(mapPath, JSON.stringify(mapping, null, 2) + '\n', 'utf8');
}

// ---------------------------------------------------------------------------
// Link discovery
// ---------------------------------------------------------------------------

function findLink(parsed) {
  const { frontmatter, sections } = parsed;

  // 1. Check frontmatter
  if (frontmatter.jira_ticket_id) return { target: 'jira', linkId: frontmatter.jira_ticket_id };
  if (frontmatter.confluence_page_id) return { target: 'confluence', linkId: frontmatter.confluence_page_id };

  // 2. Check title for [KEY-123] pattern
  const h1 = sections.find((s) => s.level === 1);
  if (h1) {
    const m = h1.title.match(/^\[([A-Z]+-\d+)\]\s*/);
    if (m) return { target: 'jira', linkId: m[1] };
    const pageM = h1.title.match(/^\[page:(\d+)\]\s*/);
    if (pageM) return { target: 'confluence', linkId: pageM[1] };
  }

  return null;
}

// ---------------------------------------------------------------------------
// Write link back to document
// ---------------------------------------------------------------------------

function addLinkToDoc(filePath, parsed, target, linkId) {
  let content = parsed.raw;

  if (parsed.hasFrontmatter) {
    // Add to YAML frontmatter
    const prop = target === 'jira' ? 'jira_ticket_id' : 'confluence_page_id';
    const lines = content.split('\n');
    // Find second --- and insert before it
    let dashCount = 0;
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].trim() === '---') {
        dashCount++;
        if (dashCount === 2) {
          lines.splice(i, 0, `${prop}: '${linkId}'`);
          break;
        }
      }
    }
    content = lines.join('\n');
  } else {
    // Prefix title with [KEY]
    const h1Match = content.match(/^(#{1,6}\s+)(.*)/m);
    if (h1Match) {
      const prefix = target === 'jira' ? `[${linkId}] ` : `[page:${linkId}] `;
      content = content.replace(/^(#{1,6}\s+)(.*)/m, `$1${prefix}$2`);
    }
  }

  writeFileSync(filePath, content, 'utf8');
  return content;
}

// ---------------------------------------------------------------------------
// Story extraction from epic docs
// ---------------------------------------------------------------------------

function extractStories(sections) {
  const stories = [];
  let currentStory = null;

  for (const s of sections) {
    const storyMatch = s.title.match(/^US-(\d+)[:\s-]+(.*)/i);
    if (storyMatch && (s.level === 2 || s.level === 3) && s.title.startsWith('US-')) {
      if (currentStory) stories.push(currentStory);
      currentStory = {
        id: `US-${storyMatch[1]}: ${storyMatch[2]}`,
        number: storyMatch[1],
        title: storyMatch[2],
        heading: s.title,
        content: s.content,
        level: s.level,
      };
    } else if (currentStory && s.level > currentStory.level) {
      currentStory.content += `\n${'#'.repeat(s.level)} ${s.title}\n${s.content}`;
    } else {
      if (currentStory) stories.push(currentStory);
      currentStory = null;
    }
  }

  if (currentStory) stories.push(currentStory);
  return stories;
}

function extractUsReferences(text) {
  const matches = text?.match(/US-\d+/g) || [];
  const seen = new Set();
  const ordered = [];
  for (const match of matches) {
    if (!seen.has(match)) {
      seen.add(match);
      ordered.push(match);
    }
  }
  return ordered;
}

function referencesAllUserStories(text) {
  return /\ball user stor(?:y|ies)\b/i.test(text || '');
}

function extractRelatedJiraKey(content) {
  const match = content?.match(/^\*\*Related Jira\*\*(?: \(optional, sync only\))?:\s*([A-Z]+-\d+)$/mi);
  return match?.[1] || null;
}

function parseTaskPlan(content) {
  const lines = content.split('\n');
  const tasks = [];
  let inChecklist = false;
  let currentTask = null;

  for (const line of lines) {
    if (!inChecklist) {
      if (/^##\s+Implementation Checklist\s*$/i.test(line.trim())) {
        inChecklist = true;
      }
      continue;
    }

    if (/^##\s+/.test(line)) break;

    const taskMatch = line.match(/^- \[([ xX])\]\s+(\d+)\.\s+(.*)$/);
    if (taskMatch) {
      if (currentTask) tasks.push(currentTask);
      currentTask = {
        taskId: taskMatch[2],
        summary: taskMatch[3].trim(),
        checked: taskMatch[1].toLowerCase() === 'x',
        bulletLines: [],
        referenceLine: null,
        referencedUs: [],
      };
      continue;
    }

    if (!currentTask) continue;

    const bulletMatch = line.match(/^\s{2,}-\s+(.*)$/);
    if (bulletMatch) {
      const value = bulletMatch[1].trim();
      currentTask.bulletLines.push(value);
      if (value.startsWith('Reference:')) {
        currentTask.referenceLine = value.replace(/^Reference:\s*/, '').trim();
        currentTask.referencedUs = extractUsReferences(currentTask.referenceLine);
      }
    }
  }

  if (currentTask) tasks.push(currentTask);
  return tasks;
}

function loadTaskPlanStoryMap(taskFilePath) {
  const requirementsPath = join(dirname(taskFilePath), 'requirements.md');
  if (!existsSync(requirementsPath)) {
    console.error(`Sibling requirements.md not found: ${requirementsPath}`);
    process.exit(1);
  }

  const requirementsContent = readFileSync(requirementsPath, 'utf8');
  const parsed = parseBmadDoc(requirementsContent);
  const stories = extractStories(parsed.sections);
  const storyMap = {};

  for (const story of stories) {
    const usId = `US-${story.number}`;
    storyMap[usId] = {
      usId,
      title: story.title,
      jiraKey: extractRelatedJiraKey(story.content),
    };
  }

  return { requirementsPath, storyMap };
}

function detectSubtaskType(projectKey) {
  const issueTypes = jira('issue-types', projectKey)?.issueTypes || [];
  const preferred = issueTypes.find((type) => type.subtask && /^Subtask$/i.test(type.name));
  if (preferred) return preferred.name;
  const fallback = issueTypes.find((type) => type.subtask);
  if (!fallback) {
    console.error(`No subtask issue type found for Jira project ${projectKey}`);
    process.exit(1);
  }
  return fallback.name;
}

function buildTaskPlanDescription(task, target) {
  const detailBullets = task.bulletLines
    .filter((line) => !line.startsWith('Reference:'))
    .map((line) => `- ${line}`);

  const lines = [
    '## Task Details',
    ...(detailBullets.length > 0 ? detailBullets : ['- No additional task details were provided in tasks.md.']),
    '',
    '## Source Metadata',
    '',
    `**AIDLC Task ID:** ${task.taskId}`,
    '',
    `**Source file:** ${task.sourceFile}`,
    '',
    `**Reference line:** ${task.referenceLine || 'none'}`,
    '',
    `**Referenced US:** ${task.referencedUs.join(', ')}`,
    '',
    `**Parent Jira story:** ${target.parentKey}`,
    '',
    `**Parent US:** ${target.usId}`,
    '',
    `**Local completion state:** ${task.checked ? 'checked' : 'unchecked'}`,
  ];

  return lines.join('\n');
}

function findExistingTaskSubtask(parentKey, summary) {
  const jql = `parent = ${parentKey}`;
  const result = jira('search', jql, '--max', '10');
  return result.issues?.find((issue) => issue.summary === summary) || null;
}

function buildTaskPlanSyncPlan(taskFilePath) {
  const absPath = resolve(taskFilePath);
  if (!existsSync(absPath)) {
    console.error(`File not found: ${absPath}`);
    process.exit(1);
  }

  const content = readFileSync(absPath, 'utf8');
  const tasks = parseTaskPlan(content);
  const { requirementsPath, storyMap } = loadTaskPlanStoryMap(absPath);
  const specSlug = basename(dirname(absPath));
  const plan = [];

  for (const task of tasks) {
    const referencedUs = task.referencedUs.length
      ? task.referencedUs
      : referencesAllUserStories(task.referenceLine)
        ? Object.keys(storyMap)
        : [];

    if (!referencedUs.length) {
      console.error(`Task ${task.taskId} has no usable US reference in ${absPath}`);
      process.exit(1);
    }

    for (const usId of referencedUs) {
      const story = storyMap[usId];
      if (!story?.jiraKey) {
        console.error(`Missing Jira link for ${usId} in ${requirementsPath}`);
        process.exit(1);
      }

      const existing = findExistingTaskSubtask(story.jiraKey, task.summary);
      plan.push({
        ...task,
        referencedUs,
        sourceFile: absPath,
        sourceFileRelative: absPath.replace(resolve(process.cwd()) + '/', ''),
        specSlug,
        usId,
        parentKey: story.jiraKey,
        parentSummary: story.title,
        action: existing ? 'update' : 'create',
        existingKey: existing?.key || null,
      });
    }
  }

  return { absPath, requirementsPath, specSlug, tasks, plan };
}

async function syncTaskPlanEntries(planEntries) {
  const projectKeys = [...new Set(planEntries.map((entry) => entry.parentKey.replace(/-\d+$/, '')))];
  if (projectKeys.length !== 1) {
    console.error(`Expected one Jira project for task-plan sync, found: ${projectKeys.join(', ')}`);
    process.exit(1);
  }

  const projectKey = projectKeys[0];
  const subtaskType = detectSubtaskType(projectKey);
  const results = [];

  for (const entry of planEntries) {
    const description = buildTaskPlanDescription(entry, entry);
    const tmpDescFile = writeTempContent(description, `task_${entry.taskId}_${entry.usId}`);

    if (entry.existingKey) {
      jira('edit', entry.existingKey, '--summary', entry.summary, '--description-file', tmpDescFile);
      results.push({
        action: 'updated',
        key: entry.existingKey,
        parentKey: entry.parentKey,
        usId: entry.usId,
        taskId: entry.taskId,
        needsTransitionReview: entry.checked,
      });
    } else {
      const created = jira(
        'create',
        '--project', projectKey,
        '--type', subtaskType,
        '--summary', entry.summary,
        '--parent', entry.parentKey,
        '--description-file', tmpDescFile,
      );
      results.push({
        action: 'created',
        key: created.key,
        parentKey: entry.parentKey,
        usId: entry.usId,
        taskId: entry.taskId,
        needsTransitionReview: entry.checked,
      });
    }

    cleanupTemp(tmpDescFile);
  }

  return { projectKey, subtaskType, results };
}

function formatAidlcStoryHeading(number, summary) {
  return `US-${String(number).padStart(3, '0')}: ${summary || ''}`;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function stripSyncOnlyReferenceLines(content) {
  return (content || '')
    .replace(/^\*\*Related (ADO|Jira)\*\*(?: \(optional, sync only\))?:\s*.*$/gmi, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function storyContentForRemote(content) {
  return stripSyncOnlyReferenceLines(content);
}

function upsertStorySyncReference(content, label, value) {
  const referenceLine = label === 'Related Jira'
    ? `**${label}**: ${value}`
    : `**${label}** (optional, sync only): ${value}`;
  const referenceRegex = new RegExp(`^\\*\\*${escapeRegExp(label)}\\*\\*(?: \\(optional, sync only\\))?:\\s*.*$`, 'gmi');
  const withoutExisting = (content || '')
    .replace(referenceRegex, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  if (!withoutExisting) return referenceLine;

  const relatedAdoRegex = /^(\*\*Related ADO\*\*(?: \(optional, sync only\))?:.*)$/mi;
  if (relatedAdoRegex.test(withoutExisting)) {
    return withoutExisting.replace(relatedAdoRegex, `$1\n${referenceLine}`).replace(/\n{3,}/g, '\n\n').trim();
  }

  const priorityRegex = /^(\*\*Priority\*\*:.*)$/mi;
  if (priorityRegex.test(withoutExisting)) {
    return withoutExisting.replace(priorityRegex, `${referenceLine}\n\n$1`).replace(/\n{3,}/g, '\n\n').trim();
  }

  const userStoryRegex = /^(\*\*User Story\*\*:.*)$/mi;
  if (userStoryRegex.test(withoutExisting)) {
    return withoutExisting.replace(userStoryRegex, `$1\n\n${referenceLine}`).replace(/\n{3,}/g, '\n\n').trim();
  }

  return `${referenceLine}\n\n${withoutExisting}`.trim();
}

function addRelatedJiraReference(content, jiraKey) {
  return upsertStorySyncReference(content, 'Related Jira', jiraKey);
}

// ---------------------------------------------------------------------------
// Markdown ↔ ADF conversion (using marklassian)
// ---------------------------------------------------------------------------

function markdownToAdf(markdown) {
  return mdToAdf(markdown || '');
}

function adfToMarkdown(adf) {
  if (!adf || !adf.content) return '';
  return adf.content.map(nodeToMarkdown).join('\n\n');
}

function nodeToMarkdown(node) {
  switch (node.type) {
    case 'paragraph':
      return inlineNodesToMd(node.content || []);
    case 'heading':
      return '#'.repeat(node.attrs?.level || 1) + ' ' + inlineNodesToMd(node.content || []);
    case 'bulletList':
      return (node.content || []).map((li) =>
        '- ' + (li.content || []).map(nodeToMarkdown).join('\n')
      ).join('\n');
    case 'orderedList':
      return (node.content || []).map((li, idx) =>
        `${idx + 1}. ` + (li.content || []).map(nodeToMarkdown).join('\n')
      ).join('\n');
    case 'codeBlock': {
      const lang = node.attrs?.language || '';
      const text = (node.content || []).map((c) => c.text || '').join('');
      return '```' + lang + '\n' + text + '\n```';
    }
    case 'blockquote':
      return (node.content || []).map(nodeToMarkdown).map((l) => '> ' + l).join('\n');
    case 'rule':
      return '---';
    case 'table':
      return tableNodeToMd(node);
    case 'listItem':
      return (node.content || []).map(nodeToMarkdown).join('\n');
    default:
      return inlineNodesToMd(node.content || []);
  }
}

function tableNodeToMd(node) {
  const rows = (node.content || []).map((row) =>
    (row.content || []).map((cell) =>
      (cell.content || []).map(nodeToMarkdown).join(' ')
    )
  );
  if (rows.length === 0) return '';
  const header = '| ' + rows[0].join(' | ') + ' |';
  const sep = '| ' + rows[0].map(() => '---').join(' | ') + ' |';
  const body = rows.slice(1).map((r) => '| ' + r.join(' | ') + ' |').join('\n');
  return [header, sep, body].filter(Boolean).join('\n');
}

function inlineNodesToMd(nodes) {
  return (nodes || []).map((n) => {
    let text = n.text || '';
    if (n.marks) {
      for (const mark of n.marks) {
        if (mark.type === 'strong') text = `**${text}**`;
        if (mark.type === 'em') text = `*${text}*`;
        if (mark.type === 'code') text = '`' + text + '`';
        if (mark.type === 'link') text = `[${text}](${mark.attrs?.href || ''})`;
      }
    }
    return text;
  }).join('');
}

// Confluence storage format conversion now imported from confluence-format.mjs

// ---------------------------------------------------------------------------
// Document rebuilding
// ---------------------------------------------------------------------------

function rebuildDoc(frontmatter, hasFrontmatter, sections, preamble) {
  const parts = [];

  if (hasFrontmatter) {
    parts.push('---');
    for (const [key, val] of Object.entries(frontmatter)) {
      if (Array.isArray(val)) {
        if (val.length === 0) {
          parts.push(`${key}: []`);
        } else {
          parts.push(`${key}:`);
          for (const item of val) {
            parts.push(`  - ${typeof item === 'string' ? quoteYamlValue(item) : item}`);
          }
        }
      } else if (typeof val === 'string') {
        parts.push(`${key}: ${quoteYamlValue(val)}`);
      } else if (val === null) {
        parts.push(`${key}: null`);
      } else {
        parts.push(`${key}: ${val}`);
      }
    }
    parts.push('---');
    parts.push('');
  }

  if (preamble) {
    parts.push(preamble);
    parts.push('');
  }

  for (const s of sections) {
    parts.push('#'.repeat(s.level) + ' ' + s.title);
    if (s.content) {
      parts.push(s.content);
    }
    parts.push('');
  }

  return parts.join('\n').replace(/\n{3,}/g, '\n\n').trimEnd() + '\n';
}

// ---------------------------------------------------------------------------
// Diff logic
// ---------------------------------------------------------------------------

function diffSections(localSections, remoteSections, stateHashes) {
  const diffs = [];

  const localHashes = computeSectionHashes(localSections);
  const remoteHashes = {};
  for (const s of remoteSections) {
    remoteHashes[s.title] = computeHash(s.content);
  }

  // All known section titles
  const allTitles = new Set([
    ...Object.keys(localHashes),
    ...Object.keys(remoteHashes),
    ...Object.keys(stateHashes || {}),
  ]);

  for (const title of allTitles) {
    const local = localHashes[title];
    const remote = remoteHashes[title];
    const synced = stateHashes?.[title];

    const localChanged = local !== synced;
    const remoteChanged = remote !== synced;

    let status;
    if (!local && remote) {
      status = remoteChanged ? 'added-remote' : 'remote-only';
    } else if (local && !remote) {
      status = localChanged ? 'added-local' : 'local-only';
    } else if (localChanged && remoteChanged) {
      status = 'conflict';
    } else if (localChanged) {
      status = 'local-changed';
    } else if (remoteChanged) {
      status = 'remote-changed';
    } else {
      status = 'unchanged';
    }

    diffs.push({
      title,
      status,
      localHash: local || null,
      remoteHash: remote || null,
      syncedHash: synced || null,
    });
  }

  return diffs;
}

// ---------------------------------------------------------------------------
// Shell out to jira.mjs / confluence.mjs
// ---------------------------------------------------------------------------

function runScript(scriptName, args) {
  const scriptPath = join(SCRIPT_DIR, scriptName);
  try {
    const result = execFileSync('node', [scriptPath, ...args], {
      encoding: 'utf8',
      env: process.env,
      maxBuffer: 10 * 1024 * 1024,
    });
    return JSON.parse(result);
  } catch (err) {
    console.error(`Error running ${scriptName}: ${err.stderr || err.message}`);
    process.exit(1);
  }
}

function jira(...args) { return runScript('jira.mjs', args); }
function confluence(...args) { return runScript('confluence.mjs', args); }

// ---------------------------------------------------------------------------
// Subcommands
// ---------------------------------------------------------------------------

async function cmdStatus(positional, _flags) {
  const filePath = requirePositional(positional, 0, 'file');
  const absPath = resolve(filePath);

  if (!existsSync(absPath)) {
    console.error(`File not found: ${absPath}`);
    process.exit(1);
  }

  const content = readFileSync(absPath, 'utf8');
  const parsed = parseBmadDoc(content);
  const docType = detectDocType(parsed);
  const target = targetForDocType(docType);
  const link = findLink(parsed);
  const state = loadSyncState(absPath);
  const mapping = loadFieldMapping(docType);
  if (mapping?.instructions) {
    console.log(`\n📋 Mapping instructions for "${docType}":\n   ${mapping.instructions}\n`);
  }

  const result = {
    file: absPath,
    docType,
    target,
    linked: !!(link || state?.linkId || (state?.childLinks && state.childLinks.length > 0)),
    linkId: link?.linkId || state?.linkId || null,
    hasFrontmatter: parsed.hasFrontmatter,
    hasMapping: !!mapping,
    sectionCount: parsed.sections.length,
  };

  if (state?.childLinks?.length) {
    result.childLinkCount = state.childLinks.length;
  }

  if (state) {
    const currentHash = computeDocHash(content);
    result.localChanged = currentHash !== state.localHash;
    result.lastSyncedAt = state.lastSyncedAt;
    result.lastSyncDirection = state.lastSyncDirection;
  }

  console.log(JSON.stringify(result, null, 2));
}

async function cmdSyncTaskPlan(positional, flags) {
  const filePath = requirePositional(positional, 0, 'file');
  checkEnv();

  const planState = buildTaskPlanSyncPlan(filePath);
  const preview = {
    file: planState.absPath,
    requirementsFile: planState.requirementsPath,
    specSlug: planState.specSlug,
    apply: !!flags.apply,
    entries: planState.plan.map((entry) => ({
      taskId: entry.taskId,
      summary: entry.summary,
      referencedUs: entry.referencedUs,
      targetUs: entry.usId,
      parentKey: entry.parentKey,
      action: entry.action,
      existingKey: entry.existingKey,
      checked: entry.checked,
    })),
  };

  if (!flags.apply) {
    preview.nextStep = 'Re-run with --apply to create or update the Jira subtasks.';
    console.log(JSON.stringify(preview, null, 2));
    return;
  }

  const syncResult = await syncTaskPlanEntries(planState.plan);
  console.log(JSON.stringify({ ...preview, ...syncResult }, null, 2));
}

async function cmdLink(positional, flags) {
  const filePath = requirePositional(positional, 0, 'file');
  const absPath = resolve(filePath);
  const content = readFileSync(absPath, 'utf8');
  const parsed = parseBmadDoc(content);
  const docType = flags.type || detectDocType(parsed);

  if (!docType) {
    console.error('Cannot detect document type. Use --type <story|prd|architecture>');
    process.exit(1);
  }

  const target = targetForDocType(docType);
  let linkId;

  if (target === 'jira') {
    const stories = extractStories(parsed.sections);
    const bundleMode = stories.length > 1;

    if (flags.ticket) {
      if (bundleMode) {
        console.error('Linking a multi-story AIDLC artifact to a single Jira ticket is not supported. Use --project <KEY> --create.');
        process.exit(1);
      }
      // Link to existing ticket
      linkId = flags.ticket;
    } else if (flags.project && flags.create) {
      checkEnv();
      if (stories.length === 0) {
        console.error('No user stories (US-N sections) found in document. Cannot sync — fix the headings and retry.');
        process.exit(1);
      }
      if (bundleMode) {
        const childLinks = [];
        for (const story of stories) {
          const storyArgs = ['create', '--project', flags.project, '--type', 'Story', '--summary', story.title];
          let tmpStoryFile;
          const storyBody = storyContentForRemote(story.content);
          if (storyBody) {
            tmpStoryFile = writeTempContent(storyBody, 'desc');
            storyArgs.push('--description-file', tmpStoryFile);
          }
          const storyResult = jira(...storyArgs);
          if (tmpStoryFile) cleanupTemp(tmpStoryFile);
          console.error(`  Created Story: ${storyResult.key} — ${story.title}`);
          const storySection = parsed.sections.find((s) => s.title === story.id);
          const linkedStoryContent = storySection
            ? addRelatedJiraReference(storySection.content, storyResult.key)
            : addRelatedJiraReference(story.content, storyResult.key);
          if (storySection) storySection.content = linkedStoryContent;
          const syncedHash = computeHash(storyContentForRemote(linkedStoryContent));
          childLinks.push({
            sourceSectionId: story.id,
            remoteId: storyResult.key,
            localHash: syncedHash,
            remoteHash: syncedHash,
          });
        }
        const linkedBundleContent = rebuildDoc(parsed.frontmatter, parsed.hasFrontmatter, parsed.sections, parsed.preamble);
        writeFileSync(absPath, linkedBundleContent, 'utf8');
        saveSyncState(absPath, {
          '$schema': 'sync-state-v1',
          localFilePath: absPath,
          docType: 'story',
          target,
          linkId: null,
          bundleMode: 'story-artifact',
          linkedAt: new Date().toISOString(),
          lastSyncedAt: new Date().toISOString(),
          lastSyncDirection: 'local-to-remote',
          localHash: computeDocHash(linkedBundleContent),
          remoteHash: null,
          childLinks,
          sectionHashes: computeSectionHashes(parsed.sections),
        });
        console.log(JSON.stringify({ linked: null, children: childLinks.map((c) => c.remoteId), bundleMode: 'story-artifact' }, null, 2));
        return;
      }

      const h1 = parsed.sections.find((s) => s.level === 1);
      const summary = h1?.title || parsed.frontmatter?.title || basename(absPath, '.md');
      const overview = parsed.sections.find((s) => /^Overview$/i.test(s.title));
      const descArgs = ['create', '--project', flags.project, '--type', 'Story', '--summary', summary];
      let tmpDescFile;
      if (overview) {
        tmpDescFile = writeTempContent(overview.content.trim(), 'desc');
        descArgs.push('--description-file', tmpDescFile);
      }

      const result = jira(...descArgs);
      if (tmpDescFile) cleanupTemp(tmpDescFile);
      linkId = result.key;
      console.error(`Created Story: ${linkId}`);
    } else {
      console.error('For Jira: use --ticket <KEY> or --project <KEY> --create');
      process.exit(1);
    }
  } else {
    // Confluence
    if (flags['page-id']) {
      linkId = flags['page-id'];
    } else if (flags.space && flags.create) {
      checkEnv();
      const h1 = parsed.sections.find((s) => s.level === 1);
      const title = h1?.title || parsed.frontmatter?.title || parsed.frontmatter?.project_name || basename(absPath, '.md');
      const body = markdownToStorage(parsed.sections.map((s) => '#'.repeat(s.level) + ' ' + s.title + '\n' + s.content).join('\n\n'));

      // Write body to temp file for large content
      const tmpFile = join(SYNC_STATE_DIR, '_tmp_body.html');
      ensureDir(SYNC_STATE_DIR);
      writeFileSync(tmpFile, body, 'utf8');

      const result = confluence('create-page', '--space', flags.space, '--title', title, '--body-file', tmpFile);
      linkId = result.id?.toString() || result.id;
      console.error(`Created Confluence page: ${linkId}`);

      // Cleanup temp file
      try { unlinkSync(tmpFile); } catch { /* ignore */ }
    } else {
      console.error('For Confluence: use --page-id <ID> or --space <KEY> --create');
      process.exit(1);
    }
  }

  // Save sync state
  const docHash = computeDocHash(content);
  const linkedContent = addLinkToDoc(absPath, parsed, target, linkId);
  let finalLinkedContent = linkedContent;
  if (target === 'jira' && docType === 'story') {
    const linkedParsed = parseBmadDoc(linkedContent);
    const linkedStories = extractStories(linkedParsed.sections);
    if (linkedStories.length === 1) {
      const storySection = linkedParsed.sections.find((s) => s.title === linkedStories[0].id);
      if (storySection) {
        storySection.content = addRelatedJiraReference(storySection.content, linkId);
        finalLinkedContent = rebuildDoc(linkedParsed.frontmatter, linkedParsed.hasFrontmatter, linkedParsed.sections, linkedParsed.preamble);
        writeFileSync(absPath, finalLinkedContent, 'utf8');
      }
    }
  }
  saveSyncState(absPath, {
    '$schema': 'sync-state-v1',
    localFilePath: absPath,
    docType,
    target,
    linkId,
    linkedAt: new Date().toISOString(),
    lastSyncedAt: new Date().toISOString(),
    lastSyncDirection: 'local-to-remote',
    localHash: computeDocHash(finalLinkedContent),
    remoteHash: docHash,
    childLinks: [],
    sectionHashes: computeSectionHashes(parseBmadDoc(finalLinkedContent).sections),
  });
  console.log(JSON.stringify({ linked: linkId, docType, target }, null, 2));
}

async function cmdPush(positional, _flags) {
  const filePath = requirePositional(positional, 0, 'file');
  const absPath = resolve(filePath);
  const content = readFileSync(absPath, 'utf8');
  const parsed = parseBmadDoc(content);
  const state = loadSyncState(absPath);

  if (!state) {
    console.error('Document is not linked. Run: sync-aidlc.mjs link <file> first');
    process.exit(1);
  }

  checkEnv();
  const mapping = loadFieldMapping(state.docType);
  if (mapping?.instructions) {
    console.log(`\n📋 Mapping instructions for "${state.docType}":\n   ${mapping.instructions}\n`);
  }
  const results = [];
  const bundleMode = isStoryBundle(parsed, state);

  if (state.target === 'jira') {
    if (bundleMode) {
      const stories = extractStories(parsed.sections);
      const existingLinks = state.childLinks || [];
      const projectKey = loadFieldMapping('story')?.projectKey || existingLinks[0]?.remoteId?.replace(/-\d+$/, '') || null;
      let docChanged = false;

      for (const story of stories) {
        const existing = existingLinks.find((cl) => getSectionLinkId(cl) === story.id);
        const storyHash = computeHash(storyContentForRemote(story.content));

        if (existing) {
          const linkedStoryContent = addRelatedJiraReference(story.content, existing.remoteId);
          if (linkedStoryContent !== story.content) {
            const storySection = parsed.sections.find((s) => s.title === story.id);
            if (storySection) storySection.content = linkedStoryContent;
            docChanged = true;
          }
          if (storyHash !== existing.localHash) {
            const tmpEditFile = writeTempContent(storyContentForRemote(story.content), 'desc');
            jira('edit', existing.remoteId, '--summary', story.title, '--description-file', tmpEditFile);
            cleanupTemp(tmpEditFile);
            existing.localHash = storyHash;
            existing.remoteHash = storyHash;
            results.push({ action: 'pushed', target: existing.remoteId, section: story.id, status: 'updated' });
          }
        } else {
          if (!projectKey) {
            console.error('Cannot determine Jira project key for story bundle push. Add projectKey to jira-aidlc-story-field-mapping.json.');
            process.exit(1);
          }
          const tmpNewFile = writeTempContent(storyContentForRemote(story.content), 'desc');
          const storyResult = jira('create', '--project', projectKey, '--type', 'Story', '--summary', story.title, '--description-file', tmpNewFile);
          cleanupTemp(tmpNewFile);
          const storySection = parsed.sections.find((s) => s.title === story.id);
          const linkedStoryContent = addRelatedJiraReference(story.content, storyResult.key);
          if (storySection) storySection.content = linkedStoryContent;
          docChanged = true;
          existingLinks.push({
            sourceSectionId: story.id,
            remoteId: storyResult.key,
            localHash: storyHash,
            remoteHash: storyHash,
          });
          results.push({ action: 'pushed', target: storyResult.key, section: story.id, status: 'created' });
        }
      }

      const currentIds = stories.map((s) => s.id);
      const orphaned = existingLinks.filter((cl) => !currentIds.includes(getSectionLinkId(cl)));
      for (const orphan of orphaned) {
        results.push({ action: 'orphaned', target: orphan.remoteId, section: getSectionLinkId(orphan), status: 'manual-cleanup-required' });
      }

      state.docType = 'story';
      state.linkId = null;
      state.bundleMode = 'story-artifact';
      state.childLinks = existingLinks;

      if (docChanged) {
        const updatedContent = rebuildDoc(parsed.frontmatter, parsed.hasFrontmatter, parsed.sections, parsed.preamble);
        writeFileSync(absPath, updatedContent, 'utf8');
      }
    } else if (mapping) {
      const editArgs = [state.linkId];
      const customFields = {};
      let tmpDescFile;
      for (const fm of mapping.fieldMappings || []) {
        const value = extractMappedValue(parsed, fm);
        if (value === null) continue;
        if (fm.jiraFieldId === 'summary') {
          editArgs.push('--summary', value);
        } else if (fm.jiraFieldId === 'description') {
          tmpDescFile = writeTempContent(value, 'desc');
          editArgs.push('--description-file', tmpDescFile);
        } else if (fm.jiraFieldId.startsWith('customfield_')) {
          // Custom fields — build body for direct API call
          if (fm.transform === 'markdownToAdf') {
            customFields[fm.jiraFieldId] = markdownToAdf(value);
          } else {
            customFields[fm.jiraFieldId] = value;
          }
        }
      }
      if (editArgs.length > 1) {
        jira('edit', ...editArgs);
        if (tmpDescFile) cleanupTemp(tmpDescFile);
        results.push({ action: 'pushed', target: state.linkId, status: 'updated' });
      } else if (tmpDescFile) {
        cleanupTemp(tmpDescFile);
      }
      // Push custom fields via direct API call
      if (Object.keys(customFields).length > 0) {
        await request(`${jiraBaseUrl()}/issue/${state.linkId}`, {
          method: 'PUT',
          body: { fields: customFields },
        });
        results.push({ action: 'pushed', target: state.linkId, fields: Object.keys(customFields), status: 'custom-fields-updated' });
      }
    } else {
      const h1 = parsed.sections.find((s) => s.level === 1);
      const overview = parsed.sections.find((s) => /^Overview$/i.test(s.title));
      const editArgs = [state.linkId];
      let tmpFallbackFile;
      if (h1) editArgs.push('--summary', h1.title);
      if (overview) {
        tmpFallbackFile = writeTempContent(overview.content.trim(), 'desc');
        editArgs.push('--description-file', tmpFallbackFile);
      }
      if (editArgs.length > 1) {
        jira('edit', ...editArgs);
        results.push({ action: 'pushed', target: state.linkId, status: 'updated' });
      }
      if (tmpFallbackFile) cleanupTemp(tmpFallbackFile);
    }
  } else {
    const h1 = parsed.sections.find((s) => s.level === 1);
    const title = h1?.title || parsed.frontmatter?.title || parsed.frontmatter?.project_name || '';
    const body = markdownToStorage(parsed.sections.map((s) => '#'.repeat(s.level) + ' ' + s.title + '\n' + s.content).join('\n\n'));

    const tmpFile = join(SYNC_STATE_DIR, '_tmp_body.html');
    ensureDir(SYNC_STATE_DIR);
    writeFileSync(tmpFile, body, 'utf8');

    confluence('update-page', state.linkId, '--title', title, '--body-file', tmpFile);
    results.push({ action: 'pushed', target: `page:${state.linkId}`, status: 'updated' });

    try { unlinkSync(tmpFile); } catch { /* ignore */ }
  }

  // Update sync state
  const finalContent = readFileSync(absPath, 'utf8');
  const newHash = computeDocHash(finalContent);
  state.localHash = newHash;
  state.remoteHash = state.linkId ? newHash : null;
  state.lastSyncedAt = new Date().toISOString();
  state.lastSyncDirection = 'local-to-remote';
  state.sectionHashes = computeSectionHashes(parsed.sections);
  saveSyncState(absPath, state);

  console.log(JSON.stringify({ results }, null, 2));
}

async function cmdPull(positional, _flags) {
  const filePath = requirePositional(positional, 0, 'file');
  const absPath = resolve(filePath);
  const content = readFileSync(absPath, 'utf8');
  const parsed = parseBmadDoc(content);
  const state = loadSyncState(absPath);

  if (!state) {
    console.error('Document is not linked. Run: sync-aidlc.mjs link <file> first');
    process.exit(1);
  }

  checkEnv();
  const results = [];
  const bundleMode = isStoryBundle(parsed, state);

  if (state.target === 'jira') {
    if (bundleMode) {
      const existingLinks = state.childLinks || [];

      for (const existing of existingLinks) {
        const child = jira('get', existing.remoteId, '--fields', 'summary,status,description');
        const childSummary = child.fields?.summary || '';
        const childDesc = child.fields?.description ? adfToMarkdown(child.fields.description) : '';
        const sourceSectionId = getSectionLinkId(existing);
        const storySection = parsed.sections.find((s) => s.title === sourceSectionId);

        if (storySection) {
          const remoteHash = computeHash(storyContentForRemote(childDesc));
          const newTitle = formatAidlcStoryHeading(sourceSectionId.match(/US-(\d+)/)?.[1] || '001', childSummary);
          const linkedStoryContent = addRelatedJiraReference(childDesc, existing.remoteId);
          if (remoteHash !== existing.remoteHash || storySection.title !== newTitle || storySection.content !== linkedStoryContent) {
            storySection.content = linkedStoryContent;
            storySection.title = newTitle;
            existing.remoteHash = remoteHash;
            existing.localHash = remoteHash;
            existing.sourceSectionId = newTitle;
            results.push({ action: 'pulled', section: sourceSectionId, target: existing.remoteId, status: 'updated' });
          } else {
            results.push({ action: 'pulled', section: sourceSectionId, target: existing.remoteId, status: 'unchanged' });
          }
        }
      }

      state.docType = 'story';
      state.linkId = null;
      state.bundleMode = 'story-artifact';
      state.childLinks = existingLinks;
    } else {
      const issue = jira('get', state.linkId);
      const remoteTitle = issue.fields?.summary || '';
      const remoteDesc = issue.fields?.description ? adfToMarkdown(issue.fields.description) : '';

      const h1 = parsed.sections.find((s) => s.level === 1);
      if (h1 && remoteTitle && h1.title !== remoteTitle) {
        const linkPrefix = h1.title.match(/^\[.+?\]\s*/)?.[0] || '';
        h1.title = linkPrefix + remoteTitle;
        results.push({ action: 'pulled', field: 'title', status: 'updated' });
      }

      const overview = parsed.sections.find((s) => /^Overview$/i.test(s.title));
      if (overview && remoteDesc) {
        overview.content = remoteDesc;
        results.push({ action: 'pulled', field: 'description', status: 'updated' });
      }
    }

    const newContent = rebuildDoc(parsed.frontmatter, parsed.hasFrontmatter, parsed.sections, parsed.preamble);
    writeFileSync(absPath, newContent, 'utf8');
  } else {
    const page = confluence('get-page', state.linkId);
    const remoteBody = page.body?.storage?.value || page.body?.view?.value || '';
    const remoteMd = storageToMarkdown(remoteBody);

    // Parse remote content as sections
    const remoteParsed = parseBmadDoc(remoteMd);

    // Update local sections from remote
    for (const remoteSection of remoteParsed.sections) {
      const localSection = parsed.sections.find((s) => s.title === remoteSection.title);
      if (localSection) {
        localSection.content = remoteSection.content;
        results.push({ action: 'pulled', section: remoteSection.title, status: 'updated' });
      } else {
        parsed.sections.push(remoteSection);
        results.push({ action: 'pulled', section: remoteSection.title, status: 'added' });
      }
    }

    const newContent = rebuildDoc(parsed.frontmatter, parsed.hasFrontmatter, parsed.sections, parsed.preamble);
    writeFileSync(absPath, newContent, 'utf8');
  }

  // Update sync state
  const updatedContent = readFileSync(absPath, 'utf8');
  const updatedParsed = parseBmadDoc(updatedContent);
  state.localHash = computeDocHash(updatedContent);
  state.remoteHash = state.linkId ? state.localHash : null;
  state.lastSyncedAt = new Date().toISOString();
  state.lastSyncDirection = 'remote-to-local';
  state.sectionHashes = computeSectionHashes(updatedParsed.sections);
  saveSyncState(absPath, state);

  console.log(JSON.stringify({ results }, null, 2));
}

async function cmdDiff(positional, _flags) {
  const filePath = requirePositional(positional, 0, 'file');
  const absPath = resolve(filePath);
  const content = readFileSync(absPath, 'utf8');
  const parsed = parseBmadDoc(content);
  const state = loadSyncState(absPath);

  if (!state) {
    console.error('Document is not linked. Run: sync-aidlc.mjs link <file> first');
    process.exit(1);
  }

  checkEnv();

  // Get remote content
  let remoteSections = [];
  if (state.target === 'jira') {
    if (isStoryBundle(parsed, state)) {
      const existingLinks = state.childLinks || [];
      for (const existing of existingLinks) {
        const child = jira('get', existing.remoteId, '--fields', 'summary,description');
        remoteSections.push({
          title: getSectionLinkId(existing) || child.fields?.summary || existing.remoteId,
          content: child.fields?.description ? adfToMarkdown(child.fields.description) : '',
        });
      }
    } else {
      const issue = jira('get', state.linkId);
      const desc = issue.fields?.description ? adfToMarkdown(issue.fields.description) : '';
      const remoteParsed = parseBmadDoc(desc);
      remoteSections = remoteParsed.sections;

      remoteSections.unshift({
        title: parsed.sections.find((s) => s.level === 1)?.title || 'Title',
        content: issue.fields?.summary || '',
      });
    }
  } else {
    const page = confluence('get-page', state.linkId);
    const body = page.body?.storage?.value || page.body?.view?.value || '';
    const remoteParsed = parseBmadDoc(storageToMarkdown(body));
    remoteSections = remoteParsed.sections;
  }

  const diffs = diffSections(parsed.sections, remoteSections, state.sectionHashes);

  // Format output
  const output = diffs.map((d) => {
    let indicator;
    switch (d.status) {
      case 'local-changed': indicator = '→'; break;
      case 'remote-changed': indicator = '←'; break;
      case 'conflict': indicator = '⚡'; break;
      case 'added-local': indicator = '+ local'; break;
      case 'added-remote': indicator = '+ remote'; break;
      case 'unchanged': indicator = '='; break;
      default: indicator = '?';
    }
    return { section: d.title, status: d.status, indicator };
  });

  console.log(JSON.stringify({ diffs: output }, null, 2));
}

async function cmdSetupMapping(_positional, flags) {
  const docType = flags.type;
  const sample = flags.sample;

  if (!docType) {
    console.error('Required: --type <story|prd|architecture>');
    process.exit(1);
  }
  if (!sample) {
    console.error('Required: --sample <TICKET-KEY or PAGE-ID>');
    process.exit(1);
  }

  checkEnv();
  const target = targetForDocType(docType);

  if (target === 'jira') {
    const issue = jira('get', sample);
    const fields = Object.keys(issue.fields || {});
    const fieldDetails = fields.map((f) => {
      const val = issue.fields[f];
      const type = val === null ? 'null' : Array.isArray(val) ? 'array' : typeof val === 'object' ? 'object' : typeof val;
      return { id: f, value: val, type };
    });

    // Auto-detect common fields
    const mapping = {
      '$schema': 'field-mapping-v1',
      docType,
      projectKey: issue.fields?.project?.key || sample.replace(/-\d+$/, ''),
      issueType: issue.fields?.issuetype?.name || 'Story',
      sampleTicket: sample,
      instructions: '',
      fieldMappings: [],
    };

    // Map well-known fields
    const wellKnown = {
      summary: { source: 'title', jiraFieldType: 'string', transform: 'direct' },
      description: { source: 'section', sourceSectionHeading: 'Overview', jiraFieldType: 'adf', transform: 'markdownToAdf' },
    };

    for (const [fieldId, config] of Object.entries(wellKnown)) {
      if (fields.includes(fieldId)) {
        mapping.fieldMappings.push({
          source: config.source,
          sourceSectionHeading: config.sourceSectionHeading || null,
          jiraField: fieldId.charAt(0).toUpperCase() + fieldId.slice(1),
          jiraFieldId: fieldId,
          jiraFieldType: config.jiraFieldType,
          transform: config.transform,
        });
      }
    }

    // Detect custom fields
    const customFields = fieldDetails.filter((f) => f.id.startsWith('customfield_') && f.value !== null);
    for (const cf of customFields) {
      mapping.fieldMappings.push({
        source: 'section',
        sourceSectionHeading: '?',
        jiraField: cf.id,
        jiraFieldId: cf.id,
        jiraFieldType: cf.type === 'object' ? 'adf' : 'string',
        transform: 'direct',
        _detectedValue: typeof cf.value === 'object' ? JSON.stringify(cf.value).slice(0, 100) : String(cf.value).slice(0, 100),
        _needsReview: true,
      });
    }

    // Output for agent review
    console.log(JSON.stringify(mapping, null, 2));

  } else {
    // Confluence
    const page = confluence('get-page', sample);
    const mapping = {
      '$schema': 'field-mapping-v1',
      docType,
      spaceKey: page.spaceId || '',
      samplePageId: sample,
      createdAt: new Date().toISOString(),
      instructions: '',
      titleSource: 'frontmatter.title',
      titleFallback: 'heading.1',
      bodyTransform: 'markdownToStorage',
      sectionMappings: [],
      frontmatterAsMetadata: {},
    };

    // Parse remote page to discover sections
    const body = page.body?.storage?.value || page.body?.view?.value || '';
    const remoteParsed = parseBmadDoc(storageToMarkdown(body));
    for (const s of remoteParsed.sections) {
      mapping.sectionMappings.push({
        sourceSectionHeading: s.title,
        confluenceHeading: s.title,
        includeSubsections: true,
      });
    }

    console.log(JSON.stringify(mapping, null, 2));
  }
}

async function cmdInitBatch(_positional, flags) {
  const configPath = flags.config || join(MEMORY_DIR, 'batch-sync-config.json');
  const projectRoot = process.cwd();
  const scanPaths = [];

  for (const aidlcDir of findDirectoriesByName(projectRoot, 'aidlc-docs')) {
    const relAidlcDir = aidlcDir.replace(projectRoot + '/', '');
    if (existsSync(join(aidlcDir, 'story-artifacts'))) {
      scanPaths.push({ glob: `${relAidlcDir}/story-artifacts/**/*.md`, docType: 'story', target: 'jira' });
    }
    if (existsSync(join(aidlcDir, 'specs'))) {
      scanPaths.push({ glob: `${relAidlcDir}/specs/**/*.md`, docType: 'story', target: 'jira' });
    }
    if (existsSync(join(aidlcDir, 'foundation'))) {
      scanPaths.push({ glob: `${relAidlcDir}/foundation/**/*.md`, docType: 'architecture', target: 'confluence' });
    }
  }

  if (scanPaths.length === 0) {
    scanPaths.push(
      { glob: 'aidlc-docs/story-artifacts/**/*.md', docType: 'story', target: 'jira' },
      { glob: 'aidlc-docs/specs/**/*.md', docType: 'story', target: 'jira' },
      { glob: 'aidlc-docs/foundation/**/*.md', docType: 'architecture', target: 'confluence' }
    );
  }

  const batchConfig = {
    aidlcConfigPath: null,
    projectRoot,
    scanPaths,
  };

  ensureDir(dirname(configPath));
  writeFileSync(configPath, JSON.stringify(batchConfig, null, 2) + '\n', 'utf8');
  console.log(JSON.stringify(batchConfig, null, 2));
}

async function cmdBatch(_positional, flags) {
  const configPath = flags.config || join(MEMORY_DIR, 'batch-sync-config.json');

  if (!existsSync(configPath)) {
    console.error(`Batch config not found: ${configPath}\nRun: sync-aidlc.mjs init-batch`);
    process.exit(1);
  }

  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  const results = [];

  for (const scan of config.scanPaths || []) {
    const searchDir = resolve(config.projectRoot, dirname(scan.glob));
    if (!existsSync(searchDir)) continue;

    // Simple recursive file discovery
    const files = findFiles(searchDir, '.md');
    for (const file of files) {
      const content = readFileSync(file, 'utf8');
      const parsed = parseBmadDoc(content);
      const docType = detectDocType(parsed) || scan.docType;
      const link = findLink(parsed);
      const state = loadSyncState(file);

      const entry = {
        file: file.replace(config.projectRoot + '/', ''),
        docType,
        linked: !!(link || state),
        linkId: link?.linkId || state?.linkId || null,
      };

      if (state) {
        const currentHash = computeDocHash(content);
        entry.localChanged = currentHash !== state.localHash;
      }

      results.push(entry);
    }
  }

  console.log(JSON.stringify({ files: results }, null, 2));
}

function findFiles(dir, ext) {
  const results = [];
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        results.push(...findFiles(fullPath, ext));
      } else if (entry.name.endsWith(ext)) {
        results.push(fullPath);
      }
    }
  } catch { /* ignore permission errors */ }
  return results;
}

// ---------------------------------------------------------------------------
// Extract value from BMAD doc based on field mapping

function findDirectoriesByName(dir, targetName) {
  const results = [];
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const fullPath = join(dir, entry.name);
      if (entry.name === targetName) {
        results.push(fullPath);
        continue;
      }
      results.push(...findDirectoriesByName(fullPath, targetName));
    }
  } catch { /* ignore permission errors */ }
  return results;
}
// ---------------------------------------------------------------------------

function extractMappedValue(parsed, fieldMapping) {
  const source = fieldMapping.source || fieldMapping.bmadSource || fieldMapping.bmad;
  const sourceSectionHeading = fieldMapping.sourceSectionHeading ?? fieldMapping.bmadSectionHeading ?? null;

  if (source === 'title') {
    const h1 = parsed.sections.find((s) => s.level === 1);
    return h1?.title?.replace(/^\[[A-Z]+-\d+\]\s+/, '') || null;
  }

  if (source?.startsWith('frontmatter.')) {
    const key = source.replace('frontmatter.', '');
    return parsed.frontmatter[key] || null;
  }

  if (source === 'section' && sourceSectionHeading) {
    const section = parsed.sections.find((s) => s.title === sourceSectionHeading);
    return section?.content?.trim() || null;
  }

  return null;
}

// ---------------------------------------------------------------------------
// Usage
// ---------------------------------------------------------------------------

function printUsage() {
  console.log(`Usage: sync-aidlc.mjs <command> [args] [--flags]

Commands:
  status <file>                                Show sync status for a document
  sync-task-plan <tasks.md> [--apply]          Preview or sync AIDLC tasks.md subtasks to Jira
  link <file> --type T --ticket KEY            Link to existing Jira ticket
  link <file> --type T --project P --create    Create new Jira story or story bundle and link
  link <file> --type T --page-id ID            Link to existing Confluence page
  link <file> --type T --space S --create      Create new Confluence page and link
  push <file> [--delete-orphans]               Push local changes to remote
  pull <file>                                  Pull remote changes to local
  diff <file>                                  Show per-section diff
  setup-mapping --type T --sample KEY          Setup field mapping from sample
  init-batch [--config path]                   Generate batch config from AIDLC directories
  batch [--config path]                        Scan and report batch sync status

Document types (--type): story, prd, architecture

Environment variables (required for remote operations):
  ATLASSIAN_EMAIL      Your Atlassian account email
  ATLASSIAN_API_TOKEN  API token
  ATLASSIAN_DOMAIN     e.g. yoursite.atlassian.net`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const COMMANDS = {
  status: cmdStatus,
  'sync-task-plan': cmdSyncTaskPlan,
  link: cmdLink,
  push: cmdPush,
  pull: cmdPull,
  diff: cmdDiff,
  'setup-mapping': cmdSetupMapping,
  'init-batch': cmdInitBatch,
  batch: cmdBatch,
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

  const { positional, flags } = parseArgs(args.slice(1));
  await handler(positional, flags);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
