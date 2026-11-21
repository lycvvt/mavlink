///|
test "crc16: ITU-T X.25 standard ASCII check vector 123456789" {
  let check_bytes = b"123456789"
  assert_eq(crc16_calculate(check_bytes), 0x6F91U)
}

///|
test "crc16: incremental byte vs slice vs ascii accumulation equivalence" {
  let c1 = X25Crc::new()
  c1.accumulate_ascii("HEARTBEAT ")
  let c2 = X25Crc::new()
  c2.accumulate_bytes(b"xxHEARTBEAT yy", start=2, len=10)
  assert_eq(c1.value, c2.value)
  assert_eq(c1.low_byte(), c2.low_byte())
  assert_eq(c1.high_byte(), c2.high_byte())
  c1.reset()
  assert_eq(c1.value, X25_INIT_CRC)
}

///|
test "crc_extra: minimal and core telemetry messages (HEARTBEAT, SYS_STATUS, SYSTEM_TIME, PING)" {
  assert_eq(Heartbeat::crc_extra(), (50).to_byte())
  assert_eq(SysStatus::crc_extra(), (124).to_byte())
  assert_eq(SystemTime::crc_extra(), (137).to_byte())
  assert_eq(Ping::crc_extra(), (237).to_byte())
}

///|
test "crc_extra: parameter and navigation messages" {
  assert_eq(ParamRequestRead::crc_extra(), (214).to_byte())
  assert_eq(ParamValue::crc_extra(), (220).to_byte())
  assert_eq(ParamSet::crc_extra(), (168).to_byte())
  assert_eq(Attitude::crc_extra(), (39).to_byte())
  assert_eq(LocalPositionNed::crc_extra(), (185).to_byte())
  assert_eq(GlobalPositionInt::crc_extra(), (104).to_byte())
  assert_eq(RcChannelsRaw::crc_extra(), (244).to_byte())
}

///|
test "crc_extra: mission and command messages with v2 extensions excluded from seed" {
  assert_eq(MissionCount::crc_extra(), (221).to_byte())
  assert_eq(MissionAck::crc_extra(), (153).to_byte())
  assert_eq(MissionRequestInt::crc_extra(), (196).to_byte())
  assert_eq(MissionItemInt::crc_extra(), (38).to_byte())
  assert_eq(CommandLong::crc_extra(), (152).to_byte())
  assert_eq(CommandAck::crc_extra(), (143).to_byte())
}

///|
test "crc_extra: GPS_RAW_INT, STATUSTEXT, LOGGING_ACK and array length injection rule" {
  assert_eq(GpsRawInt::crc_extra(), (24).to_byte())
  assert_eq(Statustext::crc_extra(), (83).to_byte())
  assert_eq(LoggingAck::crc_extra(), (14).to_byte())
}

///|
test "payload: scalar unsigned integers (u8, u16, u24, u32, u64) little-endian boundary values" {
  let w = PayloadWriter::new()
  w.write_uint8(b'\xAB')
  w.write_uint16(0xBEEFU)
  w.write_uint24(0x123456U)
  w.write_uint32(0xDEADBEEFU)
  w.write_uint64(0x0102030405060708UL)
  let raw = w.to_bytes()
  assert_eq(raw.length(), 1 + 2 + 3 + 4 + 8)

  let r = PayloadReader::new(raw, zero_extend=false)
  assert_eq(r.read_uint8(), Ok(b'\xAB'))
  assert_eq(r.read_uint16(), Ok(0xBEEFU))
  assert_eq(r.read_uint8(), Ok(b'\x56'))
  assert_eq(r.read_uint8(), Ok(b'\x34'))
  assert_eq(r.read_uint8(), Ok(b'\x12'))
  assert_eq(r.read_uint32(), Ok(0xDEADBEEFU))
  assert_eq(r.read_uint64(), Ok(0x0102030405060708UL))
}

///|
test "payload: scalar signed integers (i8, i16, i32, i64) negative two's complement roundtrip" {
  let w = PayloadWriter::new()
  w.write_int8(-1)
  w.write_int8(-128)
  w.write_int16(-32768)
  w.write_int16(-42)
  w.write_int32(-2147483648)
  w.write_int64(-9000000000000L)
  let raw = w.to_bytes()

  let r = PayloadReader::new(raw, zero_extend=false)
  assert_eq(r.read_int8(), Ok(-1))
  assert_eq(r.read_int8(), Ok(-128))
  assert_eq(r.read_int16(), Ok(-32768))
  assert_eq(r.read_int16(), Ok(-42))
  assert_eq(r.read_int32(), Ok(-2147483648))
  assert_eq(r.read_int64(), Ok(-9000000000000L))
}

///|
test "payload: IEEE-754 float32 and float64 precision roundtrip" {
  let w = PayloadWriter::new()
  w.write_float((3.1415927 : Float))
  w.write_float((-0.0025 : Float))
  w.write_double(2.718281828459045)
  let r = PayloadReader::new(w.to_bytes(), zero_extend=false)
  assert_eq(r.read_float(), Ok((3.1415927 : Float)))
  assert_eq(r.read_float(), Ok((-0.0025 : Float)))
  assert_eq(r.read_double(), Ok(2.718281828459045))
}

///|
test "payload: fixed char[N] NUL padding, exact-length, and over-length truncation" {
  let w = PayloadWriter::new()
  w.write_char_array("SYS_ID", 16)
  w.write_char_array("0123456789ABCDEF_EXTRA", 16)
  let raw = w.to_bytes()
  assert_eq(raw.length(), 32)
  let r = PayloadReader::new(raw, zero_extend=false)
  assert_eq(r.read_char_array(16), Ok("SYS_ID"))
  assert_eq(r.read_char_array(16), Ok("0123456789ABCDEF"))
}

///|
test "payload: MAVLink v2 trailing zero-byte truncation strips trailing 0x00 bytes" {
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
  assert_eq(v2_payload.length(), 32)
  assert_eq(CommandLong::decode_payload(v2_payload, v2=true), Ok(arm_cmd))
}

