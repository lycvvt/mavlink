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
