use serde::{Deserialize, Serialize};
#[derive(Debug, Serialize, Deserialize)]
pub struct Item { pub name: String, pub n: u32 }
pub fn make(name: &str) -> Item { Item { name: name.into(), n: 1 } }
// edit
// e1793694941
