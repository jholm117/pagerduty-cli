# pagerduty-cli Modernization Design

**Date:** 2026-03-19
**Goal:** Make the forked pagerduty-cli reliable, secure, and usable for personal/team use.

## Context

Forked from `martindstone/pagerduty-cli` (unmaintained). oclif-based CLI with ~95 commands covering most PagerDuty REST API v2 operations. TypeScript, CommonJS.

### Current State

- **Build:** TypeScript compiles successfully
- **Tests:** Crash on Node 24 (`@oclif/test` v2 incompatible)
- **ESLint:** Crashes (`eslint-config-oclif` v4 incompatible with Node 24)
- **Vulnerabilities:** 31 npm audit findings (2 critical, 13 high)
- **Deprecated packages:** `fancy-test`, `@oclif/color`, `@oclif/screen`, `eslint@8`, `aws-sdk@2`
- **oclif:** 3 major versions behind (1.x → 4.x)
- **TypeScript:** 1 major behind (4.x → 5.x)
- **Node target:** .node-version pinned to 16.19.0 (EOL)
- **API version:** PagerDuty REST API v2 — correct and current

### Not In Scope

- Publishing to npm/Homebrew (personal/team use for now)
- ESM conversion (too disruptive, project stays CommonJS)
- Adding new PD API commands (Incident Workflows, AIOps, etc.)
- Comprehensive test suite (existing coverage is minimal — fix what exists, don't expand)

## Approach: Incremental Patch (5 Waves)

### Wave 1: Unbreak the Toolchain

**Remove dead weight:**
- `aws-sdk` (devDep, only needed for S3-based auto-update)
- `@oclif/plugin-update` (points to original author's S3 bucket)
- `@oclif/plugin-warn-if-update-available` (same)
- `fs-extra-debug` (unmaintained)

**Fix toolchain:**
- `typescript` 4 → 5
- `eslint` 8 → 9+ with `eslint-config-oclif` 4 → 6
- `@oclif/test` 2 → 4
- `mocha` 10 → 11
- `chai` 4 → 5 (not 6 — ESM-only)
- `nyc` 15 → 18
- `@types/node` 16 → 22+
- `.node-version` → 22.x LTS
- `npm audit fix` for transitive vulns

**Exit criteria:** `npm test` runs, `eslint` passes, `tsc` compiles, zero critical/high vulns.

### Wave 2: oclif 1 → 3 Migration

**Why v3, not v4:** oclif v4 removed `ux.table`, `ux.prompt`, and `ux.wait`. This codebase uses `ux.table` in 35+ command files via `CliUx.ux.table.flags()` and `printTable()`. Rewriting all table output is unnecessary scope. v3 renames `CliUx` → `ux` but keeps all APIs intact — a rename-only migration.

**Changes:**
- `CliUx` → `ux` import rename across 105 files (mechanical sed)
- `CliUx.ux.X` → `ux.X` usage rename across 105 files
- Remove `Flags.help()` from base (v3 auto-adds via help plugin)
- Update `bin/run` bootstrap to v3 async pattern
- Update `@oclif/plugin-*` to v3-compatible versions

**Scope:**
- `@oclif/core` 1 → 3 and all `@oclif/plugin-*` to matching majors
- Regenerate `oclif.manifest.json`

**Nature:** Mechanical but large diff. Command logic unchanged — only oclif wiring.

### Wave 3: Runtime Dependency Updates

| Package | From | To | Notes |
|---------|------|----|-------|
| `axios` | 1.2 | 1.13 | Security patches |
| `chrono-node` | 2.1 | 2.9 | |
| `csv-parse` | 5 | 6 | Check for breaking changes |
| `fs-extra` | 11.1 | 11.3 | |
| `jsonpath` | 1.1 | 1.3 | |
| `libphonenumber-js` | 1.10 | 1.12 | |
| `ololog` | 1.1.168 | 1.1.175 | |
| `parse-duration` | 1.0 | 2.1 | Major bump — verify API |
| `simple-oauth2` | 5.0 | 5.1 | |
| `tslib` | 2.4 | 2.8 | |
| `get-stream` | 6 | 6.x (pin) | 7+ is ESM-only |
| `cardinal` | 2.1.1 | keep | No updates |

### Wave 4: Functional Verification

- Test each command category against PD API
- Fix custom fields commands (PD changed the schema in 2023)
- Verify offset and cursor pagination
- Fix any deprecated endpoint paths

### Wave 5: Cleanup

- Update `package.json` metadata (`repository` → `jholm117/pagerduty-cli`)
- Remove S3 update config from oclif section
- Remove `npm-shrinkwrap.json` from `files` array
- Drop `yarn.lock`, standardize on `package-lock.json`
- Update README with fork context
