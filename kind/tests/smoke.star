# kind/tests/smoke.star — stable across upstream releases, and RUNTIME-FREE.
#
# kind drives a container runtime, so almost every headline verb needs Docker
# or Podman. The container test legs have neither, and a runtime-dependent
# assertion would be an environment probe rather than a test. What IS hermetic:
# kind's own version reporting, and its cluster-config parser, which reads and
# validates the YAML it is handed BEFORE it ever reaches for a runtime.
#
# ⚠️ TWO near-misses are recorded here, because both LOOK hermetic on a
# developer box that happens to have Docker installed and are not:
#
#   `kind get clusters` — with Docker present but no clusters it exits 0 with
#   empty stdout; with no runtime binary on PATH it exits 1 (`failed to list
#   clusters: … exec: "docker": executable file not found in $PATH`). Measured
#   on the alpine:3.20 leg of this repo's first CI run.
#
#   A config whose FIELD VALUES are invalid (`networking.ipFamily: klingon`) —
#   kind probes the provider (`docker info`) BEFORE it schema-validates, so in
#   a runtime-less image the failure is the docker error, not the validation
#   error. The rejection is real either way, but the MESSAGE is not stable
#   across legs, and asserting it would be asserting the environment.
#
# Only the DECODE stage runs ahead of the provider probe, so only decode-stage
# rejections are usable. Both cases below are decode-stage, verified inside
# `docker run --rm alpine:3.20` with no runtime present. Dropped rather than
# weakened.
#
# Assert on the contract — exit code, version shape, and tokens echoed back out
# of values we fed in. Never on help or banner prose.

KIND = "kind.exe" if ocx.target_platform.os == ocx.os.Windows else "kind"

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# This is also the only check that the raw-binary bundle is executable at all:
# GitHub serves release assets without the exec bit, so a green here means
# metadata.json's `binaries` claim really did drive the 0755 chmod. On Windows
# it additionally proves the `name: kind.exe` asset_type override landed — the
# upstream asset has no suffix, and a bundle shipping bare `kind` would fail to
# resolve here.
r_version = ocx.run(KIND, "version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3: the config DECODER reads both type fields, and discriminates ────
# `create cluster` decodes its `--config` — reading `apiVersion` and `kind` and
# resolving them against its registered scheme — before it probes for a
# container runtime. Two rejections, not one, and deliberately for DIFFERENT
# reasons: a tool that merely passed its input through, or that blanket-refused
# every `--config`, would produce the same outcome for both. Each error names
# the offending token back to us, so what is asserted is derived from input we
# chose, not vendor prose. This pair is also the proof that a RED outcome is
# reachable from this script at all. Both messages measured byte-identical on
# v0.30.0 (oldest in range) and v0.32.0 (newest), inside alpine:3.20 with no
# container runtime present.

# (a) known apiVersion, unknown kind. The message echoes BOTH: it rejects
#     `Custer` while naming `kind.x-k8s.io/v1alpha4` as a version it accepts,
#     so this is a positive statement about the scheme as well as a rejection.
ocx.write_file(
    "bad-kind.yaml",
    "kind: Custer\napiVersion: kind.x-k8s.io/v1alpha4\n",
)
r_bad_kind = ocx.run(KIND, "create", "cluster", "--name", "ocx-smoke", "--config", "bad-kind.yaml")
expect.ne(r_bad_kind.exit_code, 0)
expect.contains(r_bad_kind.stderr, "Custer")
expect.contains(r_bad_kind.stderr, "kind.x-k8s.io/v1alpha4")

# (b) known kind, unknown apiVersion — the other field, rejected on its own.
ocx.write_file(
    "bad-apiversion.yaml",
    "kind: Cluster\napiVersion: kind.x-k8s.io/v1alpha1\n",
)
r_bad_api = ocx.run(KIND, "create", "cluster", "--name", "ocx-smoke", "--config", "bad-apiversion.yaml")
expect.ne(r_bad_api.exit_code, 0)
expect.contains(r_bad_api.stderr, "kind.x-k8s.io/v1alpha1")

# Different inputs must fail differently — otherwise the pair proves only that
# `--config` is refused, which is not the claim being made.
expect.ne(r_bad_api.stderr, r_bad_kind.stderr)

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proved it.
