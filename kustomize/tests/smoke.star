# kustomize/tests/smoke.star — stable across upstream releases, and hermetic.
#
# kustomize reads local YAML and writes rendered YAML to stdout. That makes it
# one of the rare tools whose headline verb is fully testable with no network,
# no daemon and no cluster: the fixture below is written into the test sandbox
# and `build` is the real thing, not a proxy for it.
#
# Assert on the contract — exit code, version shape, and the CONTENT of the
# render (a value we fed in, coming back transformed, plus a content address
# kustomize computed). Never on help or banner prose.

KUSTOMIZE = "kustomize.exe" if ocx.target_platform.os == ocx.os.Windows else "kustomize"

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# `kustomize version` prints the bare version and nothing else (measured:
# stdout is exactly "v5.8.1\n" on 5.8.1). The digits are the contract; the
# exact version is not, and neither is the leading `v`.
r_version = ocx.run(KUSTOMIZE, "version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3: a real render, asserted on its OUTPUT ───────────────────────────
# The fixture exercises two independent parts of the engine:
#
#   * `configMapGenerator` — kustomize SYNTHESISES a ConfigMap from literals
#     and appends a hash of its content to the name. That suffix is a computed
#     content address, not an echo, so a build that silently produced nothing
#     or copied its input through cannot produce it.
#   * `namePrefix` — a transformer that must run over the generated object
#     AFTER it exists, so `ocx-` appearing ahead of the generated name proves
#     the two stages composed in the right order.
#
# Asserting the hash's SHAPE rather than its literal value is deliberate. The
# value is in fact stable — 5.7.1, 5.8.0 and 5.8.1 all render
# `ocx-smoke-g7bf6bb4d6` from this input — but pinning it would red a future
# release for a legitimate change in how kustomize serialises or hashes a
# ConfigMap, which is not this mirror's contract. That it computes a
# well-formed one at all is.
ocx.write_file(
    "kustomization.yaml",
    "apiVersion: kustomize.config.k8s.io/v1beta1\n" +
    "kind: Kustomization\n" +
    "namePrefix: ocx-\n" +
    "configMapGenerator:\n" +
    "  - name: smoke\n" +
    "    literals:\n" +
    "      - answer=42\n",
)

r_build = ocx.run(KUSTOMIZE, "build", ".")
expect.ok(r_build)
expect.contains(r_build.stdout, "kind: ConfigMap")
# The literal we fed in, round-tripped and re-quoted as a YAML string value.
expect.contains(r_build.stdout, "answer: \"42\"")
# namePrefix applied to a generated name, plus kustomize's content-hash suffix.
expect.matches(r_build.stdout, r"name: ocx-smoke-[a-z0-9]{10}")

# ── NEGATIVE CONTROL ────────────────────────────────────────────────────────
# `build` is output-shaped, so a tool that merely concatenated whatever it
# found would pass everything above. This kustomization references a resource
# that does not exist: a real accumulator must fail. It is also the proof that
# a RED outcome is reachable from this script at all. Measured non-zero on
# 5.7.1 and 5.8.1.
ocx.mkdir("broken")
ocx.write_file(
    "broken/kustomization.yaml",
    "apiVersion: kustomize.config.k8s.io/v1beta1\n" +
    "kind: Kustomization\n" +
    "resources:\n" +
    "  - does-not-exist.yaml\n",
)
r_broken = ocx.run(KUSTOMIZE, "build", "broken")
expect.ne(r_broken.exit_code, 0)
expect.contains(r_broken.stderr, "does-not-exist.yaml")

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proved it.
