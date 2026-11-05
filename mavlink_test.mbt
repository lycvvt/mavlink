///|
test "blackbox public api: attitude, global_position_int, and parameter protocol roundtrip" {
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
  let pos_payload = pos.encode_payload(v2=true)
  assert_eq(
    @mavlink.GlobalPositionInt::decode_payload(pos_payload, v2=true),
    Ok(pos),
  )

  let param_val : @mavlink.ParamValue = {
    param_id: "MPC_XY_VEL_MAX",
    param_value: (12.0 : Float),
    param_type: b'\x09',
    param_count: 148U,
    param_index: 17U,
  }
  let pv_payload = param_val.encode_payload(v2=true)
  assert_eq(
    @mavlink.ParamValue::decode_payload(pv_payload, v2=true),
    Ok(param_val),
  )
}

///|
test "blackbox xml schema validation and error handling" {
  // Duplicate message ID should fail with SchemaError
  let dup_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="10" name="MSG_A"><field type="uint8_t" name="a"/></message>
    #|    <message id="10" name="MSG_B"><field type="uint8_t" name="b"/></message>
    #|  </messages>
    #|</mavlink>
  let dup_res = @mavlink.parse_dialect_xml(dup_xml)
  assert_true(dup_res is Err(@mavlink.MavError::SchemaError(_)))

  // Unknown field type should fail with SchemaError
  let bad_type_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="11" name="MSG_BAD"><field type="uint128_t" name="x"/></message>
    #|  </messages>
    #|</mavlink>
  let bad_type_res = @mavlink.parse_dialect_xml(bad_type_xml)
  assert_true(bad_type_res is Err(@mavlink.MavError::SchemaError(_)))

  // Mismatched XML closing tag should fail with XmlParseError
  let malformed_xml = "<mavlink><messages></mavlink>"
  let malformed_res = @mavlink.parse_dialect_xml(malformed_xml)
  assert_true(malformed_res is Err(@mavlink.MavError::XmlParseError(_)))
}
