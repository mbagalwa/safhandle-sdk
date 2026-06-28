# Contributing to SafHandle SDK

Thank you for helping wallets and dApps integrate human-friendly Safrochain payments.

## TL;DR

1. Fork and branch from `main`.
2. Run `npm run verify` locally.
3. Open a PR with summary and test plan.
4. CI must pass before merge.

## Prerequisites

- Node.js 20+ (see [`.nvmrc`](./.nvmrc))
- npm 10+
- Git

## Setup

```bash
git clone https://github.com/<your-fork>/safhandle-sdk.git
cd safhandle-sdk
nvm use
npm install
npm run verify
cp .env.example .env
```

## Branching

Use prefixes: `feat/`, `fix/`, `docs/`, `chore/`, `test/`, `ci/`.

## Conventional Commits

```text
type(scope): short description
```

## Specification changes

SDK API changes must stay aligned with [safhandle-contract](https://github.com/Safrochain-Org/safhandle-contract) `CONTRACT_API.md`. Note cross-repo impact in PRs.

## Code of conduct

See [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
