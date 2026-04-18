# veri-core — Verified-Program rkyv Contract (veric↔semac)

veri-core defines the typed verified-and-linked program that
veric produces and semac/domainc/rsc/askid consume. corec
generates Rust with rkyv derives from the `.core` definitions.

Renamed from `sema-core` — the contract holds VERIFIED aski
(veric's output), not sema itself. Only semac produces true
sema binary; that format has no rkyv crate.

## Role in the Pipeline

```
corec       — .core → Rust with rkyv derives (bootstrap tool)
synth-core  — grammar contract (askicc↔askic)
aski-core   — parse tree contract (askic↔veric↔semac)
veri-core   — verified-program contract (veric↔semac) — THIS REPO
askicc      — source/<surface>/*.synth → dsls.rkyv
askic       — source + dsls.rkyv → per-module rkyv (aski-core types)
veric       — per-module rkyv → program.rkyv (veri-core types)
semac       — program.rkyv + domain types → .sema (pure binary)
```

## What It Holds

Post-resolution entities with absolute references and embedded
scope information. Each entity carries the list of things it
relates to — no string lookups at the semac stage.

## Files

- `source/program.core` — Program root, resolution structures
- `src/lib.rs` — re-exports aski-core + includes generated types

## Regenerate

```
corec source generated/veri_core.rs
```

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.
