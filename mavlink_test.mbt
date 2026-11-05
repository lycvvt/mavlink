///|
test "blackbox: Attitude, LocalPositionNed, and GlobalPositionInt roundtrip" {
  let att : @mavlink.Attitude = {
    time_boot_ms: 45200U,
    roll: (0.05 : Float),
    pitch: (-0.02 : Float),
    yaw: (1.57 : Float),
    rollspeed: (0.001 : Float),
    pitchspeed: (0.0 : Float),
    yawspeed: (0.12 : Float),
  }
  let (att_wire, _) = match
    @mavlink.MavMessage::MsgAttitude(att).encode_to_frame(
      seq=b'\x20',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (att_frame, _) = match
    @mavlink.decode_frame(att_wire, @mavlink.lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    @mavlink.MavMessage::decode_from_frame(att_frame),
    Ok(@mavlink.MavMessage::MsgAttitude(att)),
  )

  let ned : @mavlink.LocalPositionNed = {
    time_boot_ms: 45210U,
    x: (10.5 : Float),
    y: (-4.2 : Float),
    z: (-15.0 : Float),
    vx: (1.0 : Float),
    vy: (0.0 : Float),
    vz: (-0.5 : Float),
  }
  assert_eq(
    @mavlink.LocalPositionNed::decode_payload(ned.encode_payload(), v2=true),
    Ok(ned),
  )

  let pos : @mavlink.GlobalPositionInt = {
    time_boot_ms: 45250U,
    lat: 225430960,
    lon: 1140578650,
    alt: 100500,
    relative_alt: 50000,
    vx: 320,
    vy: -40,
    vz: -15,
    hdg: 9000U,
  }
  assert_eq(
    @mavlink.GlobalPositionInt::decode_payload(pos.encode_payload(), v2=true),
    Ok(pos),
  )
}

///|
test "blackbox: enum roundtrip for MavAutopilot, MavType, MavState, MavCmd, MavResult, MavCoordFrame" {
  assert_eq(
    @mavlink.MavAutopilot::from_uint(@mavlink.MavAutopilot::Px4.to_uint()),
    Some(@mavlink.MavAutopilot::Px4),
  )
  assert_eq(@mavlink.MavAutopilot::from_uint(999U), None)
  assert_eq(
    @mavlink.MavType::from_uint(@mavlink.MavType::Quadrotor.to_uint()),
    Some(@mavlink.MavType::Quadrotor),
  )
  assert_eq(
    @mavlink.MavState::from_uint(@mavlink.MavState::Active.to_uint()),
    Some(@mavlink.MavState::Active),
  )
  assert_eq(
    @mavlink.MavCmd::from_uint(@mavlink.MavCmd::ComponentArmDisarm.to_uint()),
    Some(@mavlink.MavCmd::ComponentArmDisarm),
  )
  assert_eq(
    @mavlink.MavResult::from_uint(@mavlink.MavResult::Accepted.to_uint()),
    Some(@mavlink.MavResult::Accepted),
  )
  assert_eq(
    @mavlink.MavCoordFrame::from_uint(
      @mavlink.MavCoordFrame::GlobalRelativeAltInt.to_uint(),
    ),
    Some(@mavlink.MavCoordFrame::GlobalRelativeAltInt),
  )
}

///|
test "blackbox: self-hosting verification of official_standard_xml (11 enums, 20 messages)" {
  let (schema, code) = match
    @mavlink.generate_moonbit_from_xml(@mavlink.official_standard_xml) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.version, 3)
  assert_eq(schema.enums.length(), 11)
  assert_eq(schema.messages.length(), 20)
  assert_true(code.contains("pub(all) struct Heartbeat"))
  assert_true(code.contains("pub(all) struct MissionItemInt"))
  assert_true(code.contains("pub(all) struct LoggingAck"))
  assert_true(code.contains("pub(all) enum MavCoordFrame"))
}

