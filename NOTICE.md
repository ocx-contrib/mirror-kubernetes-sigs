# NOTICE

This repository packages and redistributes upstream software published by
[Kubernetes SIGs](https://github.com/kubernetes-sigs). The Apache-2.0 license
in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `kind` | `ghcr.io/ocx-contrib/kubernetes-sigs/kind` | `Apache-2.0` |

---

## `kind`

Upstream: <https://github.com/kubernetes-sigs/kind>
Published to `ghcr.io/ocx-contrib/kubernetes-sigs/kind`.

| Component | SPDX | Holder |
|---|---|---|
| kind (`kind`) | **Apache-2.0** | Copyright The Kubernetes Authors |

Permissive; redistribution of the compiled binary is granted under the terms of
<https://github.com/kubernetes-sigs/kind/blob/main/LICENSE>. Verified via
`gh api repos/kubernetes-sigs/kind/license --jq '.license.spdx_id'` →
`Apache-2.0`. Upstream ships raw binaries with no bundled `LICENSE` file, so
the terms are referenced here rather than travelling with the artifact.

The binary is a pure-Go static build that links third-party Go modules under
permissive licenses, enumerated in upstream's `go.mod`.

The kind logo (`kind/logo.svg`, and `kind/logo.png` rendered from it) is
reproduced from upstream's `logo/logo.svg`, which upstream licenses under **a
choice of either Apache-2.0 or CC-BY-4.0**
(<https://github.com/kubernetes-sigs/kind/blob/main/logo/LICENSE>). It is used
here for catalog identification. Kubernetes and the Kubernetes wheel are
trademarks of The Linux Foundation.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
