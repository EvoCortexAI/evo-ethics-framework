# Publishing Plan

Target repository:

`EvoCortexAI/evo-ethics-framework`

Recommended description:

> Local-first, deterministic ethics-policy framework and conformance contract for EvoIntelligenceFabric and Saturn products.

Recommended topics:

- policy-as-code
- local-first
- swift
- governance
- auditability
- responsible-ai
- apple-silicon

**Prerequisite:** Complete every gate in `docs/PUBLIC-RELEASE-CHECKLIST.md` and obtain founder + legal approval. Do not flip visibility until that checklist is closed.

After the license and canonical-source decisions are approved and GitHub CLI is authenticated:

```sh
gh repo edit EvoCortexAI/evo-ethics-framework --visibility public
```

(or the equivalent create/push flow if the repository is being re-created).

Then enable:

- branch protection on `main`
- pull-request review requirement
- signed commits or signed release tags
- private vulnerability reporting
- secret scanning and push protection where available
- GitHub Actions read-only default token permissions

Do not publish the internal audit report, operational addresses, secrets, current infrastructure inventory, unpublished product status, or incident records in this repository.