///|
test "blackbox: SystemTime, ParamValue, ParamSet, RcChannelsRaw, and LoggingAck roundtrip" {
  let st : @mavlink.SystemTime = {
    time_unix_usec: 1730800000000000UL,
    time_boot_ms: 125000U,
  }
  assert_eq(
    @mavlink.SystemTime::decode_payload(st.encode_payload(), v2=true),
    Ok(st),
  )

  let pv : @mavlink.ParamValue = {
    param_value: (9.80665 : Float),
    param_count: 320U,
    param_index: 42U,
    param_id: "MPC_THR_HOVER",
    param_type: b'\x09',
  }
  assert_eq(
    @mavlink.ParamValue::decode_payload(pv.encode_payload(), v2=true),
    Ok(pv),
  )

  let ps : @mavlink.ParamSet = {
    param_value: (0.55 : Float),
    target_system: b'\x01',
    target_component: b'\x01',
    param_id: "MPC_THR_HOVER",
    param_type: b'\x09',
  }
  assert_eq(
    @mavlink.ParamSet::decode_payload(ps.encode_payload(), v2=true),
    Ok(ps),
  )

  let rc : @mavlink.RcChannelsRaw = {
    time_boot_ms: 125100U,
    chan1_raw: 1500U,
    chan2_raw: 1500U,
    chan3_raw: 1000U,
    chan4_raw: 1500U,
    chan5_raw: 1900U,
    chan6_raw: 1100U,
    chan7_raw: 1500U,
    chan8_raw: 1500U,
    port: b'\x00',
    rssi: b'\xfe',
  }
  assert_eq(
    @mavlink.RcChannelsRaw::decode_payload(rc.encode_payload(), v2=true),
    Ok(rc),
  )

  let ack : @mavlink.LoggingAck = {
    sequence: 17U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  let (wire, _) = match
    @mavlink.MavMessage::MsgLoggingAck(ack).encode_to_frame(
      seq=b'\x09',
      sysid=b'\xff',
      compid=b'\xbe',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (frame, _) = match
    @mavlink.decode_frame(wire, @mavlink.lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    @mavlink.MavMessage::decode_from_frame(frame),
    Ok(@mavlink.MavMessage::MsgLoggingAck(ack)),
  )
}

///|
test "blackbox: custom dialect with uint16_t[4] array, comments, entities, and reserved keyword sanitization" {
  let custom_xml =
    #|<?xml version="1.0"?>
    #|<!-- Custom quadrotor ESC dialect -->
    #|<mavlink>
    #|  <version>3</version>
    #|  <dialect>2</dialect>
    #|  <include>minimal.xml</include>
    #|  <enums>
    #|    <enum name="MOTOR_STATE">
    #|      <entry value="0x00" name="MOTOR_STATE_IDLE"/>
    #|      <entry value="0x01" name="MOTOR_STATE_SPINNING"/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id="1200" name="ESC_TELEMETRY_QUAD">
    #|      <description>Quadrotor ESC telemetry &amp; thermal status</description>
    #|      <field type="uint8_t" name="type" enum="MOTOR_STATE">Motor state</field>
    #|      <field type="uint16_t[4]" name="rpm">RPM of 4 motors</field>
    #|      <field type="uint32_t" name="timestamp_ms">Boot timestamp</field>
    #|      <extensions/>
    #|      <field type="int8_t" name="max_temp_c">Peak ESC temperature</field>
    #|    </message>
    #|  </messages>
    #|</mavlink>

  let (schema, generated_src) = match
    @mavlink.generate_moonbit_from_xml(custom_xml) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.includes, ["minimal.xml"])
  let esc_msg = schema.messages[0]
  assert_eq(esc_msg.id, 1200U)
  assert_eq(esc_msg.description, "Quadrotor ESC telemetry & thermal status")
  assert_eq(esc_msg.wire_ordered_fields[0].name, "timestamp_ms")
  assert_eq(esc_msg.wire_ordered_fields[0].wire_offset, 0)
  assert_eq(esc_msg.wire_ordered_fields[1].name, "rpm")
  assert_eq(esc_msg.wire_ordered_fields[1].wire_offset, 4)
  assert_eq(esc_msg.wire_ordered_fields[2].name, "type")
  assert_eq(esc_msg.wire_ordered_fields[2].wire_offset, 12)
  assert_eq(esc_msg.wire_ordered_fields[3].name, "max_temp_c")
  assert_eq(esc_msg.wire_ordered_fields[3].wire_offset, 13)
  assert_eq(esc_msg.base_payload_len, 13)
  assert_eq(esc_msg.max_payload_len, 14)
  assert_true(generated_src.contains("mav_type : Byte"))
}

///|
test "blackbox: rejection of duplicate message IDs, >255B payload, unknown field types, and malformed XML tags" {
  let dup_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="10" name="MSG_A"><field type="uint8_t" name="a"/></message>
    #|    <message id="10" name="MSG_B"><field type="uint8_t" name="b"/></message>
    #|  </messages>
    #|</mavlink>
  assert_true(
    @mavlink.parse_dialect_xml(dup_xml)
    is Err(@mavlink.MavError::SchemaError(_)),
  )

  let bad_type_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="11" name="MSG_BAD"><field type="uint128_t" name="x"/></message>
    #|  </messages>
    #|</mavlink>
  assert_true(
    @mavlink.parse_dialect_xml(bad_type_xml)
    is Err(@mavlink.MavError::SchemaError(_)),
  )

  let over_len_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="12" name="MSG_HUGE">
    #|      <field type="uint64_t[32]" name="part1"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  assert_true(
    @mavlink.parse_dialect_xml(over_len_xml)
    is Err(@mavlink.MavError::SchemaError(_)),
  )

  let malformed_xml = "<mavlink><messages></mavlink>"
  assert_true(
    @mavlink.parse_dialect_xml(malformed_xml)
    is Err(@mavlink.MavError::XmlParseError(_)),
  )
}
