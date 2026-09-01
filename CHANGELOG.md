# Changelog

## Unreleased

- Add automatic `0.1.x` cueing: every green merge to `main` receives the next unused `0.1.x` tag starting at `0.1.1` (first Apache-2.0 published git tag). Changelog `0.1.0` remains proprietary history and is not a git tag.
- Relicensed current `main` first-party materials under Apache License 2.0. Third-party components remain under their own terms. Repository visibility and the closed external-contribution policy are unchanged by the license text.
- Changelog version `0.1.0` remains under the proprietary terms present when that section was recorded. The first published Apache-2.0 git tag is `0.1.1`.
- Remove false `EvoEthics` → `SaturnAuthority` SPM dependency. Products remain co-located but independent (ADR 0003).
- EvoEthicsTests no longer depends on SaturnAuthority.

## 0.1.0

- Initial reference evaluator, policy bundle loader, and SaturnAuthority contract types.
