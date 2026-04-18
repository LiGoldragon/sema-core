// veri-core — the rkyv contract types for veric→semac.
//
// Verified program: Vec<ModuleDef> + ResolutionTable.
// veric serializes, semac/domainc/rsc/askid deserialize.
//
// Run `corec source generated/veri_core.rs` to regenerate.
// Domain definitions are in source/*.core.

pub use aski_core;

use rkyv::{Archive, Serialize, Deserialize};

// ── The verified program ────────────────────────────────

#[derive(Archive, Serialize, Deserialize, Debug, Clone, PartialEq)]
#[rkyv(serialize_bounds(
    __S: rkyv::ser::Writer + rkyv::ser::Allocator,
    __S::Error: rkyv::rancor::Source))]
#[rkyv(deserialize_bounds(__D::Error: rkyv::rancor::Source))]
pub struct Program {
    #[rkyv(omit_bounds)]
    pub modules: Vec<aski_core::Module>,
    pub resolution: ResolutionTable,
}

// ── Generated resolution types ──────────────────────────

include!("../generated/veri_core.rs");
