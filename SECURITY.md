# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| `main` (latest) | Yes |
| Latest tagged release | Yes |
| Older releases | Best effort |

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

| Channel | Details |
| --- | --- |
| **Email** | [security@safrochain.com](mailto:security@safrochain.com) |
| **Subject** | `[saflink-sdk] Brief description` |

### High-priority areas

- Client-side address spoofing or cache poisoning
- Incorrect resolution before transaction signing
- Leaking phone numbers to third-party analytics
- Hardcoded private keys or contract addresses in examples
- Supply-chain issues in npm dependencies

## Response timeline

| Stage | Target |
| --- | --- |
| Initial acknowledgment | 2 business days |
| Severity assessment | 5 business days |
| Fix or mitigation plan | 15 business days |

## Safe harbor

Good-faith security research is welcome when it follows responsible disclosure and does not harm users.

## Dependencies

Monitored via [Dependabot](.github/dependabot.yml) and CI audits once dependencies are added.
