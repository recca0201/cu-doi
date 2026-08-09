/**
 * Loads .env file variables into process.env before the caller reads them.
 *
 * Search order (first found wins):
 *   1. <cwd>/.env
 *   2. <script-dir>/.env  (the skill's own scripts/ directory)
 *   3. <git-root>/.env    (project root, walked up from cwd)
 *
 * Only missing variables are injected — existing env vars always win,
 * so shell-exported values (e.g. from ~/.zshrc) are never overwritten.
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

function parseEnvFile(filePath) {
  const vars = {};
  for (const raw of readFileSync(filePath, 'utf8').split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (key) vars[key] = value;
  }
  return vars;
}

function findGitRoot(startDir) {
  let dir = startDir;
  while (true) {
    if (existsSync(join(dir, '.git'))) return dir;
    const parent = resolve(dir, '..');
    if (parent === dir) return null;
    dir = parent;
  }
}

export function normalizeAtlassianDomain(value) {
  if (!value || typeof value !== 'string') {
    throw new Error('ATLASSIAN_DOMAIN is required');
  }

  const trimmed = value.trim().toLowerCase();
  let hostname = trimmed;

  if (trimmed.includes('://')) {
    const url = new URL(trimmed);
    if (
      url.protocol !== 'https:'
      || url.username
      || url.password
      || url.port
      || url.pathname !== '/'
      || url.search
      || url.hash
    ) {
      throw new Error('ATLASSIAN_DOMAIN must be a bare Atlassian Cloud host such as yoursite.atlassian.net');
    }
    hostname = url.hostname;
  }

  if (
    hostname.includes('/')
    || hostname.includes('@')
    || hostname.includes(':')
    || !/^[a-z0-9.-]+$/.test(hostname)
    || !hostname.endsWith('.atlassian.net')
  ) {
    throw new Error('ATLASSIAN_DOMAIN must be a *.atlassian.net host');
  }

  return hostname;
}

function validateLoadedAtlassianDomain() {
  if (!process.env.ATLASSIAN_DOMAIN) {
    return;
  }

  try {
    process.env.ATLASSIAN_DOMAIN = normalizeAtlassianDomain(process.env.ATLASSIAN_DOMAIN);
  } catch (error) {
    console.error(`Invalid ATLASSIAN_DOMAIN: ${error.message}`);
    process.exit(1);
  }
}

export function loadEnv() {
  const scriptDir = dirname(fileURLToPath(import.meta.url));
  const cwd = process.cwd();
  const gitRoot = findGitRoot(cwd);

  const candidates = [
    join(cwd, '.env'),
    join(scriptDir, '..', '.env'),   // skill root (one level above scripts/)
    join(scriptDir, '.env'),          // scripts/ dir itself
    gitRoot ? join(gitRoot, '.env') : null,
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      const vars = parseEnvFile(candidate);
      for (const [k, v] of Object.entries(vars)) {
        if (!process.env[k]) process.env[k] = v;
      }
      validateLoadedAtlassianDomain();
      return;
    }
  }

  validateLoadedAtlassianDomain();
}
