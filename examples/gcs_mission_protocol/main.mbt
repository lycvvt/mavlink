///|
fn main {
  println(
    "=== Example 2: GCS <-> UAV Waypoint Mission Upload & Signed Control ===",
  )
  let waypoints : Array[@mavlink.MissionItemInt] = [
    {
      target_system: b'\x01',
      target_component: b'\x01',
      seq: 0U,
      frame: @mavlink.MavCoordFrame::GlobalRelativeAltInt.to_uint().to_byte(),
      command: @mavlink.MavCmd::NavTakeoff.to_uint(),
      current: b'\x01',
      autocontinue: b'\x01',
      param1: (0.0 : Float),
      param2: (0.0 : Float),
      param3: (0.0 : Float),
      param4: (0.0 : Float),
      x: 225430960,
      y: 1140578650,
      z: (25.0 : Float),
      mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    },
    {
      target_system: b'\x01',
      target_component: b'\x01',
      seq: 1U,
      frame: @mavlink.MavCoordFrame::GlobalRelativeAltInt.to_uint().to_byte(),
      command: @mavlink.MavCmd::NavWaypoint.to_uint(),
      current: b'\x00',
      autocontinue: b'\x01',
      param1: (5.0 : Float),
      param2: (2.0 : Float),
      param3: (0.0 : Float),
      param4: (90.0 : Float),
      x: 225445000,
      y: 1140592000,
      z: (30.0 : Float),
      mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    },
    {
      target_system: b'\x01',
      target_component: b'\x01',
      seq: 2U,
      frame: @mavlink.MavCoordFrame::GlobalRelativeAltInt.to_uint().to_byte(),
      command: @mavlink.MavCmd::NavReturnToLaunch.to_uint(),
      current: b'\x00',
      autocontinue: b'\x01',
      param1: (0.0 : Float),
      param2: (0.0 : Float),
      param3: (0.0 : Float),
      param4: (0.0 : Float),
      x: 0,
      y: 0,
      z: (0.0 : Float),
      mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    },
  ]

  // 1. GCS initiates upload with MISSION_COUNT
  let count_msg : @mavlink.MissionCount = {
    target_system: b'\x01',
    target_component: b'\x01',
    count: waypoints.length().reinterpret_as_uint(),
    mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    opaque_id: 2026U,
  }
  let (count_wire, _) = match
    @mavlink.MavMessage::MsgMissionCount(count_msg).encode_to_frame(
      seq=b'\x00',
      sysid=b'\xFF',
      compid=b'\xBE',
    ) {
    Ok(r) => r
    Err(_) => return
  }
  println(
    "[GCS -> UAV] MISSION_COUNT: count=\{count_msg.count}, opaque_id=\{count_msg.opaque_id} (\{count_wire.length()}B wire)",
  )

  // 2. UAV requests each waypoint via MISSION_REQUEST_INT and GCS responds with MISSION_ITEM_INT
  for idx = 0; idx < waypoints.length(); idx = idx + 1 {
    let req : @mavlink.MissionRequestInt = {
      target_system: b'\xFF',
      target_component: b'\xBE',
      seq: idx.reinterpret_as_uint(),
      mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    }
    let (req_wire, _) = match
      @mavlink.MavMessage::MsgMissionRequestInt(req).encode_to_frame(
        seq=idx.to_byte(),
        sysid=b'\x01',
        compid=b'\x01',
      ) {
      Ok(r) => r
      Err(_) => return
    }
    let (req_frame, _) = match
      @mavlink.decode_frame(req_wire, @mavlink.lookup_message_crc_extra) {
      Ok(r) => r
      Err(_) => return
    }
    match @mavlink.MavMessage::decode_from_frame(req_frame) {
      Ok(@mavlink.MavMessage::MsgMissionRequestInt(r)) => {
        let wp = waypoints[r.seq.reinterpret_as_int()]
        let (wp_wire, wp_frame) = match
          @mavlink.MavMessage::MsgMissionItemInt(wp).encode_to_frame(
            seq=(idx + 1).to_byte(),
            sysid=b'\xFF',
            compid=b'\xBE',
          ) {
          Ok(res) => res
          Err(_) => return
        }
        println(
          "[UAV -> GCS] MISSION_REQUEST_INT(seq=\{r.seq}) -> [GCS -> UAV] MISSION_ITEM_INT(cmd=\{wp.command}, alt=\{wp.z}m, payload=\{wp_frame.payload.length()}B/\{@mavlink.MissionItemInt::max_payload_len()}B, wire=\{wp_wire.length()}B)",
        )
      }
      _ => ()
    }
  }

  // 3. UAV finishes transaction with MISSION_ACK
  let ack : @mavlink.MissionAck = {
    target_system: b'\xFF',
    target_component: b'\xBE',
    mav_type: @mavlink.MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
    mission_type: @mavlink.MavMissionType::Mission.to_uint().to_byte(),
    opaque_id: 2026U,
  }
  let (ack_wire, _) = match
    @mavlink.MavMessage::MsgMissionAck(ack).encode_to_frame(
      seq=b'\x04',
      sysid=b'\x01',
      compid=b'\x01',
    ) {
    Ok(r) => r
    Err(_) => return
  }
  let (ack_frame, _) = match
    @mavlink.decode_frame(ack_wire, @mavlink.lookup_message_crc_extra) {
    Ok(r) => r
    Err(_) => return
  }
  match @mavlink.MavMessage::decode_from_frame(ack_frame) {
    Ok(@mavlink.MavMessage::MsgMissionAck(a)) =>
      println(
        "[UAV -> GCS] MISSION_ACK: result=\{a.mav_type.to_int()} (ACCEPTED), opaque_id=\{a.opaque_id}",
      )
    _ => ()
  }
}
