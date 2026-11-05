///|
fn bytes_to_hex_preview(data : Bytes, max_bytes : Int32) -> String {
  let hex = "0123456789ABCDEF".to_array()
  let sb = StringBuilder()
  let limit = if data.length() < max_bytes { data.length() } else { max_bytes }
  for i = 0; i < limit; i = i + 1 {
    if i > 0 {
      sb.write_char(' ')
    }
    let u = data[i].to_int() & 0xFF
    sb.write_char(hex[(u >> 4) & 0x0F])
    sb.write_char(hex[u & 0x0F])
  }
  if data.length() > max_bytes {
    sb.write_string(" ...")
  }
  sb.to_string()
}

///|
fn main {
  println(
    "======================================================================",
  )
  println("  MoonBit MAVLink v2 Protocol & XML Codegen Demo (lycvvt/mavlink)")
  println(
    "======================================================================\n",
  )

  // --------------------------------------------------------------------------
  // Part 1: Parse Official MAVLink XML & Verify Code Generation Metadata
  // --------------------------------------------------------------------------
  let (schema, generated_src) = match
    @mavlink.generate_moonbit_from_xml(@mavlink.official_standard_xml) {
    Ok(res) => res
    Err(e) => {
      println("XML Codegen Error: \{e.to_repr()}")
      return
    }
  }
  println(
    "[1] Official MAVLink XML Schema Parsed & Code Generated Successfully:",
  )
  println(
    "    - Protocol Version : \{schema.version}, Dialect: \{schema.dialect}",
  )
  println(
    "    - Enums Parsed     : \{schema.enums.length()}, Messages Parsed: \{schema.messages.length()}",
  )
  println(
    "    - Generated Code   : \{generated_src.length()} characters of strongly-typed MoonBit\n",
  )
  println(
    "    ID   | Message Name         | BaseLen | MaxLen | CRC_EXTRA | First Wire Field",
  )
  println(
    "    -----+----------------------+---------+--------+-----------+--------------------",
  )
  for m in schema.messages {
    let first_field = if m.wire_ordered_fields.length() > 0 {
      m.wire_ordered_fields[0].name +
      " (" +
      m.wire_ordered_fields[0].wire_type +
      ")"
    } else {
      "-"
    }
    let crc_val = m.crc_extra.to_int() & 0xFF
    println(
      "    #\{m.id} | \{m.name} | \{m.base_payload_len}B | \{m.max_payload_len}B | \{crc_val} | \{first_field}",
    )
  }

  // --------------------------------------------------------------------------
  // Part 2: Closed-Loop UAV (PX4, sysid=1) <-> GCS (QGC, sysid=255) Simulation
  // --------------------------------------------------------------------------
  println(
    "\n----------------------------------------------------------------------",
  )
  println(
    "[2] UAV (PX4 Quadrotor, sysid=1) <-> Ground Control Station (sysid=255)",
  )
  println("    Full-Duplex MAVLink v2 Signed & Streaming Telemetry Simulation")
  println(
    "----------------------------------------------------------------------",
  )

  let shared_secret = b"px4-gcs-mavlink-v2-secret-key-32"
  let gcs_signer = match
    @mavlink.SigningContext::new(
      shared_secret,
      link_id=b'\x01',
      initial_timestamp=500000UL,
    ) {
    Ok(ctx) => ctx
    Err(_) => return
  }
  let uav_verifier = match
    @mavlink.SigningContext::new(
      shared_secret,
      link_id=b'\x01',
      initial_timestamp=500000UL,
    ) {
    Ok(ctx) => ctx
    Err(_) => return
  }

  // Step A: GCS sends signed COMMAND_LONG (MAV_CMD_COMPONENT_ARM_DISARM = 400)
  let arm_cmd : @mavlink.CommandLong = {
    target_system: b'\x01',
    target_component: b'\x01',
    command: @mavlink.MavCmd::ComponentArmDisarm.to_uint(),
    confirmation: b'\x00',
    param1: (1.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    param5: (0.0 : Float),
    param6: (0.0 : Float),
    param7: (0.0 : Float),
  }
  let (cmd_wire, cmd_frame) = match
    @mavlink.MavMessage::MsgCommandLong(arm_cmd).encode_to_frame(
      seq=b'\x00',
      sysid=b'\xFF',
      compid=b'\xBE',
      signing=Some(gcs_signer),
    ) {
    Ok(res) => res
    Err(_) => return
  }
  println(
    "\n  [GCS -> UAV] Sent Signed COMMAND_LONG (MAV_CMD_COMPONENT_ARM_DISARM):",
  )
  println(
    "    - Wire Frame Length : \{cmd_wire.length()}B (Payload zero-trimmed: \{cmd_frame.payload.length()}B / 33B, +13B SHA-256 signature)",
  )
  println("    - Wire Hex Preview  : [\{bytes_to_hex_preview(cmd_wire, 16)}]")

  // UAV verifies signature and decodes command
  match
    @mavlink.decode_frame(
      cmd_wire,
      @mavlink.lookup_message_crc_extra,
      signing=Some(uav_verifier),
    ) {
    Ok((verified_frame, _)) =>
      match @mavlink.MavMessage::decode_from_frame(verified_frame) {
        Ok(@mavlink.MavMessage::MsgCommandLong(c)) =>
          println(
            "  [UAV Rx] Signature Verified! Executing Command #\{c.command} (param1=\{c.param1})",
          )
        _ => ()
      }
    Err(e) => println("  [UAV Rx Error] \{e.to_repr()}")
  }

  // Step B: UAV emits telemetry burst over a noisy fragmented byte stream
  let uav_messages : Array[@mavlink.MavMessage] = [
    @mavlink.MavMessage::MsgHeartbeat({
      mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
      autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
      base_mode: (@mavlink.MavModeFlag::CustomModeEnabled.to_uint() |
      @mavlink.MavModeFlag::GuidedEnabled.to_uint() |
      @mavlink.MavModeFlag::SafetyArmed.to_uint()).to_byte(),
      custom_mode: 0x04010000U,
      system_status: @mavlink.MavState::Active.to_uint().to_byte(),
      mavlink_version: b'\x03',
    }),
    @mavlink.MavMessage::MsgCommandAck({
      command: @mavlink.MavCmd::ComponentArmDisarm.to_uint(),
      result: @mavlink.MavResult::Accepted.to_uint().to_byte(),
      progress: (100).to_byte(),
      result_param2: 0,
      target_system: b'\xFF',
      target_component: b'\xBE',
    }),
    @mavlink.MavMessage::MsgGpsRawInt({
      time_usec: 1730000500000UL,
      fix_type: @mavlink.GpsFixType::RtkFixed.to_uint().to_byte(),
      lat: 225430960,
      lon: 1140578650,
      alt: 35200,
      eph: 80U,
      epv: 100U,
      vel: 450U,
      cog: 18000U,
      satellites_visible: (21).to_byte(),
      alt_ellipsoid: 38100,
      h_acc: 12U,
      v_acc: 18U,
      vel_acc: 8U,
      hdg_acc: 40U,
      yaw: 18000U,
    }),
    @mavlink.MavMessage::MsgGlobalPositionInt({
      time_boot_ms: 12500U,
      lat: 225430960,
      lon: 1140578650,
      alt: 35200,
      relative_alt: 15000,
      vx: 420,
      vy: 110,
      vz: -80,
      hdg: 18000U,
    }),
    @mavlink.MavMessage::MsgStatustext({
      severity: @mavlink.MavSeverity::Info.to_uint().to_byte(),
      text: "PX4: Armed, RTK Fixed, climbing to 15.0m",
      id: 1U,
      chunk_seq: b'\x00',
    }),
  ]

  let uart_stream : Array[Byte] = [b'\x00', b'\xFF', b'\x42'] // Leading UART noise
  for i = 0; i < uav_messages.length(); i = i + 1 {
    match
      uav_messages[i].encode_to_frame(
        seq=i.to_byte(),
        sysid=b'\x01',
        compid=b'\x01',
      ) {
      Ok((wire, _)) =>
        for b_idx = 0; b_idx < wire.length(); b_idx = b_idx + 1 {
          uart_stream.push(wire[b_idx])
        }
      Err(_) => ()
    }
  }

  let gcs_parser = @mavlink.FrameParser::new()
  println(
    "\n  [UAV -> GCS] Streaming \{uart_stream.length()} bytes (with 3 leading noise bytes) in 7-byte UART chunks...",
  )
  let mut cursor = 0
  while cursor < uart_stream.length() {
    let chunk : Array[Byte] = []
    for k = 0; k < 7 && cursor + k < uart_stream.length(); k = k + 1 {
      chunk.push(uart_stream[cursor + k])
    }
    cursor = cursor + chunk.length()
    let events = gcs_parser.push_bytes(
      Bytes::from_array(chunk),
      @mavlink.lookup_message_crc_extra,
    )
    for ev in events {
      match ev {
        @mavlink.ParseStreamEvent::FrameDecoded(frame) =>
          match @mavlink.MavMessage::decode_from_frame(frame) {
            Ok(@mavlink.MavMessage::MsgHeartbeat(hb)) =>
              println(
                "    -> [Seq #\{frame.header.seq.to_int()}] HEARTBEAT (autopilot=\{hb.autopilot.to_int()}, armed=true, v=\{hb.mavlink_version.to_int()})",
              )
            Ok(@mavlink.MavMessage::MsgCommandAck(ack)) =>
              println(
                "    -> [Seq #\{frame.header.seq.to_int()}] COMMAND_ACK (cmd=\{ack.command}, result=\{ack.result.to_int()}, progress=\{ack.progress.to_int()}%)",
              )
            Ok(@mavlink.MavMessage::MsgGpsRawInt(gps)) =>
              println(
                "    -> [Seq #\{frame.header.seq.to_int()}] GPS_RAW_INT (sats=\{gps.satellites_visible.to_int()}, h_acc=\{gps.h_acc}mm [v2 ext], yaw=\{gps.yaw}cdeg [v2 ext])",
              )
            Ok(@mavlink.MavMessage::MsgGlobalPositionInt(pos)) =>
              println(
                "    -> [Seq #\{frame.header.seq.to_int()}] GLOBAL_POSITION_INT (lat=\{pos.lat}, lon=\{pos.lon}, rel_alt=\{pos.relative_alt}mm)",
              )
            Ok(@mavlink.MavMessage::MsgStatustext(st)) =>
              println(
                "    -> [Seq #\{frame.header.seq.to_int()}] STATUSTEXT [sev=\{st.severity.to_int()}]: \"\{st.text}\"",
              )
            _ => ()
          }
        @mavlink.ParseStreamEvent::FrameError(err) =>
          println("    -> [Stream Error]: \{err.to_repr()}")
      }
    }
  }

  println(
    "\n  [GCS Link Stats] Packets Received: \{gcs_parser.packets_received}, Dropped: \{gcs_parser.packets_dropped}, CRC Errors: \{gcs_parser.crc_errors}, Noise Skipped: \{gcs_parser.noise_bytes_skipped}B",
  )
  println(
    "======================================================================",
  )
}
