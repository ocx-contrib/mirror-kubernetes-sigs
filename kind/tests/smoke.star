# kind/tests/smoke.star — stable across upstream releases, and RUNTIME-FREE.
#
# kind drives a container runtime, so almost every headline verb needs Docker
# or Podman. The container test legs have neither, and a network- or
# daemon-dependent assertion would be a flake rather than a test. What IS
# hermetic: kind's own version reporting, its provider enumeration (which
# reports an empty set rather than failing when no runtime is present), and its
# cluster-config parser, which validates the YAML it is handed BEFORE it ever
# reaches for a runtime.
#
# Assert on the contract — exit code, version shape, result count, and a token
# echoed back out of a value we fed in. Never on help or banner prose.

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

# ── Tier 3a: provider enumeration returns an EMPTY SET, not an error ────────
# Asserting the COUNT (zero clusters ⇒ nothing on stdout), not the exit code
# alone: kind prints "No kind clusters found." to STDERR and leaves stdout
# empty, so an empty stdout is the result, and a binary that had printed
# anything here would have found a cluster that does not exist.
r_list = ocx.run(KIND, "get", "clusters")
expect.ok(r_list)
expect.eq(r_list.stdout, "")

# ── Tier 3b: the config parser actually parses — NEGATIVE CONTROL ───────────
# `create cluster` validates its `--config` against kind's own v1alpha4 schema
# before touching any container runtime, so this path is hermetic. A tool that
# merely passed its input through would happily accept `ipFamily: klingon`;
# this fails non-zero and names the offending value back to us, which is a
# computed result rather than prose. It is also the proof that a RED outcome is
# reachable from this script at all.
ocx.write_file(
    "bad-cluster.yaml",
    "kind: Cluster\napiVersion: kind.x-k8s.io/v1alpha4\nnetworking:\n  ipFamily: klingon\n",
)
r_bad = ocx.run(KIND, "create", "cluster", "--name", "ocx-smoke", "--config", "bad-cluster.yaml")
expect.ne(r_bad.exit_code, 0)
expect.contains(r_bad.stderr, "klingon")

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proved it.
