fn main() -> anyhow::Result<()> {
    let i = demo_core::make("x");
    println!("{} {}", demo_leaf::greet(), demo_utils::to_json(&i));
    Ok(())
}
