pagerduty-cli
=============

PagerDuty Command Line Interface

> Fork of [martindstone/pagerduty-cli](https://github.com/martindstone/pagerduty-cli), modernized and maintained.

[![oclif](https://img.shields.io/badge/cli-oclif_v3-brightgreen.svg)](https://oclif.io)
[![License](https://img.shields.io/npm/l/pagerduty-cli.svg)](https://github.com/jholm117/pagerduty-cli/blob/master/package.json)

## Requirements

- Node.js 24 LTS or later (bundled when installed via Homebrew)

## Install

### Homebrew (recommended)

```bash
brew tap jholm117/tap
brew install pd
```

### From source

```bash
git clone https://github.com/jholm117/pagerduty-cli.git
cd pagerduty-cli
npm install
npm link
```

## Authentication

```bash
# OAuth browser flow (recommended)
pd login

# Or use an API token
pd auth:set -t <your-token>

# Verify
pd auth list
```

## Usage

See the [User Guide](https://github.com/martindstone/pagerduty-cli/wiki/PagerDuty-CLI-User-Guide) (upstream, still applicable).

<!-- commands -->
# Command Topics

* [`pd analytics`](docs/analytics.md) - Get PagerDuty Incident Analytics
* [`pd auth`](docs/auth.md) - Get/Set authentication token
* [`pd autocomplete`](docs/autocomplete.md) - Display autocomplete installation instructions.
* [`pd automation`](docs/automation.md) - Manage automation actions and runners
* [`pd bs`](docs/bs.md) - See/manage business services
* [`pd commands`](docs/commands.md) - list all the commands
* [`pd ep`](docs/ep.md) - See/manage escalation policies
* [`pd event`](docs/event.md) - Send an Alert to PagerDuty
* [`pd field`](docs/field.md) - Manage custom fields
* [`pd help`](docs/help.md) - Display help for pd.
* [`pd incident`](docs/incident.md) - See/manage incidents
* [`pd log`](docs/log.md) - Show PagerDuty Domain Log Entries
* [`pd orchestration`](docs/orchestration.md) - Manage global orchestrations
* [`pd rest`](docs/rest.md) - Make raw requests to PagerDuty REST endpoints
* [`pd schedule`](docs/schedule.md) - See/manage schedules
* [`pd service`](docs/service.md) - See/manage services
* [`pd tag`](docs/tag.md) - Assign/Remove Tags to/from PagerDuty objects
* [`pd team`](docs/team.md) - See/Manage teams
* [`pd user`](docs/user.md) - See/manage users
* [`pd util`](docs/util.md) - Utility commands
* [`pd version`](docs/version.md)

<!-- commandsstop -->

## Changes from upstream

- TypeScript 4 → 5, targeting Node 24 LTS
- oclif/core v1 → v3
- ESLint 8 → 9 (flat config)
- Mocha 10 → 11, nyc 15 → 18
- Removed dead deps (aws-sdk, plugin-update, fs-extra-debug)
- 0 npm audit vulnerabilities
