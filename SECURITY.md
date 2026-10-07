# Security Policy

We take security seriously.

aliasx processes external knowledge, agent-generated content, metadata, and reusable instructions. Treat every unverified source as untrusted input.

- Please report vulnerabilities privately.
- Do not open public Issues for security reports.

## Report a vulnerability

Preferred:

- [GitHub Private Vulnerability Reporting / Security Advisories](https://github.com/comstrx/aliasx/security/advisories/new) 🔒

If that is unavailable, email the maintainer privately: <comstrx@gmail.com>

## What belongs here

✅ Security reports include:

- remote code execution or arbitrary command execution
- path traversal, sandbox escape, or unsafe file access
- prompt/instruction injection that crosses a defined trust boundary
- malicious or poisoned skill/source ingestion with security impact
- unsafe execution of imported scripts, hooks, tools, or generated content
- provenance, signature, integrity, or validation bypasses
- data exposure, secret leakage, or privilege escalation
- supply-chain attacks or dependency compromise with clear impact
- unsafe defaults that affect real aliasx deployments or consumers

❌ Not security reports:

- ordinary validation failures
- low-quality or inaccurate skills without a security boundary impact
- feature requests or usage questions
- duplicate/conflicting skills without an exploitation path

Use [Issues](https://github.com/comstrx/aliasx/issues) or [Discussions](https://github.com/comstrx/aliasx/discussions) for those.

## Include this

- affected aliasx version, commit, or tag
- affected component, pipeline stage, adapter, validator, or skill when known
- source/trust context involved
- impact and threat model
- minimal safe reproduction or PoC
- environment details
- relevant logs or validation output

🚫 Do not include secrets, credentials, private keys, tokens, private datasets, or personal data.

## Responsible disclosure

- Avoid public disclosure until a fix is available.
- We will coordinate on confirmation, remediation, release, and advisory when appropriate.
- Security fixes may also invalidate, quarantine, or revoke affected skill versions or sources.
