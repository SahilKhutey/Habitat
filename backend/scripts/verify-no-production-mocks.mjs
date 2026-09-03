#!/usr/bin/env node
/**
 * Habitat CI Verification Gate: Zero Production Mocks
 *
 * Scans production source directories (backend/src, apps/mobile/lib, packages)
 * to ensure no unauthorized mocks, fake repositories, synthetic telemetry,
 * or mock fallbacks exist in production code paths.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '../..');

const scanDirectories = [
  path.join(rootDir, 'backend', 'src'),
  path.join(rootDir, 'apps', 'mobile', 'lib'),
  path.join(rootDir, 'packages')
];

// Patterns that are strictly forbidden in production source files
const forbiddenProductionPatterns = [
  {
    regex: /\bnew\s+MockVisionProvider\s*\(/i,
    description: 'Direct instantiation of MockVisionProvider in production code'
  },
  {
    regex: /\bclass\s+(?:Fake|Mock)(?:Task|User|Alarm|Mission|Proof)Repository\b/i,
    description: 'Fake/Mock repository implementation in production source'
  },
  {
    regex: /\b(?:fakeResult|fakeVerification|mockResult)\s*[:=]/i,
    description: 'Fabricated verification result object'
  },
  {
    regex: /\bstatus\s*:\s*['"](?:FAKE|MOCK)_/i,
    description: 'Fake/Mock entity status'
  },
  {
    regex: /\bconst\s+demoTasks\s*=/i,
    description: 'Hardcoded demo tasks collection'
  }
];

// Whitelisted files (e.g. unit tests or test helpers that happen to reside in src or test)
const ignoredPathPatterns = [
  /\.test\.[tj]sx?$/,
  /\.spec\.[tj]sx?$/,
  /tests[\\/]/,
  /node_modules[\\/]/,
  /\.dart_tool[\\/]/,
  /build[\\/]/
];

const violations = [];

function scanFile(filePath) {
  for (const ignorePattern of ignoredPathPatterns) {
    if (ignorePattern.test(filePath)) {
      return;
    }
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Skip comment-only lines
    const trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
      continue;
    }

    for (const rule of forbiddenProductionPatterns) {
      if (rule.regex.test(line)) {
        violations.push({
          file: path.relative(rootDir, filePath),
          line: i + 1,
          rule: rule.description,
          snippet: trimmed
        });
      }
    }
  }
}

function traverse(dir) {
  if (!fs.existsSync(dir)) return;

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== 'node_modules' && entry.name !== '.git' && entry.name !== 'build') {
        traverse(fullPath);
      }
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name).toLowerCase();
      if (['.ts', '.js', '.mjs', '.dart'].includes(ext)) {
        scanFile(fullPath);
      }
    }
  }
}

console.log('================================================================');
console.log('🔍 HABITAT ZERO-PRODUCTION-MOCK AUDIT GATE');
console.log('================================================================');

for (const dir of scanDirectories) {
  console.log(`Scanning: ${path.relative(rootDir, dir)}/`);
  traverse(dir);
}

if (violations.length > 0) {
  console.error(`\n❌ [MOCK DETECTOR FAILED] ${violations.length} violation(s) detected:\n`);
  for (const v of violations) {
    console.error(`  [!] ${v.file}:${v.line}`);
    console.error(`      Rule: ${v.rule}`);
    console.error(`      Code: ${v.snippet}\n`);
  }
  process.exit(1);
} else {
  console.log('\n✅ [MOCK DETECTOR PASSED] 0 unauthorized mocks or synthetic shortcuts detected.');
  console.log('================================================================');
  process.exit(0);
}