///|
test "payload: MAVLink v2 all-zero payload retains mandatory 1st byte" {
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
test "payload: v1 strict reader rejects short buffer with PayloadTooShort while v2 zero-extends" {
  let short_buf = b"\x01\x02"
  assert_true(
    Ping::decode_payload(short_buf, v2=false) is Err(PayloadTooShort(_, _)),
  )
  assert_true(Ping::decode_payload(short_buf, v2=true) is Ok(_))
}

///|
test "frame: HEARTBEAT wire field reordering (custom_mode at offset 0) and v2 byte layout" {
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
  let payload = hb.encode_payload(v2=true)
  assert_eq(payload.length(), 9)
  assert_eq(payload[0], b'\x00')
  assert_eq(payload[1], b'\x00')
  assert_eq(payload[2], b'\x01')
  assert_eq(payload[3], b'\x04')
  assert_eq(payload[4], b'\x02')
  assert_eq(payload[5], b'\x0C')
  assert_eq(payload[6], (1 + 16 + 128).to_byte())
  assert_eq(payload[7], b'\x04')
  assert_eq(payload[8], b'\x03')

  let msg = MsgHeartbeat(hb)
  let (v2_wire, v2_frame) = match
    msg.encode_to_frame(seq=b'\x07', sysid=b'\x01', compid=b'\x01', version=V2) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(v2_wire[0], MAVLINK_STX_V2)
  assert_eq(v2_wire.length(), 1 + V2_HEADER_LEN + 9 + 2)
  let (decoded_v2_frame, consumed_v2) = match
    decode_frame(v2_wire, lookup_message_crc_extra) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(consumed_v2, v2_wire.length())
  assert_eq(decoded_v2_frame, v2_frame)
  assert_eq(MavMessage::decode_from_frame(decoded_v2_frame), Ok(msg))
}

///|
test "frame: HEARTBEAT legacy MAVLink v1 (0xFE) frame encoding and decoding" {
  let hb : Heartbeat = {
    mav_type: MavType::FixedWing.to_uint().to_byte(),
    autopilot: MavAutopilot::Ardupilotmega.to_uint().to_byte(),
    base_mode: b'\x81',
    custom_mode: 11U,
    system_status: MavState::Standby.to_uint().to_byte(),
    mavlink_version: b'\x03',
  }
  let msg = MsgHeartbeat(hb)
  let (v1_wire, _) = match
    msg.encode_to_frame(seq=b'\x08', sysid=b'\x01', compid=b'\x01', version=V1) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(v1_wire[0], MAVLINK_STX_V1)
  assert_eq(v1_wire.length(), 1 + V1_HEADER_LEN + 9 + 2)
  let (decoded_v1_frame, consumed_v1) = match
    decode_frame(v1_wire, lookup_message_crc_extra) {
    Ok(res) => res
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(consumed_v1, v1_wire.length())
  assert_eq(decoded_v1_frame.header.version, V1)
  assert_eq(MavMessage::decode_from_frame(decoded_v1_frame), Ok(msg))
}

///|
test "frame: SYS_STATUS and SYSTEM_TIME v2 roundtrip" {
  let ss : SysStatus = {
    onboard_control_sensors_present: 0x3FFU,
    onboard_control_sensors_enabled: 0x3FFU,
    onboard_control_sensors_health: 0x3FFU,
    load: 410U,
    voltage_battery: 15800U,
    current_battery: 1200,
    battery_remaining: 78,
    drop_rate_comm: 2U,
    errors_comm: 0U,
    errors_count1: 0U,
    errors_count2: 0U,
    errors_count3: 0U,
    errors_count4: 1U,
  }
  let (ss_wire, _) = match
    MsgSysStatus(ss).encode_to_frame(seq=b'\x01', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (ss_f, _) = match decode_frame(ss_wire, lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(MavMessage::decode_from_frame(ss_f), Ok(MsgSysStatus(ss)))

  let stime : SystemTime = {
    time_unix_usec: 1730000123456789UL,
    time_boot_ms: 85400U,
  }
  let (st_wire, _) = match
    MsgSystemTime(stime).encode_to_frame(
      seq=b'\x02',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (st_f, _) = match decode_frame(st_wire, lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(MavMessage::decode_from_frame(st_f), Ok(MsgSystemTime(stime)))
}

///|
test "frame: PING and RC_CHANNELS_RAW v2 roundtrip" {
  let ping : Ping = {
    time_usec: 99887766UL,
    seq: 7U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  assert_eq(Ping::decode_payload(ping.encode_payload(), v2=true), Ok(ping))

  let rc : RcChannelsRaw = {
    time_boot_ms: 5000U,
    port: b'\x00',
    chan1_raw: 1500U,
    chan2_raw: 1500U,
    chan3_raw: 1000U,
    chan4_raw: 1500U,
    chan5_raw: 2000U,
    chan6_raw: 1500U,
    chan7_raw: 1500U,
    chan8_raw: 1500U,
    rssi: (254).to_byte(),
  }
  assert_eq(RcChannelsRaw::decode_payload(rc.encode_payload(), v2=true), Ok(rc))
}

///|
test "frame: PARAM_REQUEST_READ, PARAM_VALUE, and PARAM_SET char[16] roundtrip" {
  let req : ParamRequestRead = {
    target_system: b'\x01',
    target_component: b'\x01',
    param_id: "SYS_AUTOSTART",
    param_index: -1,
  }
  assert_eq(
    ParamRequestRead::decode_payload(req.encode_payload(), v2=true),
    Ok(req),
  )

  let pset : ParamSet = {
    target_system: b'\x01',
    target_component: b'\x01',
    param_id: "MPC_Z_VEL_MAX_UP",
    param_value: (3.5 : Float),
    param_type: b'\x09',
  }
  assert_eq(ParamSet::decode_payload(pset.encode_payload(), v2=true), Ok(pset))
}

///|
test "frame: GPS_RAW_INT v2 RTK extension fields preserved in v2 and zero-filled from v1" {
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
  assert_eq(
    GpsRawInt::decode_payload(gps.encode_payload(v2=true), v2=true),
    Ok(gps),
  )

  let v1_bytes = gps.encode_payload(v2=false)
  assert_eq(v1_bytes.length(), 30)
  let decoded_from_v1 = match GpsRawInt::decode_payload(v1_bytes, v2=true) {
    Ok(m) => m
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(decoded_from_v1.lat, gps.lat)
  assert_eq(decoded_from_v1.alt_ellipsoid, 0)
  assert_eq(decoded_from_v1.yaw, 0U)
}

///|
test "frame: MISSION_COUNT, MISSION_REQUEST_INT, MISSION_ITEM_INT, and MISSION_ACK v2 extensions roundtrip" {
  let mc : MissionCount = {
    target_system: b'\x01',
    target_component: b'\x01',
    count: 5U,
    mission_type: MavMissionType::Fence.to_uint().to_byte(),
    opaque_id: 999U,
  }
  assert_eq(MissionCount::decode_payload(mc.encode_payload(), v2=true), Ok(mc))

  let mreq : MissionRequestInt = {
    target_system: b'\x01',
    target_component: b'\x01',
    seq: 2U,
    mission_type: MavMissionType::Fence.to_uint().to_byte(),
  }
  assert_eq(
    MissionRequestInt::decode_payload(mreq.encode_payload(), v2=true),
    Ok(mreq),
  )

  let mitem : MissionItemInt = {
    target_system: b'\x01',
    target_component: b'\x01',
    seq: 2U,
    frame: MavCoordFrame::GlobalRelativeAltInt.to_uint().to_byte(),
    command: MavCmd::NavWaypoint.to_uint(),
    current: b'\x00',
    autocontinue: b'\x01',
    param1: (0.0 : Float),
    param2: (1.5 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    x: 225430960,
    y: 1140578650,
    z: (40.0 : Float),
    mission_type: MavMissionType::Mission.to_uint().to_byte(),
  }
  assert_eq(
    MissionItemInt::decode_payload(mitem.encode_payload(), v2=true),
    Ok(mitem),
  )

  let mack : MissionAck = {
    target_system: b'\xFF',
    target_component: b'\xBE',
    mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
    mission_type: MavMissionType::Mission.to_uint().to_byte(),
    opaque_id: 999U,
  }
  assert_eq(
    MissionAck::decode_payload(mack.encode_payload(), v2=true),
    Ok(mack),
  )
}

///|
test "frame: 24-bit message ID LOGGING_ACK (#268) works in v2 and returns UnsupportedV1MessageId in v1" {
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
}

///|
test "frame error: InvalidMagic on unknown start-of-text byte" {
  let bad = b"\xAA\x09\x00\x00\x01\x01\x01\x00\x00\x00"
  assert_eq(
    decode_frame(bad, lookup_message_crc_extra),
    Err(InvalidMagic(b'\xAA')),
  )
}

///|
test "frame error: IncompleteFrame on truncated header or truncated payload" {
  assert_eq(
    decode_frame(b"", lookup_message_crc_extra),
    Err(IncompleteFrame(1, 0)),
  )
  assert_eq(
    decode_frame(b"\xFD\x09\x00\x00", lookup_message_crc_extra),
    Err(IncompleteFrame(12, 4)),
  )
  assert_eq(
    decode_frame(
      b"\xFD\x09\x00\x00\x01\x01\x01\x00\x00\x00\x01\x02", lookup_message_crc_extra,
    ),
    Err(IncompleteFrame(21, 12)),
  )
}

///|
test "frame error: UnsupportedIncompatFlags on unknown v2 incompatibility bit" {
  let unknown_flag = b"\xFD\x01\x04\x00\x01\x01\x01\x00\x00\x00\x00\x00\x00"
  assert_eq(
    decode_frame(unknown_flag, lookup_message_crc_extra),
    Err(UnsupportedIncompatFlags(b'\x04')),
  )
}

///|
test "frame error: UnknownMessageId when msgid is absent from crc_extra table" {
  let unknown_msg = b"\xFD\x01\x00\x00\x01\x01\x01\xFF\xFF\x0F\x00\x00\x00"
  assert_eq(
    decode_frame(unknown_msg, lookup_message_crc_extra),
    Err(UnknownMessageId(0x0FFFFFU)),
  )
}

///|
test "frame error: CrcMismatch when wire payload or checksum byte is flipped" {
  let ping : Ping = {
    time_usec: 1UL,
    seq: 1U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  let (wire, _) = match
    MsgPing(ping).encode_to_frame(seq=b'\x01', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let corrupted : Array[Byte] = []
  for i = 0; i < wire.length() - 1; i = i + 1 {
    corrupted.push(wire[i])
  }
  corrupted.push((wire[wire.length() - 1].to_uint() ^ 0xFFU).to_byte())
  assert_true(
    decode_frame(Bytes::from_array(corrupted), lookup_message_crc_extra)
    is Err(CrcMismatch(_, _)),
  )
}

///|
test "sha256: FIPS 180-4 empty string and 'abc' standard test vectors" {
  let empty_digest = sha256_digest(b"")
  assert_eq(empty_digest[0], b'\xe3')
  assert_eq(empty_digest[1], b'\xb0')
  assert_eq(empty_digest[2], b'\xc4')
  assert_eq(empty_digest[3], b'\x42')
  assert_eq(empty_digest[31], b'\x55')

  let abc_digest = sha256_digest(b"abc")
  assert_eq(abc_digest[0], b'\xba')
  assert_eq(abc_digest[1], b'\x78')
  assert_eq(abc_digest[2], b'\x16')
  assert_eq(abc_digest[3], b'\xbf')
  assert_eq(abc_digest[31], b'\xad')
}

///|
test "sha256: multi-block (>64 bytes) message digest verification" {
  // FIPS 180-4 448-bit / 56-byte vector that spans 2 SHA-256 blocks after padding
  let msg = b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
  let d = sha256_digest(msg)
  assert_eq(d[0], b'\x24')
  assert_eq(d[1], b'\x8d')
  assert_eq(d[2], b'\x6a')
  assert_eq(d[3], b'\x61')
  assert_eq(d[29], b'\xdb')
  assert_eq(d[30], b'\x06')
  assert_eq(d[31], b'\xc1')
}

///|
test "signing: SigningContext rejects key length != 32 bytes" {
  assert_true(SigningContext::new(b"short_key") is Err(SignatureInvalid(_)))
}

///|
test "signing: MAVLink v2 13-byte packet signature generation and verification" {
  let secret_key = b"0123456789abcdef0123456789abcdef"
  let tx_signer = match
    SigningContext::new(secret_key, link_id=b'\x02', initial_timestamp=1000UL) {
    Ok(c) => c
    Err(e) => fail(e.to_repr().to_string())
  }
  let rx_verifier = match
    SigningContext::new(secret_key, link_id=b'\x02', initial_timestamp=1000UL) {
    Ok(c) => c
    Err(e) => fail(e.to_repr().to_string())
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
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(signed_frame.header.incompat_flags, IFLAG_SIGNED)
  assert_true(signed_frame.signature is Some(_))
  let (verified_frame, _) = match
    decode_frame(
      signed_wire,
      lookup_message_crc_extra,
      signing=Some(rx_verifier),
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    MavMessage::decode_from_frame(verified_frame),
    Ok(MsgCommandAck(ack)),
  )
}

///|
test "signing: monotonic timestamp anti-replay protection and unsigned rejection" {
  let secret_key = b"0123456789abcdef0123456789abcdef"
  let tx_signer = match
    SigningContext::new(secret_key, link_id=b'\x01', initial_timestamp=500UL) {
    Ok(c) => c
    Err(e) => fail(e.to_repr().to_string())
  }
  let rx_verifier = match
    SigningContext::new(secret_key, link_id=b'\x01', initial_timestamp=500UL) {
    Ok(c) => c
    Err(e) => fail(e.to_repr().to_string())
  }
  let ping : Ping = {
    time_usec: 42UL,
    seq: 1U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  let (signed_wire, _) = match
    MsgPing(ping).encode_to_frame(
      seq=b'\x01',
      sysid=b'\x01',
      compid=b'\x01',
      signing=Some(tx_signer),
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_true(
    decode_frame(
      signed_wire,
      lookup_message_crc_extra,
      signing=Some(rx_verifier),
    )
    is Ok(_),
  )
  // Replaying same packet must fail anti-replay check
  assert_true(
    decode_frame(
      signed_wire,
      lookup_message_crc_extra,
      signing=Some(rx_verifier),
    )
    is Err(SignatureInvalid(_)),
  )
  // Unsigned packet must fail with SignatureMissing
  let (unsigned_wire, _) = match
    MsgPing(ping).encode_to_frame(seq=b'\x02', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    decode_frame(
      unsigned_wire,
      lookup_message_crc_extra,
      signing=Some(rx_verifier),
    ),
    Err(SignatureMissing),
  )
}

///|
test "stream parser: leading UART noise skipping and multi-frame concatenation" {
  let hb : Heartbeat = {
    mav_type: b'\x02',
    autopilot: b'\x0C',
    base_mode: b'\x81',
    custom_mode: 0U,
    system_status: b'\x04',
    mavlink_version: b'\x03',
  }
  let (f1, _) = match
    MsgHeartbeat(hb).encode_to_frame(seq=b'\x00', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (f2, _) = match
    MsgHeartbeat(hb).encode_to_frame(seq=b'\x01', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let buf : Array[Byte] = [b'\x00', b'\x11', b'\x22', b'\x33']
  for i = 0; i < f1.length(); i = i + 1 {
    buf.push(f1[i])
  }
  for i = 0; i < f2.length(); i = i + 1 {
    buf.push(f2[i])
  }
  let parser = FrameParser::new()
  let events = parser.push_bytes(
    Bytes::from_array(buf),
    lookup_message_crc_extra,
  )
  assert_eq(events.length(), 2)
  assert_eq(parser.packets_received, 2U)
  assert_eq(parser.packets_dropped, 0U)
  assert_eq(parser.noise_bytes_skipped, 4U)
}

///|
test "stream parser: 1-byte at a time byte-by-byte fragmented reassembly" {
  let ping : Ping = {
    time_usec: 123456UL,
    seq: 9U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  let (wire, _) = match
    MsgPing(ping).encode_to_frame(seq=b'\x05', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let parser = FrameParser::new()
  let mut decoded_count = 0
  for i = 0; i < wire.length(); i = i + 1 {
    let single = Bytes::from_array([wire[i]])
    let evs = parser.push_bytes(single, lookup_message_crc_extra)
    decoded_count = decoded_count + evs.length()
  }
  assert_eq(decoded_count, 1)
  assert_eq(parser.packets_received, 1U)
}

///|
test "stream parser: sequence gap packet drop counting and CRC error recovery" {
  let hb : Heartbeat = {
    mav_type: b'\x02',
    autopilot: b'\x0C',
    base_mode: b'\x81',
    custom_mode: 0U,
    system_status: b'\x04',
    mavlink_version: b'\x03',
  }
  let (f1, _) = match
    MsgHeartbeat(hb).encode_to_frame(
      seq=(10).to_byte(),
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (f2, _) = match
    MsgHeartbeat(hb).encode_to_frame(
      seq=(14).to_byte(),
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let buf : Array[Byte] = []
  for i = 0; i < f1.length(); i = i + 1 {
    buf.push(f1[i])
  }
  // Corrupted frame
  for i = 0; i < f1.length() - 1; i = i + 1 {
    buf.push(f1[i])
  }
  buf.push((f1[f1.length() - 1].to_uint() ^ 0xFFU).to_byte())
  // Valid f2 (seq=14, gap of 3 packets: 11, 12, 13)
  for i = 0; i < f2.length(); i = i + 1 {
    buf.push(f2[i])
  }
  let parser = FrameParser::new()
  let _ = parser.push_bytes(Bytes::from_array(buf), lookup_message_crc_extra)
  assert_eq(parser.packets_received, 2U)
  assert_eq(parser.packets_dropped, 3U)
  assert_eq(parser.crc_errors, 1U)
}

///|
test "golden audit: all 45 official messages match C c_library_v2 CRC_EXTRA and payload lengths" {
  let golden = official_45_golden_table()
  assert_eq(golden.length(), 45)
  let schema = match parse_dialect_xml(official_standard_xml) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.messages.length(), 45)
  assert_eq(schema.enums.length(), 18)

  for i = 0; i < golden.length(); i = i + 1 {
    let g = golden[i]
    let m = schema.messages[i]
    assert_eq(m.id, g.msg_id)
    assert_eq(m.name, g.name)
    assert_eq(m.crc_extra, g.expected_crc_extra)
    assert_eq(m.base_payload_len, g.expected_base_len)
    assert_eq(m.max_payload_len, g.expected_max_len)
    assert_eq(lookup_message_crc_extra(g.msg_id), Some(g.expected_crc_extra))
    assert_eq(lookup_message_name(g.msg_id), Some(g.name))
  }
}

///|
test "dialect roundtrip: SetMode (#11), ParamRequestList (#21), ScaledImu (#26), RawImu (#27), ScaledPressure (#29)" {
  let sm : SetMode = {
    custom_mode: 0x00040000U,
    target_system: b'\x01',
    base_mode: b'\xd1',
  }
  assert_eq(
    SetMode::decode_payload(sm.encode_payload(v2=true), v2=true),
    Ok(sm),
  )

  let prl : ParamRequestList = {
    target_system: b'\x01',
    target_component: b'\x01',
  }
  assert_eq(
    ParamRequestList::decode_payload(prl.encode_payload(v2=true), v2=true),
    Ok(prl),
  )

  let simu : ScaledImu = {
    time_boot_ms: 85000U,
    xacc: -12,
    yacc: 8,
    zacc: -998,
    xgyro: 3,
    ygyro: -2,
    zgyro: 1,
    xmag: 240,
    ymag: -45,
    zmag: 410,
    temperature: 3850,
  }
  assert_eq(
    ScaledImu::decode_payload(simu.encode_payload(v2=true), v2=true),
    Ok(simu),
  )

  let rimu : RawImu = {
    time_usec: 1730800500000UL,
    xacc: -120,
    yacc: 85,
    zacc: -16384,
    xgyro: 14,
    ygyro: -9,
    zgyro: 2,
    xmag: 512,
    ymag: -128,
    zmag: 1024,
    id: b'\x01',
    temperature: 4120,
  }
  assert_eq(
    RawImu::decode_payload(rimu.encode_payload(v2=true), v2=true),
    Ok(rimu),
  )

  let sp : ScaledPressure = {
    time_boot_ms: 85100U,
    press_abs: (1013.25 : Float),
    press_diff: (1.25 : Float),
    temperature: 2650,
    temperature_press_diff: 2640,
  }
  assert_eq(
    ScaledPressure::decode_payload(sp.encode_payload(v2=true), v2=true),
    Ok(sp),
  )
}

///|
test "dialect roundtrip: AttitudeQuaternion (#31) and SetAttitudeTarget (#82) with float[4] quaternion arrays" {
  let aq : AttitudeQuaternion = {
    time_boot_ms: 91000U,
    q1: (1.0 : Float),
    q2: (0.0 : Float),
    q3: (0.0 : Float),
    q4: (0.0 : Float),
    rollspeed: (0.01 : Float),
    pitchspeed: (-0.02 : Float),
    yawspeed: (0.05 : Float),
    repr_offset_q: [
      (0.70710677 : Float),
      (0.0 : Float),
      (0.70710677 : Float),
      (0.0 : Float),
    ],
  }
  let (wire_aq, _) = match
    MsgAttitudeQuaternion(aq).encode_to_frame(
      seq=b'\x11',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (frame_aq, _) = match decode_frame(wire_aq, lookup_message_crc_extra) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(
    MavMessage::decode_from_frame(frame_aq),
    Ok(MsgAttitudeQuaternion(aq)),
  )

  let sat : SetAttitudeTarget = {
    time_boot_ms: 91200U,
    q: [(1.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)],
    body_roll_rate: (0.0 : Float),
    body_pitch_rate: (0.0 : Float),
    body_yaw_rate: (0.25 : Float),
    thrust: (0.62 : Float),
    target_system: b'\x01',
    target_component: b'\x01',
    type_mask: b'\x00',
  }
  assert_eq(
    SetAttitudeTarget::decode_payload(sat.encode_payload(v2=true), v2=true),
    Ok(sat),
  )
}

///|
test "dialect roundtrip: ServoOutputRaw (#36), RcChannels (#65), ManualControl (#69), VfrHud (#74)" {
  let srv : ServoOutputRaw = {
    time_usec: 1200000U,
    servo1_raw: 1500U,
    servo2_raw: 1520U,
    servo3_raw: 1480U,
    servo4_raw: 1500U,
    servo5_raw: 1100U,
    servo6_raw: 1900U,
    servo7_raw: 1500U,
    servo8_raw: 1500U,
    port: b'\x00',
    servo9_raw: 1500U,
    servo10_raw: 1500U,
    servo11_raw: 1000U,
    servo12_raw: 2000U,
    servo13_raw: 0U,
    servo14_raw: 0U,
    servo15_raw: 0U,
    servo16_raw: 0U,
  }
  assert_eq(
    ServoOutputRaw::decode_payload(srv.encode_payload(v2=true), v2=true),
    Ok(srv),
  )

  let rcc : RcChannels = {
    time_boot_ms: 95000U,
    chan1_raw: 1500U,
    chan2_raw: 1500U,
    chan3_raw: 1200U,
    chan4_raw: 1500U,
    chan5_raw: 1800U,
    chan6_raw: 1000U,
    chan7_raw: 1500U,
    chan8_raw: 1500U,
    chan9_raw: 1500U,
    chan10_raw: 1500U,
    chan11_raw: 1500U,
    chan12_raw: 1500U,
    chan13_raw: 0U,
    chan14_raw: 0U,
    chan15_raw: 0U,
    chan16_raw: 0U,
    chan17_raw: 0U,
    chan18_raw: 0U,
    chancount: b'\x0c',
    rssi: b'\xc8',
  }
  assert_eq(
    RcChannels::decode_payload(rcc.encode_payload(v2=true), v2=true),
    Ok(rcc),
  )

  let mc : ManualControl = {
    x: 450,
    y: -120,
    z: 600,
    r: -50,
    buttons: 0x0005U,
    target: b'\x01',
    buttons2: 0x0010U,
    enabled_extensions: b'\x03',
    s: 100,
    t: -200,
  }
  assert_eq(
    ManualControl::decode_payload(mc.encode_payload(v2=true), v2=true),
    Ok(mc),
  )

  let hud : VfrHud = {
    airspeed: (18.5 : Float),
    groundspeed: (17.2 : Float),
    alt: (120.5 : Float),
    climb: (1.8 : Float),
    heading: 270,
    throttle: 68U,
  }
  assert_eq(
    VfrHud::decode_payload(hud.encode_payload(v2=true), v2=true),
    Ok(hud),
  )
}

///|
test "dialect roundtrip: Mission family (#40, #41, #42, #43, #45, #46) and Command family (#75, #80)" {
  let mreq : MissionRequest = {
    seq: 4U,
    target_system: b'\x01',
    target_component: b'\x01',
    mission_type: b'\x01',
  }
  assert_eq(
    MissionRequest::decode_payload(mreq.encode_payload(v2=true), v2=true),
    Ok(mreq),
  )

  let mset : MissionSetCurrent = {
    seq: 2U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  assert_eq(
    MissionSetCurrent::decode_payload(mset.encode_payload(v2=true), v2=true),
    Ok(mset),
  )

  let mcur : MissionCurrent = {
    seq: 2U,
    total: 8U,
    mission_state: b'\x03',
    mission_mode: b'\x01',
  }
  assert_eq(
    MissionCurrent::decode_payload(mcur.encode_payload(v2=true), v2=true),
    Ok(mcur),
  )

  let mlist : MissionRequestList = {
    target_system: b'\x01',
    target_component: b'\x01',
    mission_type: b'\x02',
  }
  assert_eq(
    MissionRequestList::decode_payload(mlist.encode_payload(v2=true), v2=true),
    Ok(mlist),
  )

  let mclr : MissionClearAll = {
    target_system: b'\x01',
    target_component: b'\x01',
    mission_type: b'\x00',
  }
  assert_eq(
    MissionClearAll::decode_payload(mclr.encode_payload(v2=true), v2=true),
    Ok(mclr),
  )

  let mrch : MissionItemReached = { seq: 5U, }
  assert_eq(
    MissionItemReached::decode_payload(mrch.encode_payload(v2=true), v2=true),
    Ok(mrch),
  )

  let cint : CommandInt = {
    param1: (0.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    x: 225430960,
    y: 1140578650,
    z: (40.0 : Float),
    command: 16U,
    target_system: b'\x01',
    target_component: b'\x01',
    frame: b'\x06',
    current: b'\x00',
    autocontinue: b'\x01',
  }
  assert_eq(
    CommandInt::decode_payload(cint.encode_payload(v2=true), v2=true),
    Ok(cint),
  )

  let ccan : CommandCancel = {
    command: 400U,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  assert_eq(
    CommandCancel::decode_payload(ccan.encode_payload(v2=true), v2=true),
    Ok(ccan),
  )
}

///|
test "dialect roundtrip: Timesync (#111), DistanceSensor (#132), BatteryStatus (#147), AutopilotVersion (#148), ExtendedSysState (#245), MavDebug (#254)" {
  let ts : Timesync = {
    tc1: 1730800005000000L,
    ts1: 1730800001000000L,
    target_system: b'\x01',
    target_component: b'\x01',
  }
  assert_eq(
    Timesync::decode_payload(ts.encode_payload(v2=true), v2=true),
    Ok(ts),
  )

  let ds : DistanceSensor = {
    time_boot_ms: 112000U,
    min_distance: 5U,
    max_distance: 4000U,
    current_distance: 342U,
    mav_type: b'\x00',
    id: b'\x01',
    orientation: b'\x19',
    covariance: b'\x02',
    horizontal_fov: (0.52 : Float),
    vertical_fov: (0.52 : Float),
    quaternion: [(1.0 : Float), (0.0 : Float), (0.0 : Float), (0.0 : Float)],
    signal_quality: b'\x5a',
  }
  assert_eq(
    DistanceSensor::decode_payload(ds.encode_payload(v2=true), v2=true),
    Ok(ds),
  )

  let bat : BatteryStatus = {
    current_consumed: 1420,
    energy_consumed: 850,
    temperature: 3420,
    voltages: [4120U, 4118U, 4122U, 4119U, 4120U, 4121U, 0U, 0U, 0U, 0U],
    current_battery: 1850,
    id: b'\x00',
    battery_function: b'\x01',
    mav_type: b'\x03',
    battery_remaining: 74,
    time_remaining: 920,
    charge_state: b'\x01',
    voltages_ext: [0U, 0U, 0U, 0U],
    mode: b'\x00',
    fault_bitmask: 0U,
  }
  assert_eq(
    BatteryStatus::decode_payload(bat.encode_payload(v2=true), v2=true),
    Ok(bat),
  )

  let av : AutopilotVersion = {
    capabilities: 0x000000000000FFFFUL,
    uid: 0x1122334455667788UL,
    flight_sw_version: 0x010E0000U,
    middleware_sw_version: 0x010E0000U,
    os_sw_version: 0x0B020000U,
    board_version: 0x00000032U,
    vendor_id: 0x26ACU,
    product_id: 0x0032U,
    flight_custom_version: [
      b'\x31', b'\x61', b'\x32', b'\x62', b'\x33', b'\x63', b'\x34', b'\x64',
    ],
    middleware_custom_version: [
      b'\x31', b'\x61', b'\x32', b'\x62', b'\x33', b'\x63', b'\x34', b'\x64',
    ],
    os_custom_version: [
      b'\x30', b'\x30', b'\x30', b'\x30', b'\x30', b'\x30', b'\x30', b'\x30',
    ],
    uid2: [
      b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06', b'\x07', b'\x08', b'\x09',
      b'\x0A', b'\x0B', b'\x0C', b'\x0D', b'\x0E', b'\x0F', b'\x10', b'\x11', b'\x12',
    ],
  }
  assert_eq(
    AutopilotVersion::decode_payload(av.encode_payload(v2=true), v2=true),
    Ok(av),
  )

  let ess : ExtendedSysState = { vtol_state: b'\x03', landed_state: b'\x02', }
  assert_eq(
    ExtendedSysState::decode_payload(ess.encode_payload(v2=true), v2=true),
    Ok(ess),
  )

  let dbg : MavDebug = {
    time_boot_ms: 115000U,
    value: (3.1415927 : Float),
    ind: b'\x07',
  }
  assert_eq(
    MavDebug::decode_payload(dbg.encode_payload(v2=true), v2=true),
    Ok(dbg),
  )
}

///|
test "xml include: multi-file topological merge, diamond deduplication, and cycle rejection" {
  let overlay_a =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <include>minimal.xml</include>
    #|  <enums>
    #|    <enum name="MAV_AUTOPILOT">
    #|      <entry value="99" name="MAV_AUTOPILOT_CUSTOM_A"/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id="9001" name="CUSTOM_A">
    #|      <field type="uint16_t" name="val_a"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>

  let overlay_b =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <include>minimal.xml</include>
    #|  <include>overlay_a.xml</include>
    #|  <messages>
    #|    <message id="9002" name="CUSTOM_B">
    #|      <field type="uint32_t" name="val_b"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>

  let diamond_res = parse_dialect_xml_with_includes("overlay_b.xml", fn(name) {
    match name {
      "minimal.xml" => Some(official_minimal_xml)
      "overlay_a.xml" => Some(overlay_a)
      "overlay_b.xml" => Some(overlay_b)
      _ => None
    }
  })
  let merged = match diamond_res {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(merged.messages.length(), 3)
  assert_eq(merged.messages[0].name, "HEARTBEAT")
  assert_eq(merged.messages[1].name, "CUSTOM_A")
  assert_eq(merged.messages[2].name, "CUSTOM_B")
  // MAV_AUTOPILOT should contain the 4 minimal entries + 1 custom entry = 5
  assert_eq(merged.enums[0].entries.length(), 5)

  // Cyclic <include> detection: cycle1.xml <-> cycle2.xml
  let cycle1 = "<mavlink><include>cycle2.xml</include></mavlink>"
  let cycle2 = "<mavlink><include>cycle1.xml</include></mavlink>"
  let cycle_res = parse_dialect_xml_with_includes("cycle1.xml", fn(name) {
    match name {
      "cycle1.xml" => Some(cycle1)
      "cycle2.xml" => Some(cycle2)
      _ => None
    }
  })
  assert_true(cycle_res is Err(SchemaError(_)))

  // Unresolvable <include> file
  let missing_res = parse_dialect_xml_with_includes("missing.xml", fn(_) {
    None
  })
  assert_true(missing_res is Err(SchemaError(_)))
}

///|
test "xml include: conflicting enum entry value and duplicate message ID across includes are rejected" {
  let bad_enum_overlay =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <include>minimal.xml</include>
    #|  <enums>
    #|    <enum name="MAV_AUTOPILOT">
    #|      <entry value="99" name="MAV_AUTOPILOT_PX4"/>
    #|    </enum>
    #|  </enums>
    #|</mavlink>
  let res1 = parse_dialect_xml_with_includes("bad_enum.xml", fn(name) {
    match name {
      "minimal.xml" => Some(official_minimal_xml)
      "bad_enum.xml" => Some(bad_enum_overlay)
      _ => None
    }
  })
  assert_true(res1 is Err(SchemaError(_)))

  let dup_msg_overlay =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <include>minimal.xml</include>
    #|  <messages>
    #|    <message id="0" name="DUPLICATE_HB">
    #|      <field type="uint8_t" name="x"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  let res2 = parse_dialect_xml_with_includes("dup_msg.xml", fn(name) {
    match name {
      "minimal.xml" => Some(official_minimal_xml)
      "dup_msg.xml" => Some(dup_msg_overlay)
      _ => None
    }
  })
  assert_true(res2 is Err(SchemaError(_)))
}

///|
test "xml schema boundary: exact 255-byte max payload succeeds while 256-byte payload is rejected" {
  let ok_255_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="500" name="MAX_255_MSG">
    #|      <field type="uint8_t[255]" name="data"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  let s255 = match parse_dialect_xml(ok_255_xml) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(s255.messages[0].max_payload_len, 255)

  let err_256_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <messages>
    #|    <message id="501" name="OVER_256_MSG">
    #|      <field type="uint8_t[255]" name="data"/>
    #|      <field type="uint8_t" name="extra"/>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  assert_true(parse_dialect_xml(err_256_xml) is Err(SchemaError(_)))
}

///|
test "microservice: HeartbeatMonitor tracks multi-node armed state, sequence wrap-around, and link timeout" {
  let mon = HeartbeatMonitor::new(timeout_ms=2000UL)
  let hb_disarmed : Heartbeat = {
    custom_mode: 0x00010000U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\x51',
    system_status: b'\x03',
    mavlink_version: b'\x03',
  }
  let hb_armed : Heartbeat = { ..hb_disarmed, base_mode: b'\xd1', }

  let (_, f254) = match
    MsgHeartbeat(hb_disarmed).encode_to_frame(
      seq=b'\xfe',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (_, f255) = match
    MsgHeartbeat(hb_disarmed).encode_to_frame(
      seq=b'\xff',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (_, f002) = match
    MsgHeartbeat(hb_armed).encode_to_frame(
      seq=b'\x02',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }

  mon.on_frame(f254, 1000UL)
  assert_eq(mon.is_node_alive(b'\x01', b'\x01', 1500UL), true)
  match mon.get_node(b'\x01', b'\x01') {
    Some(n) => assert_eq(n.armed, false)
    None => fail("Expected node (1,1)")
  }

  mon.on_frame(f255, 2000UL)
  // Jump from seq=255 to seq=2 (seq 0 and 1 dropped -> 2 dropped frames)
  mon.on_frame(f002, 2500UL)
  match mon.get_node(b'\x01', b'\x01') {
    Some(n) => {
      assert_eq(n.armed, true)
      assert_eq(n.received_frames, 3)
      assert_eq(n.dropped_frames, 2)
      assert_eq(n.heartbeat_count, 3)
    }
    None => fail("Expected node (1,1)")
  }
  assert_eq(mon.node_packet_loss_ratio(b'\x01', b'\x01'), 0.4)
  assert_eq(mon.is_node_alive(b'\x01', b'\x01', 4500UL), true)
  assert_eq(mon.is_node_alive(b'\x01', b'\x01', 4501UL), false)
}

///|
test "microservice: ParameterClient & ParameterServer list sync, gap recovery, PARAM_SET, and max-retry timeout" {
  let srv = ParameterServer::new(b'\x01', b'\x01', [
    ("MC_ROLL_P", (6.5 : Float), b'\x09'),
    ("MC_PITCH_P", (6.5 : Float), b'\x09'),
    ("MC_YAW_P", (2.8 : Float), b'\x09'),
  ])
  let cli = ParameterClient::new(
    b'\x01',
    b'\x01',
    timeout_ms=500UL,
    max_retries=2,
  )

  let req_list = cli.start_list_sync(100UL)
  let replies = srv.handle_message(req_list)
  assert_eq(replies.length(), 3)

  // Deliver only param 0 and param 2 (simulating loss of index 1)
  match replies[0] {
    MsgParamValue(pv) => cli.on_param_value(pv, 110UL)
    _ => fail("Expected MsgParamValue")
  }
  match replies[2] {
    MsgParamValue(pv) => cli.on_param_value(pv, 120UL)
    _ => fail("Expected MsgParamValue")
  }
  assert_eq(cli.state, ListingAll)
  assert_eq(cli.missing_indices(), [1])

  // Poll timeout at 700ms -> requests missing index 1
  let retry_req = match cli.poll_timeout(700UL) {
    Some(r) => r
    None => fail("Expected targeted PARAM_REQUEST_READ for index 1")
  }
  let rec_replies = srv.handle_message(retry_req)
  assert_eq(rec_replies.length(), 1)
  match rec_replies[0] {
    MsgParamValue(pv) => cli.on_param_value(pv, 720UL)
    _ => fail("Expected MsgParamValue")
  }
  assert_eq(cli.state, Synced)

  // Now perform a verified PARAM_SET transaction on MC_YAW_P
  let set_msg = cli.start_param_set("MC_YAW_P", (3.2 : Float), b'\x09', 1000UL)
  let set_ack = srv.handle_message(set_msg)
  match set_ack[0] {
    MsgParamValue(pv) => cli.on_param_value(pv, 1050UL)
    _ => fail("Expected MsgParamValue")
  }
  assert_eq(cli.state, Synced)
  match cli.get_param("MC_YAW_P") {
    Some(p) => assert_eq(p.param_value, (3.2 : Float))
    None => fail("Expected MC_YAW_P")
  }

  // Test max-retry exhaustion when vehicle stops responding
  let _ = cli.start_param_set("MC_ROLL_P", (7.0 : Float), b'\x09', 2000UL)
  assert_true(cli.poll_timeout(2600UL) is Some(_))
  assert_true(cli.poll_timeout(3200UL) is Some(_))
  assert_eq(cli.poll_timeout(3800UL), None)
  assert_true(cli.state is Failed(_))
}

///|
test "microservice: MissionUploadClient, MissionDownloadClient, and MissionServer full lifecycle" {
  let srv = MissionServer::new(b'\x01', b'\x01')
  let uploader = MissionUploadClient::new(
    b'\x01',
    b'\x01',
    timeout_ms=1000UL,
    max_retries=2,
  )

  let wp0 : MissionItemInt = {
    param1: (0.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    x: 225430960,
    y: 1140578650,
    z: (30.0 : Float),
    seq: 0U,
    command: 22U,
    target_system: b'\x01',
    target_component: b'\x01',
    frame: b'\x06',
    current: b'\x01',
    autocontinue: b'\x01',
    mission_type: b'\x00',
  }
  let wp1 : MissionItemInt = {
    ..wp0,
    seq: 1U,
    command: 16U,
    current: b'\x00',
    x: 225440000,
  }

  let count_msg = uploader.start_upload([wp0, wp1], 100UL)
  // Simulate timeout before vehicle responds -> retransmits MISSION_COUNT
  assert_eq(uploader.poll_timeout(1200UL), Some(count_msg))

  let req0 = match srv.handle_message(b'\xff', b'\xbe', count_msg) {
    Some(r) => r
    None => fail("Expected MISSION_REQUEST_INT(0)")
  }
  let item0_msg = match uploader.on_message(req0, 1250UL) {
    Some(m) => m
    None => fail("Expected MISSION_ITEM_INT(0)")
  }
  let req1 = match srv.handle_message(b'\xff', b'\xbe', item0_msg) {
    Some(r) => r
    None => fail("Expected MISSION_REQUEST_INT(1)")
  }
  let item1_msg = match uploader.on_message(req1, 1300UL) {
    Some(m) => m
    None => fail("Expected MISSION_ITEM_INT(1)")
  }
  let ack_msg = match srv.handle_message(b'\xff', b'\xbe', item1_msg) {
    Some(r) => r
    None => fail("Expected MISSION_ACK")
  }
  assert_eq(uploader.on_message(ack_msg, 1350UL), None)
  assert_eq(uploader.state, Completed)
  assert_eq(srv.stored_items.length(), 2)

  // Set current active mission item to 1
  let set_cur_reply = srv.handle_message(
    b'\xff',
    b'\xbe',
    MsgMissionSetCurrent({
      seq: 1U,
      target_system: b'\x01',
      target_component: b'\x01',
    }),
  )
  assert_true(set_cur_reply is Some(MsgMissionCurrent(_)))
  assert_eq(srv.active_seq, 1U)

  // Now download the 2 waypoints back using MissionDownloadClient
  let downloader = MissionDownloadClient::new(b'\x01', b'\x01')
  let dl_req_list = downloader.start_download(2000UL)
  let dl_count = match srv.handle_message(b'\xff', b'\xbe', dl_req_list) {
    Some(r) => r
    None => fail("Expected MISSION_COUNT")
  }
  let dl_req0 = match downloader.on_message(dl_count, 2050UL) {
    Some(r) => r
    None => fail("Expected MISSION_REQUEST_INT(0)")
  }
  let dl_item0 = match srv.handle_message(b'\xff', b'\xbe', dl_req0) {
    Some(r) => r
    None => fail("Expected MISSION_ITEM_INT(0)")
  }
  let dl_req1 = match downloader.on_message(dl_item0, 2100UL) {
    Some(r) => r
    None => fail("Expected MISSION_REQUEST_INT(1)")
  }
  let dl_item1 = match srv.handle_message(b'\xff', b'\xbe', dl_req1) {
    Some(r) => r
    None => fail("Expected MISSION_ITEM_INT(1)")
  }
  let dl_final_ack = downloader.on_message(dl_item1, 2150UL)
  assert_true(dl_final_ack is Some(MsgMissionAck(_)))
  assert_eq(downloader.state, Completed)
  assert_eq(downloader.downloaded_items, [wp0, wp1])

  // Clear all mission items on server
  let clr_ack = srv.handle_message(
    b'\xff',
    b'\xbe',
    MsgMissionClearAll({
      target_system: b'\x01',
      target_component: b'\x01',
      mission_type: b'\x00',
    }),
  )
  assert_true(clr_ack is Some(MsgMissionAck(_)))
  assert_eq(srv.stored_items.length(), 0)
}

///|
test "microservice: CommandClient confirmation counter increment, IN_PROGRESS, cancel, and timeout" {
  let cli = CommandClient::new(
    b'\x01',
    b'\x01',
    timeout_ms=500UL,
    max_retries=2,
  )
  let first = cli.send_command_long(400U, 1000UL, param1=(1.0 : Float))
  match first {
    MsgCommandLong(c) => assert_eq(c.confirmation, b'\x00')
    _ => fail("Expected MsgCommandLong")
  }
  assert_eq(cli.state, Pending(400U, b'\x00'))

  // Timeout 1 -> confirmation becomes 1
  match cli.poll_timeout(1600UL) {
    Some(MsgCommandLong(c)) => assert_eq(c.confirmation, b'\x01')
    _ => fail("Expected retransmission with confirmation=1")
  }
  // Vehicle reports IN_PROGRESS (50%)
  cli.on_command_ack(
    {
      command: 400U,
      result: MavResult::InProgress.to_uint().to_byte(),
      progress: b'\x32',
      result_param2: 0,
      target_system: b'\xff',
      target_component: b'\xbe',
    },
    1700UL,
  )
  assert_eq(cli.state, InProgress(400U, b'\x32'))

  // Cancel the long-running command
  let cancel_msg = cli.cancel_active(1800UL)
  assert_true(cancel_msg is Some(MsgCommandCancel(_)))
  assert_eq(cli.state, Finished(400U, Cancelled))

  // Test timeout exhaustion
  let _ = cli.send_command_long(22U, 3000UL)
  assert_true(cli.poll_timeout(3600UL) is Some(_))
  assert_true(cli.poll_timeout(4200UL) is Some(_))
  assert_eq(cli.poll_timeout(4800UL), None)
  assert_eq(cli.state, TimedOut(22U))
}

///|
test "microservice: TimesyncEstimator two-way RTT, clock offset, EMA smoothing, and invalid probe rejection" {
  let est = TimesyncEstimator::new()
  let probe = TimesyncEstimator::create_probe(1_000_000L)
  let req = match probe {
    MsgTimesync(t) => t
    _ => fail("Expected MsgTimesync")
  }
  let reply_msg = match
    TimesyncEstimator::respond_to_probe(req, 5_002_000L, b'\xff', b'\xbe') {
    Some(MsgTimesync(r)) => r
    _ => fail("Expected MsgTimesync response")
  }
  // Already-stamped message should not trigger another response
  assert_eq(
    TimesyncEstimator::respond_to_probe(reply_msg, 6_000_000L, b'\xff', b'\xbe'),
    None,
  )

  let sample1 = match est.on_probe_return(reply_msg, 1_004_000L) {
    Some(s) => s
    None => fail("Expected valid TimesyncSample")
  }
  assert_eq(sample1.rtt_ns, 4_000L)
  assert_eq(sample1.clock_offset_ns, 4_000_000L)
  assert_eq(est.min_rtt_ns, 4_000L)
  assert_eq(est.ema_rtt_ns, 4_000L)

  // Second sample with RTT = 8_000L -> EMA = (4000*3 + 8000)/4 = 5000L
  let reply2 : Timesync = {
    tc1: 6_004_000L,
    ts1: 2_000_000L,
    target_system: b'\xff',
    target_component: b'\xbe',
  }
  let _ = est.on_probe_return(reply2, 2_008_000L)
  assert_eq(est.sample_count, 2)
  assert_eq(est.min_rtt_ns, 4_000L)
  assert_eq(est.ema_rtt_ns, 5_000L)

  // Reject un-stamped probe or rx_time < ts1
  assert_eq(est.on_probe_return(req, 2_000_000L), None)
  assert_eq(est.on_probe_return(reply2, 1_999_000L), None)
}

///|
test "benchmark: zero-trimming bandwidth savings and noisy stream recovery invariants" {
  let bw = evaluate_zero_trimming_bandwidth()
  assert_eq(bw.total_frames, 200)
  assert_eq(bw.untrimmed_payload_bytes, 7580)
  assert_eq(bw.trimmed_payload_bytes, 5870)
  assert_eq(bw.saved_bytes, 1710)
  assert_true(bw.payload_saving_pct > 22.0)
  assert_true(bw.wire_saving_pct > 17.0)

  let stress_1b = evaluate_noisy_stream_recovery(100, 16, 1)
  assert_eq(stress_1b.recovered_frames, 100)
  assert_eq(stress_1b.injected_noise_bytes, 1600)
  assert_eq(stress_1b.detected_dropped_packets, 6)

  let stress_7b = evaluate_noisy_stream_recovery(150, 8, 7)
  assert_eq(stress_7b.recovered_frames, 150)
  assert_eq(stress_7b.injected_noise_bytes, 1200)
  assert_eq(stress_7b.detected_dropped_packets, 10)
}

///|
test "boundary: signed and unsigned scalar integer extremes (int8, int16, int32, int64, uint16, uint32, uint64)" {
  let w = PayloadWriter::new(capacity=128)
  w.write_int8(-128)
  w.write_int8(-1)
  w.write_int8(0)
  w.write_int8(127)
  w.write_int16(-32768)
  w.write_int16(-1)
  w.write_int16(32767)
  w.write_uint16(0U)
  w.write_uint16(65535U)
  w.write_int32(-2147483648)
  w.write_int32(-1)
  w.write_int32(2147483647)
  w.write_uint32(0xFFFFFFFFU)
  w.write_int64(-9223372036854775808L)
  w.write_int64(-1L)
  w.write_int64(9223372036854775807L)
  w.write_uint64(0xFFFFFFFFFFFFFFFFUL)

  let r = PayloadReader::new(w.to_bytes(), zero_extend=false)
  assert_eq(r.read_int8(), Ok(-128))
  assert_eq(r.read_int8(), Ok(-1))
  assert_eq(r.read_int8(), Ok(0))
  assert_eq(r.read_int8(), Ok(127))
  assert_eq(r.read_int16(), Ok(-32768))
  assert_eq(r.read_int16(), Ok(-1))
  assert_eq(r.read_int16(), Ok(32767))
  assert_eq(r.read_uint16(), Ok(0U))
  assert_eq(r.read_uint16(), Ok(65535U))
  assert_eq(r.read_int32(), Ok(-2147483648))
  assert_eq(r.read_int32(), Ok(-1))
  assert_eq(r.read_int32(), Ok(2147483647))
  assert_eq(r.read_uint32(), Ok(0xFFFFFFFFU))
  assert_eq(r.read_int64(), Ok(-9223372036854775808L))
  assert_eq(r.read_int64(), Ok(-1L))
  assert_eq(r.read_int64(), Ok(9223372036854775807L))
  assert_eq(r.read_uint64(), Ok(0xFFFFFFFFFFFFFFFFUL))
  assert_true(r.read_uint8() is Err(PayloadTooShort(_, _)))
}

///|
test "boundary: IEEE-754 Float and Double precision and negative zero bit-pattern preservation" {
  let w = PayloadWriter::new(capacity=64)
  let neg_zero_f = Float::reinterpret_from_uint(0x80000000U)
  w.write_float(neg_zero_f)
  w.write_float((3.4028234e38 : Float))
  w.write_double(-3.141592653589793)
  w.write_double(1.7976931348623157e308)

  let r = PayloadReader::new(w.to_bytes(), zero_extend=false)
  let f0 = match r.read_float() {
    Ok(v) => v
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(f0.reinterpret_as_uint(), 0x80000000U)
  assert_eq(r.read_float(), Ok((3.4028234e38 : Float)))
  assert_eq(r.read_double(), Ok(-3.141592653589793))
  assert_eq(r.read_double(), Ok(1.7976931348623157e308))
}

///|
test "boundary: FixedArray field short-padding and overlong-truncation safety in generated encoders" {
  // SetAttitudeTarget expects float[4] for `q`; pass only 2 elements -> last 2 padded with 0.0
  let sat_short : SetAttitudeTarget = {
    time_boot_ms: 100U,
    q: [(0.8 : Float), (0.6 : Float)],
    body_roll_rate: (0.0 : Float),
    body_pitch_rate: (0.0 : Float),
    body_yaw_rate: (0.0 : Float),
    thrust: (0.5 : Float),
    target_system: b'\x01',
    target_component: b'\x01',
    type_mask: b'\x00',
  }
  let decoded_short = match
    SetAttitudeTarget::decode_payload(
      sat_short.encode_payload(v2=true),
      v2=true,
    ) {
    Ok(d) => d
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(decoded_short.q, [
    (0.8 : Float),
    (0.6 : Float),
    (0.0 : Float),
    (0.0 : Float),
  ])

  // Pass 6 elements -> truncated to first 4 elements
  let sat_long : SetAttitudeTarget = {
    ..sat_short,
    q: [
      (1.0 : Float),
      (2.0 : Float),
      (3.0 : Float),
      (4.0 : Float),
      (5.0 : Float),
      (6.0 : Float),
    ],
  }
  let decoded_long = match
    SetAttitudeTarget::decode_payload(sat_long.encode_payload(v2=true), v2=true) {
    Ok(d) => d
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(decoded_long.q, [
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
  ])
}

///|
test "boundary: ParameterServer target_system filtering, broadcast (0), read by name, and unknown param" {
  let srv = ParameterServer::new(b'\x01', b'\x01', [
    ("BAT1_V_CHARGED", (4.20 : Float), b'\x09'),
    ("BAT1_N_CELLS", (4.0 : Float), b'\x09'),
  ])

  // Request addressed to sysid=2 should be ignored by sysid=1
  let ignored = srv.handle_message(
    MsgParamRequestList({ target_system: b'\x02', target_component: b'\x01', }),
  )
  assert_eq(ignored.length(), 0)

  // Broadcast request (target_system=0) should be answered
  let bcast = srv.handle_message(
    MsgParamRequestList({ target_system: b'\x00', target_component: b'\x00', }),
  )
  assert_eq(bcast.length(), 2)

  // Read by param_id when param_index == -1
  let by_name = srv.handle_message(
    MsgParamRequestRead({
      param_index: -1,
      target_system: b'\x01',
      target_component: b'\x01',
      param_id: "BAT1_N_CELLS",
    }),
  )
  assert_eq(by_name.length(), 1)
  match by_name[0] {
    MsgParamValue(pv) => {
      assert_eq(pv.param_id, "BAT1_N_CELLS")
      assert_eq(pv.param_index, 1U)
      assert_eq(pv.param_value, (4.0 : Float))
    }
    _ => fail("Expected MsgParamValue")
  }

  // Unknown param_id or out-of-range param_index returns empty array
  assert_eq(
    srv.handle_message(
      MsgParamRequestRead({
        param_index: 99,
        target_system: b'\x01',
        target_component: b'\x01',
        param_id: "",
      }),
    ),
    [],
  )
  assert_eq(
    srv.handle_message(
      MsgParamRequestRead({
        param_index: -1,
        target_system: b'\x01',
        target_component: b'\x01',
        param_id: "NON_EXISTENT",
      }),
    ),
    [],
  )
}

///|
test "boundary: MissionServer and MissionUploadClient empty mission (count=0) and out-of-order item rejection" {
  let srv = MissionServer::new(b'\x01', b'\x01')
  // Empty mission upload (count=0) immediately returns Accepted
  let empty_ack = srv.handle_message(
    b'\xff',
    b'\xbe',
    MsgMissionCount({
      count: 0U,
      target_system: b'\x01',
      target_component: b'\x01',
      mission_type: b'\x00',
      opaque_id: 0U,
    }),
  )
  assert_true(empty_ack is Some(MsgMissionAck(_)))

  // Start a 2-item upload, then send seq=1 instead of seq=0 -> InvalidSequence
  let _ = srv.handle_message(
    b'\xff',
    b'\xbe',
    MsgMissionCount({
      count: 2U,
      target_system: b'\x01',
      target_component: b'\x01',
      mission_type: b'\x00',
      opaque_id: 0U,
    }),
  )
  let bad_item : MissionItemInt = {
    param1: (0.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    x: 0,
    y: 0,
    z: (10.0 : Float),
    seq: 1U,
    command: 16U,
    target_system: b'\x01',
    target_component: b'\x01',
    frame: b'\x06',
    current: b'\x00',
    autocontinue: b'\x01',
    mission_type: b'\x00',
  }
  match srv.handle_message(b'\xff', b'\xbe', MsgMissionItemInt(bad_item)) {
    Some(MsgMissionAck(ack)) =>
      assert_eq(
        ack.mav_type,
        MavMissionResult::MavMissionInvalidSequence.to_uint().to_byte(),
      )
    _ => fail("Expected MsgMissionAck with InvalidSequence")
  }

  // Empty mission download (count=0) on MissionDownloadClient
  let dl = MissionDownloadClient::new(b'\x01', b'\x01')
  let _ = dl.start_download(100UL)
  let dl_ack = dl.on_message(
    MsgMissionCount({
      count: 0U,
      target_system: b'\xff',
      target_component: b'\xbe',
      mission_type: b'\x00',
      opaque_id: 0U,
    }),
    150UL,
  )
  assert_true(dl_ack is Some(MsgMissionAck(_)))
  assert_eq(dl.state, Completed)
}

///|
test "fuzz: 1024-byte pseudo-random corrupted stream with false 0xFD/0xFE magic bytes followed by signed frame" {
  let fuzz_buf : Array[Byte] = Array(capacity=1100)
  let mut seed = 0xCAFEBABEU
  for i = 0; i < 1024; i = i + 1 {
    seed = seed * 1664525U + 1013904223U
    if i % 37 == 0 {
      fuzz_buf.push(b'\xFD')
    } else if i % 53 == 0 {
      fuzz_buf.push(b'\xFE')
    } else {
      fuzz_buf.push(((seed >> 16) & 0xFFU).to_byte())
    }
  }
  // Ensure the last false header in fuzz_buf cannot treat our real signed frame as its payload
  for i = 0; i < 280; i = i + 1 {
    fuzz_buf.push(b'\x00')
  }

  let key = b"0123456789abcdef0123456789abcdef"
  let tx_sign = match
    SigningContext::new(key, link_id=b'\x03', initial_timestamp=50000UL) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  let rx_sign = match
    SigningContext::new(key, link_id=b'\x03', initial_timestamp=40000UL) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  let hb : Heartbeat = {
    custom_mode: 0x00040000U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\xd1',
    system_status: b'\x04',
    mavlink_version: b'\x03',
  }
  let (signed_wire, _) = match
    MsgHeartbeat(hb).encode_to_frame(
      seq=b'\x42',
      sysid=b'\x01',
      compid=b'\x01',
      signing=Some(tx_sign),
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  for i = 0; i < signed_wire.length(); i = i + 1 {
    fuzz_buf.push(signed_wire[i])
  }

  let parser = FrameParser::new()
  let events = parser.push_bytes(
    Bytes::from_array(fuzz_buf),
    lookup_message_crc_extra,
    signing=Some(rx_sign),
  )
  let valid_frames : Array[MavFrame] = []
  for ev in events {
    match ev {
      FrameDecoded(f) => valid_frames.push(f)
      FrameError(_) => ()
    }
  }
  assert_eq(valid_frames.length(), 1)
  assert_eq(valid_frames[0].header.seq, b'\x42')
  assert_eq(
    MavMessage::decode_from_frame(valid_frames[0]),
    Ok(MsgHeartbeat(hb)),
  )
}

///|
test "benchmark: MAVLink v1 vs v2 wire efficiency crossover verification" {
  let cmp = evaluate_v1_vs_v2_efficiency()
  assert_eq(cmp.total_frames, 100)
  assert_eq(cmp.v1_total_wire_bytes, 4125)
  assert_eq(cmp.v2_total_wire_bytes, 3580)
  assert_eq(cmp.net_v2_wire_saved_bytes, 545)
  assert_true(cmp.v2_vs_v1_reduction_pct > 13.0)
}

///|
test "benchmark: 100-frame SHA-256 signing and 50-attack anti-replay security audit" {
  let sec = evaluate_signing_security_audit()
  assert_eq(sec.valid_signed_transmitted, 100)
  assert_eq(sec.valid_signed_accepted, 100)
  assert_eq(sec.attack_frames_injected, 50)
  assert_eq(sec.attack_frames_rejected, 50)
  assert_eq(sec.unsigned_wire_bytes, 2450)
  assert_eq(sec.signed_wire_bytes, 3750)
  assert_true(sec.signing_overhead_pct > 53.0)
}

///|
test "boundary: PayloadReader read_char_array with embedded NUL stops string at NUL while advancing full fixed_len" {
  let w = PayloadWriter::new(capacity=32)
  // Write a 16-byte char array containing an embedded NUL followed by garbage bytes, then a uint32 trailer
  let raw_str_bytes = b"ALT_MAX\x00GARBAGE!"
  w.write_bytes(raw_str_bytes)
  w.write_uint32(0x12345678U)

  let r = PayloadReader::new(w.to_bytes(), zero_extend=false)
  assert_eq(r.read_char_array(16), Ok("ALT_MAX"))
  assert_eq(r.pos, 16)
  assert_eq(r.read_uint32(), Ok(0x12345678U))
}

///|
test "boundary: X25Crc empty buffer, byte-by-byte, slice, and ASCII accumulation equivalence" {
  let c_empty = X25Crc::new()
  c_empty.accumulate_bytes(b"")
  assert_eq(c_empty.value, 0xFFFFU)

  let c_ascii = X25Crc::new()
  c_ascii.accumulate_ascii("HEARTBEAT ")
  let c_bytes = X25Crc::new()
  c_bytes.accumulate_bytes(b"HEARTBEAT ")
  let c_slice = X25Crc::new()
  let padded = b"__HEARTBEAT __"
  c_slice.accumulate_bytes(padded, start=2, len=10)
  assert_eq(c_ascii.value, c_bytes.value)
  assert_eq(c_ascii.value, c_slice.value)
}

///|
test "boundary: XML parser auto-increment enum entries, single quotes, and XML entity unescaping" {
  let xml =
    #|<?xml version='1.0'?>
    #|<mavlink>
    #|  <enums>
    #|    <enum name='GIMBAL_AXIS'>
    #|      <description>Axis &lt;0..2&gt; &amp; &quot;roll/pitch/yaw&quot; &apos;test&apos;</description>
    #|      <entry name='GIMBAL_AXIS_ROLL'/>
    #|      <entry value='0x10' name='GIMBAL_AXIS_PITCH'/>
    #|      <entry name='GIMBAL_AXIS_YAW'/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id='0x100' name='GIMBAL_REPORT'>
    #|      <field type='uint8_t' name='axis' enum='GIMBAL_AXIS'>Axis</field>
    #|    </message>
    #|  </messages>
    #|</mavlink>
  let schema = match parse_dialect_xml(xml) {
    Ok(s) => s
    Err(e) => fail(e.to_repr().to_string())
  }
  assert_eq(schema.enums.length(), 1)
  let en = schema.enums[0]
  assert_eq(en.description, "Axis <0..2> & \"roll/pitch/yaw\" 'test'")
  assert_eq(en.entries[0].value, 0U)
  assert_eq(en.entries[1].value, 16U)
  assert_eq(en.entries[2].value, 17U)
  assert_eq(schema.messages[0].id, 256U)
}

///|
test "boundary: XML parser rejects unclosed comment, unclosed PI, and missing field attributes" {
  assert_true(
    parse_dialect_xml("<?xml version=\"1.0\"<mavlink/>")
    is Err(XmlParseError(_)),
  )
  assert_true(
    parse_dialect_xml("<!-- unclosed comment <mavlink/>")
    is Err(XmlParseError(_)),
  )
  assert_true(
    parse_dialect_xml(
      "<mavlink><messages><message id=\"1\" name=\"M\"><field name=\"x\"/></message></messages></mavlink>",
    )
    is Err(XmlParseError(_)),
  )
  assert_true(
    parse_dialect_xml(
      "<mavlink><messages><message id=\"1\" name=\"M\"><field type=\"uint8_t\"/></message></messages></mavlink>",
    )
    is Err(XmlParseError(_)),
  )
}

///|
test "boundary: MissionUploadClient transitions to Failed on non-zero MISSION_ACK error codes" {
  let uploader = MissionUploadClient::new(b'\x01', b'\x01')
  let wp : MissionItemInt = {
    param1: (0.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    x: 0,
    y: 0,
    z: (15.0 : Float),
    seq: 0U,
    command: 16U,
    target_system: b'\x01',
    target_component: b'\x01',
    frame: b'\x06',
    current: b'\x01',
    autocontinue: b'\x01',
    mission_type: b'\x00',
  }
  let _ = uploader.start_upload([wp], 100UL)
  let _ = uploader.on_message(
    MsgMissionAck({
      target_system: b'\xff',
      target_component: b'\xbe',
      mav_type: MavMissionResult::MavMissionNoSpace.to_uint().to_byte(),
      mission_type: b'\x00',
      opaque_id: 0U,
    }),
    150UL,
  )
  assert_eq(uploader.state, Failed(MavMissionNoSpace))
}

///|
test "boundary: CommandClient ignores COMMAND_ACK for unrelated command IDs" {
  let cli = CommandClient::new(b'\x01', b'\x01')
  let _ = cli.send_command_long(400U, 1000UL)
  // Unrelated COMMAND_ACK for command=512 should be ignored
  cli.on_command_ack(
    {
      command: 512U,
      result: MavResult::Accepted.to_uint().to_byte(),
      progress: b'\x00',
      result_param2: 0,
      target_system: b'\xff',
      target_component: b'\xbe',
    },
    1050UL,
  )
  assert_eq(cli.state, Pending(400U, b'\x00'))
}

///|
test "boundary: HeartbeatMonitor multi-vehicle fleet isolation (sysid=1, sysid=2, sysid=255)" {
  let mon = HeartbeatMonitor::new(timeout_ms=1000UL)
  let hb1 : Heartbeat = {
    custom_mode: 1U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\xd1',
    system_status: b'\x04',
    mavlink_version: b'\x03',
  }
  let hb2 : Heartbeat = { ..hb1, custom_mode: 2U, base_mode: b'\x51', }
  let (_, f_uav1) = match
    MsgHeartbeat(hb1).encode_to_frame(
      seq=b'\x01',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  let (_, f_uav2) = match
    MsgHeartbeat(hb2).encode_to_frame(
      seq=b'\x10',
      sysid=b'\x02',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(e) => fail(e.to_repr().to_string())
  }
  mon.on_frame(f_uav1, 100UL)
  mon.on_frame(f_uav2, 800UL)

  // At t=1200ms, UAV1 (last seen 100ms) is timed out, while UAV2 (last seen 800ms) is alive
  assert_eq(mon.is_node_alive(b'\x01', b'\x01', 1200UL), false)
  assert_eq(mon.is_node_alive(b'\x02', b'\x01', 1200UL), true)
  assert_eq(mon.is_node_alive(b'\x99', b'\x01', 1200UL), false)
}
