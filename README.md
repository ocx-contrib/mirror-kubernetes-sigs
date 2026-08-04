# mirror-kubernetes-sigs

OCX mirrors for tools published by
[Kubernetes SIGs](https://github.com/kubernetes-sigs). One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [kind](https://github.com/kubernetes-sigs/kind) | [`kind/mirror.yml`](kind/mirror.yml) | `ghcr.io/ocx-contrib/kubernetes-sigs/kind` | `ocx.sh/kubernetes-sigs/kind` | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
kind/                   one directory per package — same five files each
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all. `mirror-base.yml` here deliberately carries **no** `platforms:`
block: the packages in this repo have different asset shapes and different
upstream platform coverage, so each spec owns its matrix outright and cannot
partially restate anything.

## Platforms

Everything here is a pure-Go, cgo-free static build — no `PT_INTERP`, no
`DT_NEEDED`, no UPX packing — so the Linux platform keys are **bare**:
`os.features` states what an artifact *requires of the host*, and tagging a
static binary `+libc.musl` would be a false requirement that hid it from every
glibc host. The `alpine:3.20` container leg beside `ubuntu:24.04` and
`fedora:40` is what turns that universal claim into evidence. The measurement
itself is recorded above each spec's `assets:` block.

`kind` publishes **five** platform entries — both Linux arches, both macOS
arches and `windows/amd64` — rolled out in staged passes (linux, then darwin,
then windows), each its own commit and CI run. **`windows/arm64` is not
declared, because upstream does not ship it**: the only Windows asset in
v0.30.0, v0.31.0 and v0.32.0 is `kind-windows-amd64`. A declared-but-unmatched
platform is not free — the generated test matrix is static, so the leg would
boot a `windows-11-arm` runner, skip every version and report success having
tested nothing.

kind's assets are **raw unversioned binaries**, not archives:
`kind-<os>-<arch>` is the byte-identical filename in every release. Two
consequences are wired into the spec. GitHub serves raw assets without the
exec bit, and `prepare` chmods 0755 only the binaries `metadata.json`
*declares* — so that list is load-bearing, not documentation. And
`asset_type: binary` **preserves** whatever suffix the upstream name carries
rather than synthesising one: `kind-windows-amd64` has no `.exe`, so
`kind/mirror.yml` carries an explicit `name: kind.exe` override for that
platform. Both were measured with a local `pipeline prepare`, no runner
involved.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `<pkg>/mirror.yml` | hand | yes — see below |
| `<pkg>/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `<pkg>/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci \
  --spec kind/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
