///|
test "x25 crc16 standard vector and official message crc_extra values" {
  // Standard ASCII "123456789" X.25 internal CRC value before complement is 0x6F91
  let check_bytes = b"123456789"
  assert_eq(crc16_calculate(check_bytes), 0x6F91U)

  // Verify generated official CRC_EXTRA constants match MAVLink reference table
  assert_eq(Heartbeat::crc_extra(), (50).to_byte())
  assert_eq(SysStatus::crc_extra(), (124).to_byte())
  assert_eq(Ping::crc_extra(), (237).to_byte())
  assert_eq(ParamRequestRead::crc_extra(), (214).to_byte())
  assert_eq(ParamValue::crc_extra(), (220).to_byte())
  assert_eq(GpsRawInt::crc_extra(), (24).to_byte())
  assert_eq(Attitude::crc_extra(), (39).to_byte())
  assert_eq(GlobalPositionInt::crc_extra(), (104).to_byte())
  assert_eq(CommandLong::crc_extra(), (152).to_byte())
  assert_eq(CommandAck::crc_extra(), (143).to_byte())
  assert_eq(Statustext::crc_extra(), (83).to_byte())
}

///|
test "heartbeat wire field reordering and v1/v2 frame roundtrip" {
  let hb : Heartbeat = {
    mav_type: MavType::Quadrotor.to_uint().to_byte(),
    autopilot: MavAutopilot::Px4.to_uint().to_byte(),
    base_mode: (MavModeFlag::CustomModeEnabled.to_uint() |
    MavModeFlag::StabilizeEnabled.to_uint() |
    MavModeFlag::SafetyArmed.to_uint()).to_byte(),
    custom_mode: 0x04010000U,
    system_status: MavState::Active.to_uint().to_byte(),
    mavlink_version: b'\x03',
  }

  // Wire order for HEARTBEAT must place custom_mode (uint32_t) at bytes 0..3,
  // followed by type(4), autopilot(5), base_mode(6), system_status(7), mavlink_version(8).
  let payload = hb.encode_payload(v2=true)
  assert_eq(payload.length(), 9)
  assert_eq(payload[0], b'\x00')
  assert_eq(payload[1], b'\x00')
  assert_eq(payload[2], b'\x01')
  assert_eq(payload[3], b'\x04')
  assert_eq(payload[4], b'\x02') // MAV_TYPE_QUADROTOR = 2
  assert_eq(payload[5], b'\x0C') // MAV_AUTOPILOT_PX4 = 12
  assert_eq(payload[6], (1 + 16 + 128).to_byte())
  assert_eq(payload[7], b'\x04') // MAV_STATE_ACTIVE = 4
  assert_eq(payload[8], b'\x03')

  // Full MAVLink v2 frame roundtrip
  let msg = MsgHeartbeat(hb)
  let (v2_wire, v2_frame) = match
    msg.encode_to_frame(seq=b'\x07', sysid=b'\x01', compid=b'\x01', version=V2) {
    Ok(res) => res
    Err(e) => fail("v2 encode failed: \{e.to_repr()}")
  }
  assert_eq(v2_wire[0], MAVLINK_STX_V2)
  assert_eq(v2_wire.length(), 1 + V2_HEADER_LEN + 9 + 2)
  let (decoded_v2_frame, consumed_v2) = match
    decode_frame(v2_wire, lookup_message_crc_extra) {
    Ok(res) => res
    Err(e) => fail("v2 decode failed: \{e.to_repr()}")
  }
  assert_eq(consumed_v2, v2_wire.length())
  assert_eq(decoded_v2_frame, v2_frame)
  assert_eq(MavMessage::decode_from_frame(decoded_v2_frame), Ok(msg))

  // Full MAVLink v1 frame roundtrip
  let (v1_wire, _) = match
    msg.encode_to_frame(seq=b'\x08', sysid=b'\x01', compid=b'\x01', version=V1) {
    Ok(res) => res
    Err(e) => fail("v1 encode failed: \{e.to_repr()}")
  }
  assert_eq(v1_wire[0], MAVLINK_STX_V1)
  assert_eq(v1_wire.length(), 1 + V1_HEADER_LEN + 9 + 2)
  let (decoded_v1_frame, consumed_v1) = match
    decode_frame(v1_wire, lookup_message_crc_extra) {
    Ok(res) => res
    Err(e) => fail("v1 decode failed: \{e.to_repr()}")
  }
  assert_eq(consumed_v1, v1_wire.length())
  assert_eq(MavMessage::decode_from_frame(decoded_v1_frame), Ok(msg))
}

