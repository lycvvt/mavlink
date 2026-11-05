///|
fn main {
  println("=== Example 1: PX4 Quadrotor High-Rate Telemetry Stream ===")
  let frames : Array[@mavlink.MavMessage] = [
    @mavlink.MavMessage::MsgHeartbeat({
      mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
      autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
      base_mode: (@mavlink.MavModeFlag::CustomModeEnabled.to_uint() |
      @mavlink.MavModeFlag::AutoEnabled.to_uint() |
      @mavlink.MavModeFlag::SafetyArmed.to_uint()).to_byte(),
      custom_mode: 0x04040000U,
      system_status: @mavlink.MavState::Active.to_uint().to_byte(),
      mavlink_version: b'\x03',
    }),
    @mavlink.MavMessage::MsgSysStatus({
      onboard_control_sensors_present: 0x0000FC3FU,
      onboard_control_sensors_enabled: 0x0000FC3FU,
      onboard_control_sensors_health: 0x0000FC3FU,
      load: 325U,
      voltage_battery: 16200U,
      current_battery: 1850,
      battery_remaining: 84,
      drop_rate_comm: 0U,
      errors_comm: 0U,
      errors_count1: 0U,
      errors_count2: 0U,
      errors_count3: 0U,
      errors_count4: 0U,
    }),
    @mavlink.MavMessage::MsgAttitude({
      time_boot_ms: 10240U,
      roll: (0.032 : Float),
      pitch: (-0.018 : Float),
      yaw: (1.5708 : Float),
      rollspeed: (0.005 : Float),
      pitchspeed: (-0.002 : Float),
      yawspeed: (0.01 : Float),
    }),
    @mavlink.MavMessage::MsgLocalPositionNed({
      time_boot_ms: 10240U,
      x: (125.4 : Float),
      y: (48.2 : Float),
      z: (-30.0 : Float),
      vx: (5.2 : Float),
      vy: (1.1 : Float),
      vz: (0.0 : Float),
    }),
    @mavlink.MavMessage::MsgRcChannelsRaw({
      time_boot_ms: 10240U,
      port: b'\x00',
      chan1_raw: 1500U,
      chan2_raw: 1500U,
      chan3_raw: 1680U,
      chan4_raw: 1500U,
      chan5_raw: 1900U,
      chan6_raw: 1100U,
      chan7_raw: 1500U,
      chan8_raw: 1500U,
      rssi: (210).to_byte(),
    }),
  ]

  let stream_bytes : Array[Byte] = [b'\xAA', b'\x55']
  for i = 0; i < frames.length(); i = i + 1 {
    match
      frames[i].encode_to_frame(seq=i.to_byte(), sysid=b'\x01', compid=b'\x01') {
      Ok((wire, _)) =>
        for j = 0; j < wire.length(); j = j + 1 {
          stream_bytes.push(wire[j])
        }
      Err(_) => ()
    }
  }

  let parser = @mavlink.FrameParser::new()
  let events = parser.push_bytes(
    Bytes::from_array(stream_bytes),
    @mavlink.lookup_message_crc_extra,
  )
  for ev in events {
    match ev {
      @mavlink.ParseStreamEvent::FrameDecoded(f) =>
        match @mavlink.MavMessage::decode_from_frame(f) {
          Ok(@mavlink.MavMessage::MsgHeartbeat(hb)) =>
            println(
              "[HEARTBEAT] sysid=\{f.header.sysid.to_int()} mode=0x\{hb.custom_mode} status=\{hb.system_status.to_int()}",
            )
          Ok(@mavlink.MavMessage::MsgSysStatus(ss)) =>
            println(
              "[SYS_STATUS] battery=\{ss.voltage_battery}mV (\{ss.battery_remaining}%), CPU load=\{ss.load}/1000",
            )
          Ok(@mavlink.MavMessage::MsgAttitude(att)) =>
            println(
              "[ATTITUDE] t=\{att.time_boot_ms}ms roll=\{att.roll}rad pitch=\{att.pitch}rad yaw=\{att.yaw}rad",
            )
          Ok(@mavlink.MavMessage::MsgLocalPositionNed(ned)) =>
            println(
              "[LOCAL_POSITION_NED] N=\{ned.x}m E=\{ned.y}m D=\{ned.z}m (vx=\{ned.vx}m/s)",
            )
          Ok(@mavlink.MavMessage::MsgRcChannelsRaw(rc)) =>
            println(
              "[RC_CHANNELS_RAW] ch1=\{rc.chan1_raw}us ch3(thr)=\{rc.chan3_raw}us rssi=\{rc.rssi.to_int()}",
            )
          _ => ()
        }
      _ => ()
    }
  }
  println(
    "Telemetry summary: received=\{parser.packets_received}, dropped=\{parser.packets_dropped}, noise_skipped=\{parser.noise_bytes_skipped}B",
  )
}
