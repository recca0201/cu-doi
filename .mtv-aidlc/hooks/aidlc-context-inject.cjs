#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const DEFAULT_CONTEXT = {
  aidlcDocsPath: 'aidlc-docs',
  requirementsTemplate: 'default',
  technicalDesignTemplate: 'standard',
  tasksTemplate: 'test-first',
  testCaseFormat: 'gherkin-table',
  taskExecutionApproach: 'subagent',
  designSystem: 'magenta-mds',
};

const TEST_CASE_FORMATS = new Set([
  'gherkin-table',
  'gherkin-blocks',
  'standard-table',
  'custom',
]);

const TASK_EXECUTION_APPROACHES = new Set(['inline', 'subagent']);

function findAidlcRoot(startDir) {
  let dir = path.resolve(startDir);
  while (true) {
    const candidate = path.join(dir, '.mtv-aidlc');
    try {
      const stat = fs.statSync(candidate);
      if (stat.isDirectory()) {
        return dir;
      }
    } catch (_) {
      // not found at this level
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

function readConfig(configPath) {
  try {
    const raw = fs.readFileSync(configPath, 'utf8');
    const parsed = JSON.parse(raw);
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}

function stringValue(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (trimmed.length === 0 || /[\u0000-\u001f\u007f`]/.test(trimmed)) {
    return null;
  }

  return trimmed;
}

function resolveDesignSystem(value, hasValue) {
  if (!hasValue) {
    return DEFAULT_CONTEXT.designSystem;
  }
  if (value === null) {
    return null;
  }

  const designSystem = stringValue(value);
  if (!designSystem) {
    return DEFAULT_CONTEXT.designSystem;
  }
  if (designSystem.toLowerCase() === 'none') {
    return null;
  }

  return designSystem;
}

function resolveContext(config, workspaceRoot) {
  const c = config || {};
  const aidlcDocsPath =
    stringValue(c.aidlcDocsPath) || DEFAULT_CONTEXT.aidlcDocsPath;

  const userStory = c.userStory || {};
  const designDocument = c.designDocument || {};
  const implementationTask = c.implementationTask || {};
  const testCase = c.testCase || {};

  // userStory.template -> requirementsTemplate
  const requirementsTemplate =
    stringValue(userStory.template) ||
    DEFAULT_CONTEXT.requirementsTemplate;
  const requirementsTemplatePath =
    requirementsTemplate === 'custom' ? stringValue(userStory.customTemplatePath) : null;

  // designDocument.template -> technicalDesignTemplate
  const technicalDesignTemplate =
    stringValue(designDocument.template) ||
    DEFAULT_CONTEXT.technicalDesignTemplate;
  const technicalDesignTemplatePath =
    technicalDesignTemplate === 'custom' ? stringValue(designDocument.customTemplatePath) : null;

  // implementationTask.template -> tasksTemplate
  const tasksTemplate =
    stringValue(implementationTask.template) ||
    DEFAULT_CONTEXT.tasksTemplate;
  const tasksTemplatePath =
    tasksTemplate === 'custom' ? stringValue(implementationTask.customTemplatePath) : null;

  const rawTestCaseFormat = stringValue(testCase.format);
  const testCaseFormat = TEST_CASE_FORMATS.has(rawTestCaseFormat)
    ? rawTestCaseFormat
    : DEFAULT_CONTEXT.testCaseFormat;
  const testCaseTemplatePath =
    testCaseFormat === 'custom' ? stringValue(testCase.customTemplatePath) : null;

  const taskExecution = c.taskExecution || {};
  const rawTaskExecutionApproach = stringValue(taskExecution.approach);
  const taskExecutionApproach = TASK_EXECUTION_APPROACHES.has(rawTaskExecutionApproach)
    ? rawTaskExecutionApproach
    : DEFAULT_CONTEXT.taskExecutionApproach;

  const hasDesignSystem = Object.prototype.hasOwnProperty.call(c, 'designSystem');
  const designSystem = resolveDesignSystem(c.designSystem, hasDesignSystem);

  return {
    workspaceRoot,
    aidlcDocsPath,
    requirementsTemplate,
    requirementsTemplatePath,
    technicalDesignTemplate,
    technicalDesignTemplatePath,
    tasksTemplate,
    tasksTemplatePath,
    testCaseFormat,
    testCaseTemplatePath,
    taskExecutionApproach,
    designSystem,
  };
}

function buildContext(context) {
  const lines = [
    '## AI-DLC Context',
    `- Workspace root: ${context.workspaceRoot}`,
    `- Docs: ${context.aidlcDocsPath} (workspace-root-relative)`,
    `- Requirements/User Story template: ${context.requirementsTemplate}`,
  ];

  if (context.requirementsTemplatePath) {
    lines.push(`- Requirements/User Story custom template path: ${context.requirementsTemplatePath}`);
  }

  lines.push(`- Technical Design template: ${context.technicalDesignTemplate}`);

  if (context.technicalDesignTemplatePath) {
    lines.push(`- Technical Design custom template path: ${context.technicalDesignTemplatePath}`);
  }

  lines.push(`- Tasks template: ${context.tasksTemplate}`);

  if (context.tasksTemplatePath) {
    lines.push(`- Tasks custom template path: ${context.tasksTemplatePath}`);
  }

  lines.push(`- Test Case format: ${context.testCaseFormat}`);

  if (context.testCaseTemplatePath) {
    lines.push(`- Test Case custom template path: ${context.testCaseTemplatePath}`);
  }

  lines.push(`- Task Execution Approach: ${context.taskExecutionApproach}`);

  // Always print Design System info, even if null or not configured
  if (context.designSystem) {
    lines.push(`- Design System Agent Skill: ${context.designSystem}`);
  } else {
    lines.push(`- Design System: None`);
  }

  lines.push(
    '',
    '## AI-DLC Skill Guidance',
    '- IMPORTANT: Explicit prompt flags always win over injected context and workspace config.',
    '- Follow YAGNI - KISS - DRY principles.'
  );

  if (context.designSystem) {
    lines.push(
      `- For UI/UX, design.md, mockup.html, or frontend implementation work: invoke \`${context.designSystem}\`.`
    );
  }

  return lines.join('\n');
}

function readStdinCwd() {
  try {
    // Only attempt to read if stdin is a pipe/file (not a TTY)
    if (process.stdin.isTTY) {
      return null;
    }
    const raw = fs.readFileSync(0, 'utf8');
    if (!raw || raw.trim().length === 0) {
      return null;
    }
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (_) {
      return null;
    }
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return null;
    }
    return stringValue(parsed.cwd) || null;
  } catch (_) {
    return null;
  }
}

function main() {
  const githubJson = process.argv.includes('--github-json');

  const stdinCwd = readStdinCwd();
  const startDir = stdinCwd || process.cwd();

  const foundRoot = findAidlcRoot(startDir);
  const workspaceRoot = foundRoot || startDir;

  let config = null;
  if (foundRoot) {
    const configPath = path.join(foundRoot, '.mtv-aidlc', 'extension-config.json');
    config = readConfig(configPath);
  }

  const context = resolveContext(config, workspaceRoot);
  const markdown = buildContext(context);

  if (githubJson) {
    process.stdout.write(JSON.stringify({ additionalContext: markdown }) + '\n');
  } else {
    process.stdout.write(markdown + '\n');
  }
  process.exit(0);
}

main();
