///|
fn main {
  match @mavlink.generate_moonbit_from_xml(@mavlink.official_standard_xml) {
    Ok((_, generated_code)) => println(generated_code)
    Err(err) => println("Codegen error: \{err.to_repr()}")
  }
}
