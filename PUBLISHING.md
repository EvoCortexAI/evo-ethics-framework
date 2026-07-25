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

After the license and canonical-source decisions are approved and GitHub CLI is authenticated:

```sh
gh repo create EvoCortexAI/evo-ethics-framework \
  --public \
  --source=. \
  --remote=origin \
  --push
```

Then enable:

- branch protection on `main`
- pull-request review requirement
- signed commits or signed release tags
- private vulnerability reporting
- secret scanning and push protection where available
- GitHub Actions read-only default token permissions

Do not publish the internal audit report, operational addresses, secrets, current infrastructure inventory, unpublished product status, or incident records in this repository.
