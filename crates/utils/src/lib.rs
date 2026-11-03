pub fn to_json(i: &demo_core::Item) -> String { serde_json::to_string(i).unwrap() }
