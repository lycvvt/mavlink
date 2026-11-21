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
test "blackbox: self-hosting verification of official_standard_xml (22 enums, 60 messages)" {
  let (schema, code) = match
    @mavlink.generate_moonbit_from_xml(@mavlink.official_standard_xml) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.version, 3)
  assert_eq(schema.enums.length(), 22)
  assert_eq(schema.messages.length(), 60)
  assert_true(code.contains("pub(all) struct Heartbeat"))
  assert_true(code.contains("pub(all) struct MissionItemInt"))
  assert_true(code.contains("pub(all) struct BatteryStatus"))
  assert_true(code.contains("pub(all) struct AutopilotVersion"))
  assert_true(code.contains("pub(all) struct FileTransferProtocol"))
  assert_true(code.contains("pub(all) struct ParamExtValue"))
  assert_true(code.contains("pub(all) struct LoggingAck"))
  assert_true(code.contains("pub(all) enum MavCoordFrame"))
  assert_true(code.contains("pub(all) enum MavParamType"))
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

///|
test "blackbox: all 18 standard MAVLink enums roundtrip via to_uint and from_uint" {
  assert_eq(
    @mavlink.MavComponent::from_uint(
      @mavlink.MavComponent::MavCompIdAutopilot1.to_uint(),
    ),
    Some(@mavlink.MavComponent::MavCompIdAutopilot1),
  )
  assert_eq(
    @mavlink.MavParamType::from_uint(@mavlink.MavParamType::Real32.to_uint()),
    Some(@mavlink.MavParamType::Real32),
  )
  assert_eq(
    @mavlink.MavDataStream::from_uint(
      @mavlink.MavDataStream::Position.to_uint(),
    ),
    Some(@mavlink.MavDataStream::Position),
  )
  assert_eq(
    @mavlink.MavDistanceSensor::from_uint(
      @mavlink.MavDistanceSensor::Laser.to_uint(),
    ),
    Some(@mavlink.MavDistanceSensor::Laser),
  )
  assert_eq(
    @mavlink.MavSensorOrientation::from_uint(
      @mavlink.MavSensorOrientation::MavSensorRotationPitch270.to_uint(),
    ),
    Some(@mavlink.MavSensorOrientation::MavSensorRotationPitch270),
  )
  assert_eq(
    @mavlink.MavLandedState::from_uint(@mavlink.MavLandedState::InAir.to_uint()),
    Some(@mavlink.MavLandedState::InAir),
  )
  assert_eq(
    @mavlink.MavVtolState::from_uint(@mavlink.MavVtolState::Mc.to_uint()),
    Some(@mavlink.MavVtolState::Mc),
  )
  assert_eq(
    @mavlink.MavSeverity::from_uint(@mavlink.MavSeverity::Info.to_uint()),
    Some(@mavlink.MavSeverity::Info),
  )
  assert_eq(
    @mavlink.GpsFixType::from_uint(@mavlink.GpsFixType::RtkFixed.to_uint()),
    Some(@mavlink.GpsFixType::RtkFixed),
  )
  assert_eq(
    @mavlink.MavMissionType::from_uint(@mavlink.MavMissionType::Fence.to_uint()),
    Some(@mavlink.MavMissionType::Fence),
  )
}

///|
test "blackbox: MavMessage metadata dispatch (msg_id, msg_name, crc_extra, base_payload_len, max_payload_len)" {
  let gps_msg = @mavlink.MavMessage::MsgGpsRawInt({
    time_usec: 1000UL,
    lat: 225430960,
    lon: 1140578650,
    alt: 10000,
    eph: 50U,
    epv: 80U,
    vel: 100U,
    cog: 9000U,
    fix_type: b'\x03',
    satellites_visible: b'\x0c',
    alt_ellipsoid: 9500,
    h_acc: 10U,
    v_acc: 15U,
    vel_acc: 5U,
    hdg_acc: 100U,
    yaw: 9000U,
  })
  assert_eq(gps_msg.msg_id(), 24U)
  assert_eq(gps_msg.msg_name(), "GPS_RAW_INT")
  assert_eq(gps_msg.crc_extra(), b'\x18')
  assert_eq(gps_msg.base_payload_len(), 30)
  assert_eq(gps_msg.max_payload_len(), 52)
}

