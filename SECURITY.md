# Security Policy

We take security seriously.

Please report security vulnerabilities **privately**.
Do **not** open public GitHub Issues for security reports.

## Report a security issue (private)

**Preferred (fastest):**
- GitHub Security Advisories (Private Vulnerability Reporting)

**If Security Advisories are not available:**
- Contact the maintainer(s) privately via the repository contact methods.

## Vulnerability coordination

Security fixes are prioritized.
We coordinate remediation privately with relevant stakeholders via GitHub Security Advisories.

Stakeholders may include:
- the reporter
- affected users
- maintainers of relevant dependencies or tools (when applicable)

Participation in coordinated disclosure is at the discretion of the `aliasx` team.

## Disclosure

We aim to be transparent once a fix is ready.
Confirmed issues may be announced via:
- GitHub Release notes
- GitHub Security Advisories
- ecosystem advisory channels (when applicable)

## What counts as a security issue

Examples include:
- command injection / unintended execution paths
- privilege escalation or unsafe defaults in automation contexts
- leaking secrets in logs/output (tokens, keys, credentials)
- destructive file operations beyond intended scope
- supply-chain integrity issues with clear real-world impact
