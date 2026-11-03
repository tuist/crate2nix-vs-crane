# crate2nix vs crane: what rebuilds when one workspace crate changes

Minimal Cargo workspace built two ways from one flake:

- `.#default` — crate2nix (`crate2nix generate` → checked-in `Cargo.nix`, `pkgs.callPackage ./Cargo.nix {}`). One Nix derivation per crate (third-party and workspace).
- `.#crane` — crane `buildDepsOnly` + `buildPackage`. Third-party deps in one derivation, the whole workspace in another.

Workspace graph: `demo-app` (bin) → `demo-utils` → `demo-core`; `demo-app` → `demo-leaf`, `demo-core`.
Third-party: serde (+derive), serde_json, anyhow.

## Run

```sh
nix shell nixpkgs#cargo nixpkgs#crate2nix -c crate2nix generate   # after any Cargo.toml/Cargo.lock change
./measure.sh default "label"   # or: ./measure.sh crane "label"
```
`measure.sh` lists the derivations `nix build --dry-run` says will be built, then builds with `-L` and prints which workspace crates cargo compiled (crane only).

## Results (Determinate Nix 2.35 / nixpkgs unstable 2026-11-01, crate2nix 0.15.0, 8 cores)

| Change | crate2nix derivations rebuilt | crane derivations rebuilt | crates compiled by crane |
|---|---|---|---|
| cold | 28 (each 3rd-party crate + each workspace crate) | 37 (vendoring, `demo-deps`, `demo`) | all |
| no-op | 0 | 0 | — |
| edit `app` | `demo-app` | `demo` | core, utils, leaf, app |
| edit `leaf` | `demo-leaf`, `demo-app` | `demo` | core, utils, leaf, app |
| edit `core` | `demo-core`, `demo-utils`, `demo-app` | `demo` | core, utils, leaf, app |

In every incremental case serde/serde_json/anyhow etc. were reused by both tools. With crate2nix, untouched workspace crates (e.g. `demo-core`, `demo-utils` when editing `leaf`) were reused; crane recompiled all four workspace crates on any edit. Wall times here are ~1 s per step because the crates are trivial; the point is the rebuild set, which is what scales with workspace size.

## Caveats

- `Cargo.nix` must be regenerated whenever `Cargo.toml`/`Cargo.lock` changes (or use crate2nix's IFD `tools.nix` path, which costs import-from-derivation at eval time).
- Eval time grows with crate count (one derivation per crate); measured eval+plan was ~0.5–1 s here, larger for big lockfiles.
- No incremental compilation inside a crate: an edited crate is rebuilt from scratch, and every reverse-dependent is rebuilt too (editing a crate near the root still rebuilds most of the workspace).
- Crates with build scripts that need native libs/tools (openssl-sys, prost-build/protoc, bindgen, …) need `defaultCrateOverrides`/`crateOverrides`. Many are covered by nixpkgs' defaults; others need manual entries.
- `buildRustCrate` calls rustc directly, not cargo; occasionally features/build-script behaviour differ from cargo.
