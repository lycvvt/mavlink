///|
fn main {
  println("==================================================================")
  println("  MAVLink v2 Multi-Link Router, FTP Server & QGC .tlog Replay")
  println("==================================================================")

  // 1. Multi-Link Router (Port 0: PX4 1:1, Port 1: Camera 1:100, Port 2: QGC 255:190)
  let router = @mavlink.MavRouter::new([0, 1, 2])
  let tlog = @mavlink.TlogRecorder::new()

  let hb_ap = @mavlink.MavMessage::MsgHeartbeat({
    custom_mode: 0x00040000U,
    mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
    autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
    base_mode: b'\xd1',
    system_status: @mavlink.MavState::Active.to_uint().to_byte(),
    mavlink_version: b'\x03',
  })
  let (w_ap, f_ap) = match
    hb_ap.encode_to_frame(seq=b'\x00', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(_) => return
  }
  let egress_ap = router.route_frame(0, f_ap)
  tlog.record_wire_frame(1730800000000000UL, w_ap)

  let hb_cam = @mavlink.MavMessage::MsgHeartbeat({
    custom_mode: 0U,
    mav_type: @mavlink.MavType::Generic.to_uint().to_byte(),
    autopilot: @mavlink.MavAutopilot::Invalid.to_uint().to_byte(),
    base_mode: b'\x00',
    system_status: @mavlink.MavState::Active.to_uint().to_byte(),
    mavlink_version: b'\x03',
  })
  let (w_cam, f_cam) = match
    hb_cam.encode_to_frame(seq=b'\x00', sysid=b'\x01', compid=b'\x64') {
    Ok(r) => r
    Err(_) => return
  }
  let _ = router.route_frame(1, f_cam)
  tlog.record_wire_frame(1730800000250000UL, w_cam)

  // QGC on port 2 sends PARAM_EXT_REQUEST_LIST targeting Camera (1:100) -> routed only to port 1
  let ext_req = @mavlink.MavMessage::MsgParamExtRequestList({
    target_system: b'\x01',
    target_component: b'\x64',
  })
  let (w_req, f_req) = match
    ext_req.encode_to_frame(seq=b'\x01', sysid=b'\xff', compid=b'\xbe') {
    Ok(r) => r
    Err(_) => return
  }
  let egress_unicast = router.route_frame(2, f_req)
  tlog.record_wire_frame(1730800000500000UL, w_req)
  println(
    "[1/3] MavRouter: broadcast egress ports=\{egress_ap.length()} (ports 1 & 2), camera unicast egress port=\{egress_unicast[0]}",
  )

  // 2. Virtual Onboard FTP Server (#110) file read
  let ftp_srv = @mavlink.FtpServer::new([
    (
      "/fs/microsd/mission.plan", b"QGC WPL 110\n0\t1\t0\t16\t0\t0\t0\t0\t22.543\t114.057\t50\t1\n",
    ),
  ])
  let _ = ftp_srv.handle_packet({
    seq_number: 1U,
    session: b'\x00',
    opcode: @mavlink.FtpOpcode::OpenFileRO,
    req_opcode: @mavlink.FtpOpcode::FtpNone,
    burst_complete: false,
    offset: 0U,
    data: b"/fs/microsd/mission.plan",
  })
  let read_ack = ftp_srv.handle_packet({
    seq_number: 2U,
    session: b'\x01',
    opcode: @mavlink.FtpOpcode::ReadFile,
    req_opcode: @mavlink.FtpOpcode::FtpNone,
    burst_complete: false,
    offset: 0U,
    data: b"",
  })
  println(
    "[2/3] FtpServer (#110): read \{read_ack.data.length()} bytes from /fs/microsd/mission.plan (burst_complete=\{read_ack.burst_complete})",
  )

  // 3. Replay recorded QGroundControl .tlog binary stream
  let raw_tlog = tlog.to_bytes()
  match
    @mavlink.decode_tlog_stream(raw_tlog, @mavlink.lookup_message_crc_extra) {
    Ok(entries) => {
      let hbs = @mavlink.filter_tlog_by_msgid(entries, 0U)
      println(
        "[3/3] QGC .tlog Replay: decoded \{entries.length()} timestamped frames (\{raw_tlog.length()} bytes, \{hbs.length()} HEARTBEAT entries)",
      )
    }
    Err(e) => println("Tlog error: \{e.to_repr()}")
  }
}
