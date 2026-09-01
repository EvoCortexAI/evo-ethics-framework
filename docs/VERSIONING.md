# Versioning

EvoEthics Framework uses semantic versions as the consumer-facing Swift package contract.

A released version identifies an immutable Git tag, and that tag resolves to one exact commit SHA. Saturn-Control and other consumers declare a semantic version requirement and commit `Package.resolved`. Raw commit SHAs remain provenance; they are not the normal dependency interface.

```text
semantic version = compatibility contract
Git tag          = immutable release identity
commit SHA       = source provenance
Package.resolved = exact consumer resolution
```

Do not use a floating branch as a package dependency. Do not retarget a released version tag. Do not treat a changelog section as a Git tag.

## Current release line

Changelog section `0.1.0` is proprietary history. It is **not** a Git tag on current `main` and must not be created on this tree.

The active pre-1.0 development-cueing line is `0.1.x`. The first published Git tag is `0.1.1` and is the first Apache-2.0 tagged release.

## Development cueing (`0.1.x`)

Every merge to `main` that has a green package CI run on that exact commit is assigned the next unused `0.1.x` tag.

Rules:

- Start after the untagged changelog `0.1.0` section. The first automatic cue is `0.1.1`.
- Increment only the patch component: `0.1.1`, `0.1.2`, ... Never skip, reuse, or retarget a patch.
- Tag the exact CI-green `main` SHA. Do not tag a merge commit that failed CI.
- A commit that already carries a `0.1.x` tag is left unchanged.
- Cueing tags are Apache-2.0 from `0.1.1` onward.
- Cueing tags may include source-breaking changes. Consumers review `Package.resolved` on their own PRs.
- Cueing tags do not require founder approval or a production-enforcement claim.
- `0.2.0` and later minors, and `1.0.0`, remain founder-gated formal releases.

Saturn-Control currently pins a revision. After `0.1.1` exists, a separate Control PR may switch to:

```swift
.package(
    url: "https://github.com/EvoCortexAI/evo-ethics-framework.git",
    .upToNextMinor(from: "0.1.1")
)
```

Do not pin `main`. Cueing does not authorize production ethics enforcement.

## After `1.0.0`

Breaking public API changes require a new major version. Automatic `0.1.x` cueing does not continue after `1.0.0`.

## Release provenance

```text
version -> immutable tag -> exact commit SHA
```
