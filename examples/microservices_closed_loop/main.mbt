///|
fn main {
  println("==================================================================")
  println("  MAVLink v2 Microservices Closed-Loop Simulation (GCS <-> UAV)")
  println("==================================================================")

  // 1. HeartbeatMonitor tracking multi-node link health
  let monitor = @mavlink.HeartbeatMonitor::new(timeout_ms=3000UL)
  let hb = @mavlink.MavMessage::MsgHeartbeat({
    custom_mode: 0x00040000U,
    mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
    autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
    base_mode: b'\xd1',
    system_status: @mavlink.MavState::Active.to_uint().to_byte(),
    mavlink_version: b'\x03',
  })
  let (_, f0) = match
    hb.encode_to_frame(seq=b'\x00', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(_) => return
  }
  let (_, f3) = match
    hb.encode_to_frame(seq=b'\x03', sysid=b'\x01', compid=b'\x01') {
    Ok(r) => r
    Err(_) => return
  }
  monitor.on_frame(f0, 1000UL)
  monitor.on_frame(f3, 2000UL)
  let alive = monitor.is_node_alive(b'\x01', b'\x01', 3500UL)
  let loss = monitor.node_packet_loss_ratio(b'\x01', b'\x01')
  println(
    "[1/4] HeartbeatMonitor: UAV (1:1) alive=\{alive}, armed=true, packet_loss=\{loss * 100.0}%",
  )

  // 2. ParameterClient <-> ParameterServer with simulated drop & gap recovery
  let param_srv = @mavlink.ParameterServer::new(b'\x01', b'\x01', [
    ("MPC_THR_HOVER", (0.52 : Float), b'\x09'),
    ("MPC_XY_VEL_MAX", (12.0 : Float), b'\x09'),
    ("MPC_Z_VEL_MAX_UP", (3.0 : Float), b'\x09'),
  ])
  let param_cli = @mavlink.ParameterClient::new(
    b'\x01',
    b'\x01',
    timeout_ms=500UL,
  )
  let list_req = param_cli.start_list_sync(1000UL)
  let srv_replies = param_srv.handle_message(list_req)
  // Deliver index 0 and index 2, simulating radio drop of index 1
  match srv_replies[0] {
    MsgParamValue(pv0) => param_cli.on_param_value(pv0, 1020UL)
    _ => ()
  }
  match srv_replies[2] {
    MsgParamValue(pv2) => param_cli.on_param_value(pv2, 1040UL)
    _ => ()
  }
  // Timeout poll detects missing index 1 and emits targeted PARAM_REQUEST_READ
  match param_cli.poll_timeout(1600UL) {
    Some(read_req) => {
      let recovered = param_srv.handle_message(read_req)
      match recovered[0] {
        MsgParamValue(pv1) => param_cli.on_param_value(pv1, 1620UL)
        _ => ()
      }
    }
    None => ()
  }
  println(
    "[2/4] Parameter Service: state=\{param_cli.state.to_repr()}, synced \{param_cli.params.length()} parameters after gap recovery",
  )

  // 3. CommandClient with timeout retry (confirmation increment) and IN_PROGRESS -> ACCEPTED
  let cmd_cli = @mavlink.CommandClient::new(b'\x01', b'\x01', timeout_ms=500UL)
  let _ = cmd_cli.send_command_long(400U, 2000UL, param1=(1.0 : Float))
  let retry_msg = cmd_cli.poll_timeout(2600UL)
  let retry_conf = match retry_msg {
    Some(MsgCommandLong(c)) => c.confirmation.to_int()
    _ => -1
  }
  cmd_cli.on_command_ack(
    {
      command: 400U,
      result: @mavlink.MavResult::InProgress.to_uint().to_byte(),
      progress: b'\x32',
      result_param2: 0,
      target_system: b'\xff',
      target_component: b'\xbe',
    },
    2650UL,
  )
  cmd_cli.on_command_ack(
    {
      command: 400U,
      result: @mavlink.MavResult::Accepted.to_uint().to_byte(),
      progress: b'\x64',
      result_param2: 0,
      target_system: b'\xff',
      target_component: b'\xbe',
    },
    2800UL,
  )
  println(
    "[3/4] Command Service: retry confirmation=\{retry_conf}, final state=\{cmd_cli.state.to_repr()}",
  )

  // 4. Two-way TIMESYNC (#111) RTT and Clock Offset Estimation
  let ts_est = @mavlink.TimesyncEstimator::new()
  let probe = @mavlink.TimesyncEstimator::create_probe(1_000_000_000L)
  match probe {
    MsgTimesync(p) =>
      match
        @mavlink.TimesyncEstimator::respond_to_probe(
          p, 1_052_000_000L, b'\xff', b'\xbe',
        ) {
        Some(MsgTimesync(reply)) =>
          match ts_est.on_probe_return(reply, 1_004_000_000L) {
            Some(sample) =>
              println(
                "[4/4] Timesync Estimator: RTT=\{sample.rtt_ns / 1_000_000L} ms, clock_offset=\{sample.clock_offset_ns / 1_000_000L} ms",
              )
            None => ()
          }
        _ => ()
      }
    _ => ()
  }
}
