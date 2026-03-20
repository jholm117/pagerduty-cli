# pagerduty-cli Modernization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the forked pagerduty-cli install cleanly, build, lint, and run on Node 22+ with zero critical/high vulnerabilities.

**Architecture:** Incremental patch in 5 waves. Stay on CommonJS. Target oclif/core v3 (not v4) because v4 removes `ux.table`/`ux.prompt`/`ux.wait` which would require rewriting 35+ command files. v3 is a rename-only migration (`CliUx` → `ux`) that preserves all existing table/prompt/spinner APIs.

**Tech Stack:** TypeScript 5, oclif/core v3, Node 22 LTS, ESLint 9, Mocha 11, Chai 4

**Repo:** `/Users/jeff.holm/gt/pagerduty_cli/mayor/rig/` (work directly on main branch)

---

## Task 1: Remove Dead Weight Dependencies

**Files:**
- Modify: `package.json`
- Modify: `src/commands/service/disable.ts` (if it references update plugin)
- Delete: `yarn.lock`

**Step 1: Remove unused packages from package.json**

Remove these from `dependencies`:
- `fs-extra-debug` (unmaintained wrapper, never imported)

Remove these from `devDependencies`:
- `aws-sdk` (only used by @oclif/plugin-update's S3 config)
- `globby` (only used by oclif internals, not our code)

**Step 2: Remove unused oclif plugins from package.json**

In the `oclif.plugins` array, remove:
- `@oclif/plugin-update`
- `@oclif/plugin-warn-if-update-available`

Also remove these from `dependencies`:
- `@oclif/plugin-update`
- `@oclif/plugin-warn-if-update-available`

Remove the `oclif.update` section (S3 bucket config).

**Step 3: Remove yarn.lock**

```bash
rm yarn.lock
```

We'll use `package-lock.json` (npm) going forward.

**Step 4: Remove node_modules and reinstall**

```bash
rm -rf node_modules package-lock.json
npm install
```

**Step 5: Verify TypeScript still compiles**

```bash
npx tsc -b
```

Expected: compiles with no errors.

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: remove dead weight deps (aws-sdk, plugin-update, fs-extra-debug, yarn.lock)"
```

---

## Task 2: Update TypeScript and Type Definitions

**Files:**
- Modify: `package.json`
- Modify: `tsconfig.json`

**Step 1: Update TypeScript and type definitions**

```bash
npm install --save-dev typescript@^5 @types/node@^22 @types/mocha@^10 @types/fs-extra@^11 @types/simple-oauth2@^5
```

**Step 2: Update .node-version and .tool-versions**

Set `.node-version` to `22.14.0` (current LTS).
Set `.tool-versions` to `nodejs 22.14.0` (remove the yarn line).

**Step 3: Update engines in package.json**

```json
"engines": {
  "node": ">=22"
}
```

**Step 4: Compile and fix any TypeScript errors**

```bash
npx tsc -b
```

Fix any type errors introduced by the new TypeScript version. Common issues:
- Stricter null checks
- Changed type inference
- New `@types/node` signatures

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: update typescript 4→5, @types/node 16→22, target node 22 LTS"
```

---

## Task 3: Migrate oclif/core v1 → v3

This is the largest task. oclif v3 renames `CliUx` to `ux` but keeps the same APIs (table, prompt, action, wait).

**Files:**
- Modify: `package.json`
- Modify: `bin/run` (bootstrap pattern)
- Modify: `src/base/base-command.ts`
- Modify: `src/base/authenticated-base-command.ts`
- Modify: `src/base/list-base-command.ts`
- Modify: `src/pd.ts`
- Modify: All 105 files in `src/` that import `CliUx`

**Step 1: Update oclif packages**

```bash
npm install @oclif/core@^3 @oclif/plugin-help@^6 @oclif/plugin-commands@^3 @oclif/plugin-autocomplete@^3 @oclif/plugin-version@^2
npm install --save-dev @oclif/test@^3
```

Note: `@oclif/plugin-help@^6` is compatible with core v3. Check each plugin's peer deps.

**Step 2: Update bin/run for oclif v3**

Replace the content of `bin/run` with:

```js
#!/usr/bin/env node

(async () => {
  const oclif = await import('@oclif/core')
  await oclif.execute({development: false, dir: __dirname})
})()
```

**Step 3: Rename CliUx → ux across all source files**

This is a mechanical find-and-replace across 105 files:

1. Replace `import { ... CliUx ... } from '@oclif/core'` → add `import { ux } from '@oclif/core'` (remove CliUx from the destructure)
2. Replace all `CliUx.ux.` → `ux.` throughout

Pattern for imports — change:
```typescript
import { Flags, CliUx } from '@oclif/core'
```
to:
```typescript
import { Flags, ux } from '@oclif/core'
```

Pattern for usage — change:
```typescript
CliUx.ux.action.start('...')
CliUx.ux.action.stop('...')
CliUx.ux.table(rows, columns, options)
CliUx.ux.table.flags()
CliUx.ux.prompt('...')
CliUx.ux.wait(ms)
```
to:
```typescript
ux.action.start('...')
ux.action.stop('...')
ux.table(rows, columns, options)
ux.table.flags()
ux.prompt('...')
ux.wait(ms)
```

**Approach:** Use a script or codemod for the mechanical replacement, then fix any remaining issues by hand.

```bash
# In src/ directory, replace CliUx.ux. with ux.
find src -name '*.ts' -exec sed -i '' 's/CliUx\.ux\./ux./g' {} +

# Fix imports: replace CliUx with ux in import lines
# This requires careful handling — some files import CliUx alongside other things
```

**Step 4: Update base-command.ts imports and types**

The `Interfaces` import may have changed. In oclif v3:
- `Interfaces.Command.Class` may need updating
- `Flags.help()` was removed — oclif auto-adds help flag

In `src/base/base-command.ts`:
- Remove `Flags.help({ char: 'h' })` from globalFlags (oclif v3 handles this automatically via the help plugin)
- Update `this.parse()` call if the API changed

**Step 5: Check for oclif v3 breaking changes in flag definitions**

In oclif v3, `noCacheDefault` replaces `isWritingManifest` for flags with dynamic defaults. Check if any flags use this pattern.

**Step 6: Compile and fix all TypeScript errors**

```bash
npx tsc -b
```

There will likely be type errors from changed oclif APIs. Fix each one:
- Changed method signatures on Command base class
- Changed `Interfaces` types
- Changed flag/arg type inference

**Step 7: Verify the CLI boots**

```bash
./bin/run --version
./bin/run --help
```

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: migrate oclif/core v1→v3, rename CliUx→ux across 105 files"
```

---

## Task 4: Update ESLint Toolchain

**Files:**
- Modify: `package.json`
- Modify or replace: `.eslintrc` → `eslint.config.mjs` (ESLint 9 uses flat config)

**Step 1: Update ESLint and config**

```bash
npm install --save-dev eslint@^9 eslint-config-oclif@^6 @eslint/compat@^1
```

**Step 2: Migrate from .eslintrc to flat config**

ESLint 9 uses flat config format. Create `eslint.config.mjs`:

```js
import {FlatCompat} from '@eslint/eslintrc'

const compat = new FlatCompat()

export default [
  ...compat.extends('oclif'),
  {
    rules: {
      // Override any rules that are too strict for this codebase
    },
  },
]
```

Delete `.eslintrc`.

**Step 3: Run ESLint and fix issues**

```bash
npx eslint src/ --fix
```

Fix any remaining lint errors. Don't chase cosmetic issues — focus on making it pass.

**Step 4: Update the posttest script in package.json**

Change:
```json
"posttest": "eslint . --ext .ts --config .eslintrc"
```
to:
```json
"posttest": "eslint src/"
```

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: update eslint 8→9 with flat config, eslint-config-oclif 4→6"
```

---

## Task 5: Update Test Toolchain

**Files:**
- Modify: `package.json`
- Modify: `test/commands/hello.test.ts`
- Modify: `test/commands/set-global-config.test.ts`
- Delete: `test/mocha.opts` (if present — mocha 11 uses .mocharc)

**Step 1: Update test dependencies**

```bash
npm install --save-dev mocha@^11 @oclif/test@^3 nyc@^18
```

Keep `chai@^4` (v5/v6 are ESM-only).

**Step 2: Fix test imports for @oclif/test v3**

The existing tests import `{expect, test} from '@oclif/test'`. In v3, the API may have changed. Check what `@oclif/test@3` exports and update accordingly.

The `hello.test.ts` tests a command that doesn't exist — it's scaffold cruft. Delete it or fix it to test something real.

The `set-global-config.test.ts` tests the init hook. Update the import pattern if needed.

**Step 3: Create/update .mocharc.yml**

```yaml
require:
  - ts-node/register
timeout: 10000
spec: test/**/*.test.ts
```

Delete `test/mocha.opts` if it exists.

**Step 4: Run tests**

```bash
npm test
```

Expected: Tests pass (or at least run without crashing).

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: update mocha 10→11, @oclif/test v3, nyc 15→18"
```

---

## Task 6: Update Runtime Dependencies

**Files:**
- Modify: `package.json`

**Step 1: Update non-breaking dependencies**

```bash
npm install axios@^1.13 chrono-node@^2.9 fs-extra@^11.3 jsonpath@^1.3 libphonenumber-js@^1.12 ololog@^1.1.175 simple-oauth2@^5.1 tslib@^2.8
```

**Step 2: Update parse-duration (major bump, verify API)**

```bash
npm install parse-duration@^2
```

Check if the API changed. The v1 export was `parseDuration(str)` returning milliseconds. Verify v2 does the same. Search for `parse-duration` usage in the codebase and adjust if needed.

```bash
grep -r "parse-duration" src/
```

**Step 3: Handle csv-parse major bump**

```bash
npm install csv-parse@^5.5
```

Stay on v5 latest (v6 may have breaking changes). Check usage:

```bash
grep -r "csv-parse" src/
```

**Step 4: Pin get-stream at v6**

```bash
npm install get-stream@^6.0
```

v7+ is ESM-only. Keep at 6.x.

**Step 5: Compile and verify**

```bash
npx tsc -b
```

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: update runtime dependencies (axios, chrono-node, parse-duration, etc.)"
```

---

## Task 7: Fix Vulnerabilities

**Files:**
- Modify: `package-lock.json` (via npm audit fix)

**Step 1: Run npm audit fix**

```bash
npm audit fix
```

**Step 2: Check remaining vulnerabilities**

```bash
npm audit
```

If critical/high vulns remain, investigate:
- Are they in devDependencies only? (lower risk)
- Can we override the transitive dep version?

**Step 3: Force-fix if needed**

For stubborn transitive vulns in devDeps, use overrides in package.json:

```json
"overrides": {
  "vulnerable-package": "^fixed.version"
}
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: fix npm audit vulnerabilities"
```

---

## Task 8: Metadata Cleanup

**Files:**
- Modify: `package.json`
- Modify: `.npmrc`

**Step 1: Update package.json metadata**

- `repository`: `"jholm117/pagerduty-cli"`
- `bugs`: `"https://github.com/jholm117/pagerduty-cli/issues"`
- `homepage`: `"https://github.com/jholm117/pagerduty-cli"`
- Remove the `oclif.update` section (S3 bucket config) if not already removed
- Remove `npm-shrinkwrap.json` from the `files` array (file doesn't exist)

**Step 2: Regenerate oclif manifest**

```bash
npx oclif manifest
```

**Step 3: Compile and smoke test**

```bash
npx tsc -b
./bin/run --version
./bin/run --help
./bin/run auth list
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: update package metadata for jholm117 fork, regenerate manifest"
```

---

## Task 9: Full Smoke Test

**Step 1: Clean install from scratch**

```bash
rm -rf node_modules package-lock.json lib
npm install
npm run prepack
```

**Step 2: Verify all toolchain commands**

```bash
npx tsc -b                    # TypeScript compiles
npm test                      # Tests pass
npx eslint src/               # Lint passes
./bin/run --version           # CLI boots
./bin/run --help              # Help displays
npm audit                     # No critical/high vulns
```

**Step 3: Test a few commands (if PD token available)**

```bash
./bin/run auth list
./bin/run user list --limit 5
./bin/run incident list --limit 5
./bin/run service list --limit 5
```

**Step 4: Commit any final fixes**

```bash
git add -A
git commit -m "chore: final smoke test fixes"
```

---

## Task 10: Push to Remote

**Step 1: Push all changes**

```bash
git push origin main
```

---

## Summary of Mechanical Changes

| Change | Scope | Method |
|--------|-------|--------|
| `CliUx` → `ux` import rename | 105 files | sed/codemod |
| `CliUx.ux.` → `ux.` usage rename | 105 files | sed |
| Remove `Flags.help()` from base | 1 file | manual |
| Update `bin/run` bootstrap | 1 file | manual |
| Update package versions | `package.json` | npm install |
| ESLint flat config migration | 1 file | manual |
| Fix TypeScript type errors | ~5-10 files | manual |

## Key Risk: oclif v3 Compatibility

The biggest risk is that `@oclif/core@3` has subtle breaking changes beyond the `CliUx` → `ux` rename. The mitigation is:
1. Compile after the upgrade — TypeScript will catch most issues
2. Boot the CLI (`--version`, `--help`) to verify runtime behavior
3. Test a few commands if a PD token is available

If v3 proves more painful than expected, we can stay on `@oclif/core@^2` as a fallback — v2 also renamed `CliUx` to `ux` and should work on Node 22.
