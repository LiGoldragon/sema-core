# veri-core — Verified-Program rkyv Contract (veric↔semac)

veri-core defines the typed, verified, linked program that veric
produces and semac/domainc/rsc/askid consume. corec generates Rust
with rkyv derives from the `.core` definitions.

**Renamed from `sema-core` on 2026-04-18.** Reason: the contract
holds VERIFIED aski (veric's output), not sema. Only semac produces
true sema binary; that format has no rkyv crate.

## Role in the Pipeline

```
corec        — .core → Rust with rkyv derives (bootstrap tool)
synth-core   — grammar contract (askicc↔askic)
aski-core    — parse-tree contract (askic↔veric↔semac)
veri-core    — verified-program contract (veric↔semac) — THIS REPO
askicc       — source/<surface>/*.synth → dsls.rkyv
askic        — .aski source + dsls.rkyv → per-module rkyv (aski-core types)
veric        — per-module rkyv → program.rkyv (veri-core types)
semac        — program.rkyv + domain types → .sema (pure binary)
```

## Intended Shape (D6 — redesign pending)

Each entity carries its own absolute-reference index of things it
relates to. **No separate Scope wrapper type** — scope information
is embedded directly on the entity as fields. Lexical scope levels
(module → impl → method → block) are resolved via shadowing during
veric's pass; by veri-core output, every reference is absolute.

**Parallel types (D3).** veri-core defines its own `Module`, `Enum`,
`Struct`, etc. — mirroring aski-core but with resolved references
and scope embedded. NOT a sidecar to aski-core types.

Key concepts (planned):
- `EntityRef { module: u32, kind: EntityKind, index: u32 }` —
  absolute pointer into the program's entity table.
- `Program { modules: Vec<Module> }` — root.
- Each `Module` carries resolved `Imports` (list of `EntityRef`s),
  its own `Enums`/`Structs`/…, and everything the module uses.
- Each entity (Struct, Enum, Method, Trait, …) carries
  `relates_to: Vec<EntityRef>` — the things it references in its
  content. semac/domainc/rsc consume these directly, no string
  lookups.

## Current State (pre-redesign)

`source/program.core` still has the pre-v0.18 resolution-table shape:
`TypeLocation`, `ModuleEntry`, `TraitEntry`, `ResolvedImport`,
`ImportResolution`, `ResolutionTable`. This WORKS with minimum
updates (`aski_core::ModuleDef` → `Module`) but doesn't reflect
the D6 intent.

**Next work: rewrite program.core to the D6 shape.**

## Files

- `source/program.core` — Program root + resolution structures
- `src/lib.rs` — re-exports aski-core + includes generated types

## Regenerate

```
corec source generated/veri_core.rs
```

In nix, the flake runs corec automatically.

## VCS

`jj` mandatory. Git is storage backend only.