///|
test "mavlink v2 trailing zero truncation and all-zero minimum 1-byte rule" {
  // COMMAND_LONG with only param1 = 1.0 and command = 400 (ARM), all trailing bytes 0
  let arm_cmd : CommandLong = {
    target_system: b'\x01',
    target_component: b'\x01',
    command: MavCmd::ComponentArmDisarm.to_uint(),
    confirmation: b'\x00',
    param1: (1.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    param5: (0.0 : Float),
    param6: (0.0 : Float),
    param7: (0.0 : Float),
  }
  let v1_payload = arm_cmd.encode_payload(v2=false)
  let v2_payload = arm_cmd.encode_payload(v2=true)
  assert_eq(v1_payload.length(), 33)
  // In v2, confirmation (last byte at offset 32) is 0x00, so it is truncated to 32 bytes
  assert_eq(v2_payload.length(), 32)
  assert_eq(CommandLong::decode_payload(v2_payload, v2=true), Ok(arm_cmd))

  // Now test a message where all fields are zero: v2 payload must retain exactly 1 byte
  let zero_ping : Ping = {
    time_usec: 0UL,
    seq: 0U,
    target_system: b'\x00',
    target_component: b'\x00',
  }
  let zero_v2 = zero_ping.encode_payload(v2=true)
  assert_eq(zero_v2.length(), 1)
  assert_eq(zero_v2[0], b'\x00')
  assert_eq(Ping::decode_payload(zero_v2, v2=true), Ok(zero_ping))
}

///|
test "mavlink v2 extension fields in GPS_RAW_INT, COMMAND_ACK, and STATUSTEXT" {
  let gps : GpsRawInt = {
    time_usec: 1730000000000000UL,
    fix_type: GpsFixType::RtkFixed.to_uint().to_byte(),
    lat: 225430960,
    lon: 1140578650,
    alt: 58400,
    eph: 120U,
    epv: 150U,
    vel: 520U,
    cog: 9000U,
    satellites_visible: (18).to_byte(),
    alt_ellipsoid: 61200,
    h_acc: 15U,
    v_acc: 22U,
    vel_acc: 10U,
    hdg_acc: 50U,
    yaw: 9000U,
  }
  assert_eq(GpsRawInt::base_payload_len(), 30)
  assert_eq(GpsRawInt::max_payload_len(), 52)

  // v2 preserves extension fields
  let v2_bytes = gps.encode_payload(v2=true)
  assert_eq(GpsRawInt::decode_payload(v2_bytes, v2=true), Ok(gps))

  // v1 drops extension fields (30 bytes), and v2 decoder zero-extends them cleanly
  let v1_bytes = gps.encode_payload(v2=false)
  assert_eq(v1_bytes.length(), 30)
  let decoded_from_v1 = match GpsRawInt::decode_payload(v1_bytes, v2=true) {
    Ok(m) => m
    Err(e) => fail("decode failed: \{e.to_repr()}")
  }
  assert_eq(decoded_from_v1.lat, gps.lat)
  assert_eq(decoded_from_v1.lon, gps.lon)
  assert_eq(decoded_from_v1.alt_ellipsoid, 0)
  assert_eq(decoded_from_v1.yaw, 0U)

  // STATUSTEXT char[50] + v2 extension fields
  let status : Statustext = {
    severity: MavSeverity::Info.to_uint().to_byte(),
    text: "PX4: Armed and ready for autonomous mission",
    id: 42U,
    chunk_seq: b'\x01',
  }
  let (st_wire, _) = match
    MsgStatustext(status).encode_to_frame(
      seq=b'\x12',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail("statustext encode failed: \{e.to_repr()}")
  }
  let (st_frame, _) = match decode_frame(st_wire, lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail("statustext decode failed: \{e.to_repr()}")
  }
  assert_eq(MavMessage::decode_from_frame(st_frame), Ok(MsgStatustext(status)))
}

///|
test "sha256 digest and mavlink v2 packet signing with replay protection" {
  // FIPS 180-4 test vector: SHA-256("abc")
  let digest = sha256_digest(b"abc")
  assert_eq(digest[0], b'\xba')
  assert_eq(digest[1], b'\x78')
  assert_eq(digest[2], b'\x16')
  assert_eq(digest[3], b'\xbf')
  assert_eq(digest[31], b'\xad')

  let secret_key = b"0123456789abcdef0123456789abcdef"
  let tx_signer = match
    SigningContext::new(secret_key, link_id=b'\x02', initial_timestamp=1000UL) {
    Ok(c) => c
    Err(e) => fail("tx_signer init failed: \{e.to_repr()}")
  }
  let rx_verifier = match
    SigningContext::new(secret_key, link_id=b'\x02', initial_timestamp=1000UL) {
    Ok(c) => c
    Err(e) => fail("rx_verifier init failed: \{e.to_repr()}")
  }

  let ack : CommandAck = {
    command: MavCmd::NavTakeoff.to_uint(),
    result: MavResult::Accepted.to_uint().to_byte(),
    progress: (100).to_byte(),
    result_param2: 0,
    target_system: b'\xFF',
    target_component: b'\xBE',
  }
  let (signed_wire, signed_frame) = match
    MsgCommandAck(ack).encode_to_frame(
      seq=b'\x01',
      sysid=b'\x01',
      compid=b'\x01',
      signing=Some(tx_signer),
    ) {
    Ok(r) => r
    Err(e) => fail("signed encode failed: \{e.to_repr()}")
  }
  assert_eq(signed_frame.header.incompat_flags, IFLAG_SIGNED)
  assert_true(signed_frame.signature is Some(_))

  // Verify authentic signed packet succeeds
  let (verified_frame, _) = match
    decode_frame(
      signed_wire,
      lookup_message_crc_extra,
      signing=Some(rx_verifier),
    ) {
    Ok(r) => r
    Err(e) => fail("signed decode failed: \{e.to_repr()}")
  }
  assert_eq(
    MavMessage::decode_from_frame(verified_frame),
    Ok(MsgCommandAck(ack)),
  )

  // Replaying the exact same frame must be rejected by monotonic timestamp protection
  let replay_res = decode_frame(
    signed_wire,
    lookup_message_crc_extra,
    signing=Some(rx_verifier),
  )
  assert_true(replay_res is Err(SignatureInvalid(_)))

  // Unsigned frame when signing is required must return SignatureMissing
  let (unsigned_wire, _) = match
    MsgCommandAck(ack).encode_to_frame(
      seq=b'\x02',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail("unsigned encode failed: \{e.to_repr()}")
  }
  let unsigned_res = decode_frame(
    unsigned_wire,
    lookup_message_crc_extra,
    signing=Some(rx_verifier),
  )
  assert_eq(unsigned_res, Err(SignatureMissing))
}

///|
test "streaming FrameParser handles noise, chunk fragmentation, and sequence drops" {
  let hb : Heartbeat = {
    mav_type: b'\x02',
    autopilot: b'\x0C',
    base_mode: b'\x81',
    custom_mode: 0U,
    system_status: b'\x04',
    mavlink_version: b'\x03',
  }
  // Frame 1: seq = 10
  let (f1_bytes, _) = match
    MsgHeartbeat(hb).encode_to_frame(
      seq=(10).to_byte(),
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  // Frame 2: seq = 13 (simulating 2 dropped frames: seq 11 and 12)
  let (f2_bytes, _) = match
    MsgHeartbeat(hb).encode_to_frame(
      seq=(13).to_byte(),
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }

  // Construct stream: 3 noise bytes + f1_bytes + 1 corrupted frame + f2_bytes
  let stream_buf : Array[Byte] = [b'\x00', b'\xAA', b'\x55']
  for i = 0; i < f1_bytes.length(); i = i + 1 {
    stream_buf.push(f1_bytes[i])
  }
  // Corrupted frame (flip last CRC byte of f1_bytes)
  for i = 0; i < f1_bytes.length() - 1; i = i + 1 {
    stream_buf.push(f1_bytes[i])
  }
  stream_buf.push((f1_bytes[f1_bytes.length() - 1].to_uint() ^ 0xFFU).to_byte())
  // Valid f2_bytes
  for i = 0; i < f2_bytes.length(); i = i + 1 {
    stream_buf.push(f2_bytes[i])
  }

  let parser = FrameParser::new()
  let decoded_frames : Array[MavFrame] = []
  let crc_errs : Array[MavError] = []

  // Feed in small 5-byte chunks to exercise partial frame reassembly
  let mut idx = 0
  while idx < stream_buf.length() {
    let chunk_arr : Array[Byte] = []
    for j = 0; j < 5 && idx + j < stream_buf.length(); j = j + 1 {
      chunk_arr.push(stream_buf[idx + j])
    }
    idx = idx + chunk_arr.length()
    let events = parser.push_bytes(
      Bytes::from_array(chunk_arr),
      lookup_message_crc_extra,
    )
    for ev in events {
      match ev {
        FrameDecoded(f) => decoded_frames.push(f)
        FrameError(CrcMismatch(exp, act)) =>
          crc_errs.push(CrcMismatch(exp, act))
        FrameError(_) => ()
      }
    }
  }

  assert_eq(decoded_frames.length(), 2)
  assert_eq(crc_errs.length(), 1)
  assert_eq(parser.packets_received, 2U)
  assert_eq(parser.packets_dropped, 2U)
  assert_eq(parser.crc_errors, 1U)
  assert_true(parser.noise_bytes_skipped >= 3U)
}

///|
test "24-bit v2 message id and custom xml schema code generation with numeric arrays" {
  // LOGGING_ACK has msgid = 268 (> 255), valid in v2 but rejected in v1
  let log_ack : LoggingAck = {
    target_system: b'\x01',
    target_component: b'\x01',
    sequence: 512U,
  }
  let v1_attempt = MsgLoggingAck(log_ack).encode_to_frame(
    seq=b'\x01',
    sysid=b'\x01',
    compid=b'\x01',
    version=V1,
  )
  assert_eq(v1_attempt, Err(UnsupportedV1MessageId(268U)))

  let (v2_wire, _) = match
    MsgLoggingAck(log_ack).encode_to_frame(
      seq=b'\x01',
      sysid=b'\x01',
      compid=b'\x01',
      version=V2,
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (decoded_f, _) = match decode_frame(v2_wire, lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    MavMessage::decode_from_frame(decoded_f),
    Ok(MsgLoggingAck(log_ack)),
  )

  // Parse a custom XML dialect containing fixed numeric arrays (uint16_t[4]) and hex enum values
  let custom_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <version>3</version>
    #|  <dialect>2</dialect>
    #|  <enums>
    #|    <enum name="MOTOR_STATE">
    #|      <entry value="0x00" name="MOTOR_STATE_IDLE"/>
    #|      <entry value="0x01" name="MOTOR_STATE_SPINNING"/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id="1200" name="ESC_TELEMETRY_QUAD">
    #|      <description>Quadrotor ESC telemetry with array fields</description>
    #|      <field type="uint8_t" name="state" enum="MOTOR_STATE">Motor state</field>
    #|      <field type="uint16_t[4]" name="rpm">RPM of 4 motors</field>
    #|      <field type="uint32_t" name="timestamp_ms">Boot timestamp</field>
    #|      <extensions/>
    #|      <field type="int8_t" name="max_temp_c">Peak ESC temperature</field>
    #|    </message>
    #|  </messages>
    #|</mavlink>

  let (schema, generated_src) = match generate_moonbit_from_xml(custom_xml) {
    Ok(res) => res
    Err(e) => fail("custom xml codegen failed: \{e.to_repr()}")
  }
  assert_eq(schema.messages.length(), 1)
  let esc_msg = schema.messages[0]
  assert_eq(esc_msg.id, 1200U)
  // Wire ordering: timestamp_ms (uint32_t, 4B) at offset 0, rpm (uint16_t[4], 8B) at offset 4,
  // state (uint8_t, 1B) at offset 12, extension max_temp_c (int8_t, 1B) at offset 13
  assert_eq(esc_msg.wire_ordered_fields[0].name, "timestamp_ms")
  assert_eq(esc_msg.wire_ordered_fields[0].wire_offset, 0)
  assert_eq(esc_msg.wire_ordered_fields[1].name, "rpm")
  assert_eq(esc_msg.wire_ordered_fields[1].wire_offset, 4)
  assert_eq(esc_msg.wire_ordered_fields[2].name, "state")
  assert_eq(esc_msg.wire_ordered_fields[2].wire_offset, 12)
  assert_eq(esc_msg.wire_ordered_fields[3].name, "max_temp_c")
  assert_eq(esc_msg.wire_ordered_fields[3].wire_offset, 13)
  assert_eq(esc_msg.base_payload_len, 13)
  assert_eq(esc_msg.max_payload_len, 14)
  assert_true(generated_src.contains("pub(all) struct EscTelemetryQuad"))
}