///|
test "blackbox: generate_moonbit_from_xml_with_includes resolves builtin_xml_resolver" {
  let custom_dialect =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <version>3</version>
    #|  <dialect>9</dialect>
    #|  <include>minimal.xml</include>
    #|  <messages>
    #|    <message id="42000" name="PAYLOAD_WINCH_STATUS">
    #|      <field type="uint32_t" name="time_boot_ms"/>
    #|      <field type="float" name="line_length_m"/>
    #|      <field type="int16_t" name="tension_g"/>
    #|      <field type="uint8_t" name="status_flags"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  let (schema, code) = match
    @mavlink.generate_moonbit_from_xml_with_includes("winch.xml", fn(name) {
      if name == "winch.xml" {
        Some(custom_dialect)
      } else {
        @mavlink.builtin_xml_resolver(name)
      }
    }) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.messages.length(), 2)
  assert_true(code.contains("pub(all) struct Heartbeat"))
  assert_true(code.contains("pub(all) struct PayloadWinchStatus"))
}

///|
test "blackbox: MAVLink v1 vs v2 wire encoding and extension truncation boundary" {
  let gps : @mavlink.GpsRawInt = {
    time_usec: 1730800000000000UL,
    lat: 225430960,
    lon: 1140578650,
    alt: 50000,
    eph: 70U,
    epv: 90U,
    vel: 200U,
    cog: 18000U,
    fix_type: b'\x06',
    satellites_visible: b'\x12',
    alt_ellipsoid: 48500,
    h_acc: 15U,
    v_acc: 22U,
    vel_acc: 8U,
    hdg_acc: 50U,
    yaw: 18000U,
  }
  // v1 encoding strips extension fields (30-byte base payload + 8-byte v1 overhead = 38 bytes)
  let (v1_wire, v1_frame) = match
    @mavlink.MavMessage::MsgGpsRawInt(gps).encode_to_frame(
      seq=b'\x05',
      sysid=b'\x01',
      compid=b'\x01',
      version=@mavlink.ProtocolVersion::V1,
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(v1_wire.length(), 38)
  assert_eq(v1_frame.payload.length(), 30)

  // v1 decoding zero-extends extension fields
  let (decoded_v1_frame, _) = match
    @mavlink.decode_frame(v1_wire, @mavlink.lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  match @mavlink.MavMessage::decode_from_frame(decoded_v1_frame) {
    Ok(@mavlink.MavMessage::MsgGpsRawInt(g)) => {
      assert_eq(g.lat, 225430960)
      assert_eq(g.h_acc, 0U)
      assert_eq(g.yaw, 0U)
    }
    _ => fail("Expected MsgGpsRawInt")
  }
}

///|
test "blackbox: end-to-end ParameterServer and ParameterClient over encoded MAVLink v2 wire frames" {
  let srv = @mavlink.ParameterServer::new(b'\x01', b'\x01', [
    ("COM_DISARM_LAND", (2.0 : Float), b'\x09'),
  ])
  let cli = @mavlink.ParameterClient::new(b'\x01', b'\x01')
  let req_msg = cli.start_list_sync(100UL)
  let (req_wire, _) = match
    req_msg.encode_to_frame(seq=b'\x01', sysid=b'\xff', compid=b'\xbe') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (rx_frame, _) = match
    @mavlink.decode_frame(req_wire, @mavlink.lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let decoded_req = match @mavlink.MavMessage::decode_from_frame(rx_frame) {
    Ok(m) => m
    Err(e) => fail(e.to_repr().to_string())
  }
  let srv_out = srv.handle_message(decoded_req)
  assert_eq(srv_out.length(), 1)
  match srv_out[0] {
    @mavlink.MavMessage::MsgParamValue(pv) => cli.on_param_value(pv, 120UL)
    _ => fail("Expected MsgParamValue")
  }
  assert_eq(cli.state, @mavlink.ParamSyncState::Synced)
}

///|
test "blackbox: public benchmark evaluators return deterministic metrics" {
  let v1v2 = @mavlink.evaluate_v1_vs_v2_efficiency()
  assert_eq(v1v2.total_frames, 100)
  assert_true(v1v2.v2_total_wire_bytes < v1v2.v1_total_wire_bytes)

  let sec = @mavlink.evaluate_signing_security_audit()
  assert_eq(sec.valid_signed_accepted, 100)
  assert_eq(sec.attack_frames_rejected, 50)
}

///|
test "blackbox: official_60_golden_table matches all 60 built-in message CRC_EXTRA lookups" {
  let golden60 = @mavlink.official_60_golden_table()
  assert_eq(golden60.length(), 60)
  for entry in golden60 {
    assert_eq(
      @mavlink.lookup_message_crc_extra(entry.msg_id),
      Some(entry.expected_crc_extra),
    )
    assert_eq(@mavlink.lookup_message_name(entry.msg_id), Some(entry.name))
  }
}

///|
test "blackbox: FtpPacket directory listing and read acknowledgement roundtrip" {
  let list_pkt : @mavlink.FtpPacket = {
    seq_number: 100U,
    session: b'\x00',
    opcode: @mavlink.FtpOpcode::ListDirectory,
    req_opcode: @mavlink.FtpOpcode::FtpNone,
    burst_complete: false,
    offset: 0U,
    data: b"/fs/microsd",
  }
  let msg = match list_pkt.to_mav_message() {
    Ok(m) => m
    Err(e) => fail(e.to_repr().to_string())
  }
  match msg {
    @mavlink.MavMessage::MsgFileTransferProtocol(ftp) =>
      assert_eq(
        @mavlink.FtpPacket::from_file_transfer_protocol(ftp),
        Ok(list_pkt),
      )
    _ => fail("Expected MsgFileTransferProtocol")
  }
}

///|
test "blackbox: TelemetryRateTracker multi-stream rate and bandwidth audit" {
  let tracker = @mavlink.TelemetryRateTracker::new()
  let hb = @mavlink.MavMessage::MsgHeartbeat({
    custom_mode: 0U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\xd1',
    system_status: b'\x04',
    mavlink_version: b'\x03',
  })
  let (w, f) = match
    hb.encode_to_frame(seq=b'\x00', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  tracker.record_frame(f, w.length())
  assert_eq(tracker.total_frames, 1)
  assert_eq(tracker.message_rate_hz(0U, 1000UL), 1.0)
}

///|
test "blackbox: extract_message_target identifies unicast vs broadcast MAVLink messages" {
  let hb = @mavlink.MavMessage::MsgHeartbeat({
    custom_mode: 0U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\xd1',
    system_status: b'\x04',
    mavlink_version: b'\x03',
  })
  assert_eq(@mavlink.extract_message_target(hb), None)

  let cmd = @mavlink.MavMessage::MsgCommandCancel({
    command: 400U,
    target_system: b'\x01',
    target_component: b'\x9a',
  })
  assert_eq(@mavlink.extract_message_target(cmd), Some((b'\x01', b'\x9a')))
}

///|
test "blackbox: QGroundControl .tlog recording and replay with SHA-256 signed frames" {
  let key = b"0123456789abcdef0123456789abcdef"
  let tx_sign = match
    @mavlink.SigningContext::new(
      key,
      link_id=b'\x01',
      initial_timestamp=10_000UL,
    ) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  let rx_sign = match
    @mavlink.SigningContext::new(
      key,
      link_id=b'\x01',
      initial_timestamp=10_000UL,
    ) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  let rec = @mavlink.TlogRecorder::new()
  let _ = rec.record_message(
    1730800000100000UL,
    @mavlink.MavMessage::MsgExtendedSysState({
      vtol_state: b'\x03',
      landed_state: b'\x02',
    }),
    seq=b'\x01',
    sysid=b'\x01',
    compid=b'\x01',
    signing=Some(tx_sign),
  )
  let decoded = match
    @mavlink.decode_tlog_stream(
      rec.to_bytes(),
      @mavlink.lookup_message_crc_extra,
      signing=Some(rx_sign),
    ) {
    Ok(es) => es
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(decoded.length(), 1)
  assert_eq(decoded[0].timestamp_usec, 1730800000100000UL)
  assert_eq(decoded[0].frame.header.msgid, 245U)
}

///|
test "blackbox: FtpServer and ExtendedParameterServer end-to-end integration" {
  let ftp_srv = @mavlink.FtpServer::new([
    ("/etc/init.d/rcS", b"uorb start\npx4io start\n"),
  ])
  let open_reply = ftp_srv.handle_packet({
    seq_number: 10U,
    session: b'\x00',
    opcode: @mavlink.FtpOpcode::OpenFileRO,
    req_opcode: @mavlink.FtpOpcode::FtpNone,
    burst_complete: false,
    offset: 0U,
    data: b"/etc/init.d/rcS",
  })
  assert_eq(open_reply.opcode, @mavlink.FtpOpcode::Ack)

  let ext_srv = @mavlink.ExtendedParameterServer::new(b'\x01', b'\x64', [
    ("GIMBAL_FW_VER", "v2.4.1-release", b'\x0b'),
  ])
  let replies = ext_srv.handle_message(
    @mavlink.MavMessage::MsgParamExtRequestList({
      target_system: b'\x01',
      target_component: b'\x64',
    }),
  )
  assert_eq(replies.length(), 1)
}
