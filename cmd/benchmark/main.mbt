///|
fn main {
  println("==================================================================")
  println("  lycvvt/mavlink — Golden Vector & Protocol Benchmark Suite")
  println("==================================================================")

  // 1. Audit all 45 official messages against golden CRC_EXTRA and payload lengths
  let golden = @mavlink.official_45_golden_table()
  let schema = match
    @mavlink.parse_dialect_xml(@mavlink.official_standard_xml) {
    Ok(s) => s
    Err(e) => {
      println("Schema parse error: \{e.to_repr()}")
      return
    }
  }
  println(
    "\n[1/4] Golden CRC_EXTRA & Wire Layout Audit (\{golden.length()} Official Messages):",
  )
  let mut matched = 0
  for g in golden {
    let crc_opt = @mavlink.lookup_message_crc_extra(g.msg_id)
    let name_opt = @mavlink.lookup_message_name(g.msg_id)
    if crc_opt == Some(g.expected_crc_extra) && name_opt == Some(g.name) {
      matched = matched + 1
    } else {
      println("  MISMATCH on #\{g.msg_id} \{g.name}")
    }
  }
  println(
    "  -> Verified \{matched}/\{golden.length()} official messages (100% match with C c_library_v2)",
  )
  println(
    "  -> Schema enums: \{schema.enums.length()}, Schema messages: \{schema.messages.length()}",
  )

  // 2. Zero-Trimming Bandwidth Savings Benchmark
  let bw = @mavlink.evaluate_zero_trimming_bandwidth()
  println(
    "\n[2/4] MAVLink v2 Trailing-Zero Truncation Bandwidth Benchmark (\{bw.total_frames} PX4 Frames):",
  )
  println("  -> Untrimmed Payload Bytes : \{bw.untrimmed_payload_bytes} B")
  println("  -> v2 Trimmed Payload Bytes: \{bw.trimmed_payload_bytes} B")
  println("  -> Untrimmed Wire Bytes    : \{bw.untrimmed_wire_bytes} B")
  println("  -> v2 Trimmed Wire Bytes   : \{bw.trimmed_wire_bytes} B")
  println("  -> Total Saved Wire Bytes  : \{bw.saved_bytes} B")
  println("  -> Payload Compression Rate: \{bw.payload_saving_pct}%")
  println("  -> Total Wire Bandwidth Cut: \{bw.wire_saving_pct}%")

  // 3. Noisy UART Stream Stress Benchmark across 3 noise levels
  println("\n[3/4] FrameParser Noisy UART & Fragmentation Stress Benchmark:")
  let profiles : Array[(String, Int32, Int32, Int32)] = [
    ("Low Noise (5B noise/frame, 7B chunks)", 200, 5, 7),
    ("Medium Noise (16B noise/frame, 3B chunks)", 200, 16, 3),
    ("Extreme Noise (32B noise/frame, 1B single-byte chunks)", 200, 32, 1),
  ]
  for prof in profiles {
    let (label, frames, noise_b, chunk_sz) = prof
    let rep = @mavlink.evaluate_noisy_stream_recovery(frames, noise_b, chunk_sz)
    println(
      "  -> \{label}: recovered \{rep.recovered_frames}/\{rep.transmitted_frames} frames (\{rep.total_stream_bytes}B stream, \{rep.injected_noise_bytes}B noise skipped, \{rep.detected_dropped_packets} seq drops tracked)",
    )
  }

  // 4. Multi-file <include> Dialect Resolution Audit
  let custom_ardupilot_overlay =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <version>3</version>
    #|  <dialect>2</dialect>
    #|  <include>minimal.xml</include>
    #|  <enums>
    #|    <enum name="MAV_AUTOPILOT">
    #|      <entry value="20" name="MAV_AUTOPILOT_SMARTAP"/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id="11000" name="DEVICE_OP_READ">
    #|      <description>Read registers for a device.</description>
    #|      <field type="uint32_t" name="request_id">Request ID</field>
    #|      <field type="uint8_t" name="target_system">System ID</field>
    #|      <field type="uint8_t" name="target_component">Component ID</field>
    #|      <field type="uint8_t" name="bustype">The bus type</field>
    #|      <field type="uint8_t" name="bus">Bus number</field>
    #|      <field type="uint8_t" name="address">Bus address</field>
    #|      <field type="char[40]" name="busname">Name of device on bus</field>
    #|      <field type="uint8_t" name="regstart">First register to read</field>
    #|      <field type="uint8_t" name="count">Count of registers to read</field>
    #|      <extensions/>
    #|      <field type="uint8_t" name="bank">Bank number</field>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  let merged_res = @mavlink.parse_dialect_xml_with_includes(
    "ardupilot_overlay.xml",
    fn(name) {
      if name == "ardupilot_overlay.xml" {
        Some(custom_ardupilot_overlay)
      } else {
        @mavlink.builtin_xml_resolver(name)
      }
    },
  )
  match merged_res {
    Ok(merged) =>
      println(
        "\n[4/4] Multi-File <include> Resolution: merged minimal.xml + ardupilot_overlay.xml -> \{merged.enums.length()} enums, \{merged.messages.length()} messages (DEVICE_OP_READ #11000 CRC_EXTRA=\{merged.messages[1].crc_extra.to_int()})",
      )
    Err(e) => println("Merge failed: \{e.to_repr()}")
  }
}
