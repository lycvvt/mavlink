///|
/// Per-node link health and telemetry status tracked by `HeartbeatMonitor`.
pub(all) struct NodeLinkStatus {
  sysid : Byte
  compid : Byte
  mut mav_type : Byte
  mut autopilot : Byte
  mut base_mode : Byte
  mut custom_mode : UInt32
  mut system_status : Byte
  mut armed : Bool
  mut last_seen_ms : UInt64
  mut heartbeat_count : Int32
  mut received_frames : Int32
  mut dropped_frames : Int32
  mut last_seq : Int32
} derive(Eq, Debug)

///|
pub extend NodeLinkStatus with Eq::{not_equal, equal}

///|
pub extend NodeLinkStatus with @debug.Debug::{to_repr}

///|
/// Multi-node MAVLink v2 heartbeat and link quality monitor.
pub(all) struct HeartbeatMonitor {
  timeout_ms : UInt64
  nodes : Array[NodeLinkStatus]
} derive(Eq, Debug)

///|
pub extend HeartbeatMonitor with Eq::{not_equal, equal}

///|
pub extend HeartbeatMonitor with @debug.Debug::{to_repr}

///|
/// Create a new `HeartbeatMonitor` with a configurable link timeout in milliseconds (default 3000 ms).
pub fn HeartbeatMonitor::new(timeout_ms~ : UInt64 = 3000UL) -> HeartbeatMonitor {
  { timeout_ms, nodes: [], }
}

///|
fn find_or_create_node(
  monitor : HeartbeatMonitor,
  sysid : Byte,
  compid : Byte,
  now_ms : UInt64,
) -> Int32 {
  for i = 0; i < monitor.nodes.length(); i = i + 1 {
    if monitor.nodes[i].sysid == sysid && monitor.nodes[i].compid == compid {
      return i
    }
  }
  monitor.nodes.push({
    sysid,
    compid,
    mav_type: b'\x00',
    autopilot: b'\x00',
    base_mode: b'\x00',
    custom_mode: 0U,
    system_status: b'\x00',
    armed: false,
    last_seen_ms: now_ms,
    heartbeat_count: 0,
    received_frames: 0,
    dropped_frames: 0,
    last_seq: -1,
  })
  monitor.nodes.length() - 1
}

///|
/// Record any incoming `MavFrame` to update sequence-gap packet loss statistics
/// and automatically extract `HEARTBEAT` (#0) state when present.
pub fn HeartbeatMonitor::on_frame(
  self : HeartbeatMonitor,
  frame : MavFrame,
  now_ms : UInt64,
) -> Unit {
  let idx = find_or_create_node(
    self,
    frame.header.sysid,
    frame.header.compid,
    now_ms,
  )
  let node = self.nodes[idx]
  node.last_seen_ms = now_ms
  node.received_frames = node.received_frames + 1
  let cur_seq = frame.header.seq.to_int() & 0xFF
  if node.last_seq >= 0 {
    let expected = (node.last_seq + 1) & 0xFF
    if cur_seq != expected {
      let gap = (cur_seq - expected + 256) & 0xFF
      node.dropped_frames = node.dropped_frames + gap
    }
  }
  node.last_seq = cur_seq

  if frame.header.msgid == 0U {
    match
      Heartbeat::decode_payload(frame.payload, v2=frame.header.version == V2) {
      Ok(hb) => {
        node.mav_type = hb.mav_type
        node.autopilot = hb.autopilot
        node.base_mode = hb.base_mode
        node.custom_mode = hb.custom_mode
        node.system_status = hb.system_status
        node.armed = (hb.base_mode.to_int() & 0x80) != 0
        node.heartbeat_count = node.heartbeat_count + 1
      }
      Err(_) => ()
    }
  }
}

///|
/// Check whether a specific `(sysid, compid)` node is currently alive within `timeout_ms`.
pub fn HeartbeatMonitor::is_node_alive(
  self : HeartbeatMonitor,
  sysid : Byte,
  compid : Byte,
  now_ms : UInt64,
) -> Bool {
  for node in self.nodes {
    if node.sysid == sysid && node.compid == compid {
      return now_ms >= node.last_seen_ms &&
        now_ms - node.last_seen_ms <= self.timeout_ms &&
        node.heartbeat_count > 0
    }
  }
  false
}

///|
/// Look up the current `NodeLinkStatus` for `(sysid, compid)`.
pub fn HeartbeatMonitor::get_node(
  self : HeartbeatMonitor,
  sysid : Byte,
  compid : Byte,
) -> NodeLinkStatus? {
  for node in self.nodes {
    if node.sysid == sysid && node.compid == compid {
      return Some(node)
    }
  }
  None
}

///|
/// Compute the packet loss ratio (`0.0 .. 1.0`) for `(sysid, compid)`.
pub fn HeartbeatMonitor::node_packet_loss_ratio(
  self : HeartbeatMonitor,
  sysid : Byte,
  compid : Byte,
) -> Double {
  for node in self.nodes {
    if node.sysid == sysid && node.compid == compid {
      let total = node.received_frames + node.dropped_frames
      if total <= 0 {
        return 0.0
      }
      return node.dropped_frames.to_double() / total.to_double()
    }
  }
  0.0
}

// ============================================================================
// 2. Parameter Protocol Microservice (Client & Server)
// ============================================================================

///|
/// Onboard parameter entry stored in `ParameterServer` or `ParameterClient`.
pub(all) struct ParameterEntry {
  param_id : String
  mut param_value : Float
  param_type : Byte
  param_index : UInt32
} derive(Eq, Debug)

///|
pub extend ParameterEntry with Eq::{not_equal, equal}

///|
pub extend ParameterEntry with @debug.Debug::{to_repr}

///|
/// State of the `ParameterClient` synchronization state machine.
pub(all) enum ParamSyncState {
  Idle
  ListingAll
  WritingParam(String, Float, Byte)
  Synced
  Failed(String)
} derive(Eq, Debug)

///|
pub extend ParamSyncState with Eq::{not_equal, equal}

///|
pub extend ParamSyncState with @debug.Debug::{to_repr}

///|
/// GCS-side MAVLink Parameter Protocol client supporting full list synchronization,
/// missing index gap recovery, and verified `PARAM_SET` transactions.
pub(all) struct ParameterClient {
  target_system : Byte
  target_component : Byte
  timeout_ms : UInt64
  max_retries : Int32
  mut state : ParamSyncState
  mut expected_count : Int32
  mut last_action_ms : UInt64
  mut retries : Int32
  params : Array[ParameterEntry]
} derive(Eq, Debug)

///|
pub extend ParameterClient with Eq::{not_equal, equal}

///|
pub extend ParameterClient with @debug.Debug::{to_repr}

///|
/// Create a new `ParameterClient` targeting `(target_system, target_component)`.
pub fn ParameterClient::new(
  target_system : Byte,
  target_component : Byte,
  timeout_ms~ : UInt64 = 1000UL,
  max_retries~ : Int32 = 3,
) -> ParameterClient {
  {
    target_system,
    target_component,
    timeout_ms,
    max_retries,
    state: Idle,
    expected_count: -1,
    last_action_ms: 0UL,
    retries: 0,
    params: [],
  }
}

///|
/// Initiate a full parameter list download (`PARAM_REQUEST_LIST` #21).
pub fn ParameterClient::start_list_sync(
  self : ParameterClient,
  now_ms : UInt64,
) -> MavMessage {
  self.state = ListingAll
  self.expected_count = -1
  self.last_action_ms = now_ms
  self.retries = 0
  self.params.clear()
  MsgParamRequestList({
    target_system: self.target_system,
    target_component: self.target_component,
  })
}

///|
/// Initiate a verified parameter write transaction (`PARAM_SET` #23).
pub fn ParameterClient::start_param_set(
  self : ParameterClient,
  param_id : String,
  param_value : Float,
  param_type : Byte,
  now_ms : UInt64,
) -> MavMessage {
  self.state = WritingParam(param_id, param_value, param_type)
  self.last_action_ms = now_ms
  self.retries = 0
  MsgParamSet({
    param_value,
    target_system: self.target_system,
    target_component: self.target_component,
    param_id,
    param_type,
  })
}

///|
/// Process an incoming `PARAM_VALUE` (#22) message from the vehicle.
pub fn ParameterClient::on_param_value(
  self : ParameterClient,
  pv : ParamValue,
  now_ms : UInt64,
) -> Unit {
  self.last_action_ms = now_ms
  if pv.param_count > 0U {
    self.expected_count = pv.param_count.reinterpret_as_int()
  }
  let mut found = false
  for i = 0; i < self.params.length(); i = i + 1 {
    if self.params[i].param_id == pv.param_id ||
      self.params[i].param_index == pv.param_index {
      self.params[i] = {
        param_id: pv.param_id,
        param_value: pv.param_value,
        param_type: pv.param_type,
        param_index: pv.param_index,
      }
      found = true
      break
    }
  }
  if !found {
    self.params.push({
      param_id: pv.param_id,
      param_value: pv.param_value,
      param_type: pv.param_type,
      param_index: pv.param_index,
    })
  }

  match self.state {
    ListingAll =>
      if self.expected_count > 0 && self.params.length() >= self.expected_count {
        self.state = Synced
        self.retries = 0
      }
    WritingParam(target_id, target_val, _) =>
      if pv.param_id == target_id && pv.param_value == target_val {
        self.state = Synced
        self.retries = 0
      }
    _ => ()
  }
}

///|
/// Return the list of missing parameter indices (`0 .. expected_count - 1`) during list synchronization.
pub fn ParameterClient::missing_indices(self : ParameterClient) -> Array[Int32] {
  let missing : Array[Int32] = []
  if self.expected_count <= 0 {
    return missing
  }
  for idx = 0; idx < self.expected_count; idx = idx + 1 {
    let u_idx = idx.reinterpret_as_uint()
    let mut seen = false
    for p in self.params {
      if p.param_index == u_idx {
        seen = true
        break
      }
    }
    if !seen {
      missing.push(idx)
    }
  }
  missing
}

///|
/// Poll for timeout recovery. Emits targeted `PARAM_REQUEST_READ` (#20) for missing indices
/// or retries `PARAM_REQUEST_LIST` / `PARAM_SET` up to `max_retries`.
pub fn ParameterClient::poll_timeout(
  self : ParameterClient,
  now_ms : UInt64,
) -> MavMessage? {
  if now_ms < self.last_action_ms ||
    now_ms - self.last_action_ms < self.timeout_ms {
    return None
  }
  match self.state {
    ListingAll => {
      if self.retries >= self.max_retries {
        self.state = Failed("Parameter list sync timed out after max retries")
        return None
      }
      self.retries = self.retries + 1
      self.last_action_ms = now_ms
      let missing = self.missing_indices()
      if missing.length() > 0 {
        Some(
          MsgParamRequestRead({
            param_index: missing[0],
            target_system: self.target_system,
            target_component: self.target_component,
            param_id: "",
          }),
        )
      } else {
        Some(
          MsgParamRequestList({
            target_system: self.target_system,
            target_component: self.target_component,
          }),
        )
      }
    }
    WritingParam(param_id, param_value, param_type) => {
      if self.retries >= self.max_retries {
        self.state = Failed("PARAM_SET timed out for " + param_id)
        return None
      }
      self.retries = self.retries + 1
      self.last_action_ms = now_ms
      Some(
        MsgParamSet({
          param_value,
          target_system: self.target_system,
          target_component: self.target_component,
          param_id,
          param_type,
        }),
      )
    }
    _ => None
  }
}

///|
/// Look up a synchronized parameter by name.
pub fn ParameterClient::get_param(
  self : ParameterClient,
  param_id : String,
) -> ParameterEntry? {
  for p in self.params {
    if p.param_id == param_id {
      return Some(p)
    }
  }
  None
}

///|
/// Vehicle-side MAVLink Parameter Protocol server supporting `PARAM_REQUEST_LIST`,
/// `PARAM_REQUEST_READ` (by index or ID), and `PARAM_SET`.
pub(all) struct ParameterServer {
  sysid : Byte
  compid : Byte
  params : Array[ParameterEntry]
} derive(Eq, Debug)

///|
pub extend ParameterServer with Eq::{not_equal, equal}

///|
pub extend ParameterServer with @debug.Debug::{to_repr}

///|
/// Create a new `ParameterServer` initialized with a table of parameters.
pub fn ParameterServer::new(
  sysid : Byte,
  compid : Byte,
  initial_params : Array[(String, Float, Byte)],
) -> ParameterServer {
  let params : Array[ParameterEntry] = []
  for i = 0; i < initial_params.length(); i = i + 1 {
    let (id, val, ptype) = initial_params[i]
    params.push({
      param_id: id,
      param_value: val,
      param_type: ptype,
      param_index: i.reinterpret_as_uint(),
    })
  }
  { sysid, compid, params, }
}

///|
/// Handle an incoming MAVLink parameter request message and return the response messages.
pub fn ParameterServer::handle_message(
  self : ParameterServer,
  msg : MavMessage,
) -> Array[MavMessage] {
  let total_count = self.params.length().reinterpret_as_uint()
  match msg {
    MsgParamRequestList(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      let out : Array[MavMessage] = []
      for p in self.params {
        out.push(
          MsgParamValue({
            param_value: p.param_value,
            param_count: total_count,
            param_index: p.param_index,
            param_id: p.param_id,
            param_type: p.param_type,
          }),
        )
      }
      out
    }
    MsgParamRequestRead(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      if req.param_index >= 0 {
        let idx = req.param_index
        if idx < self.params.length() {
          let p = self.params[idx]
          return [
            MsgParamValue({
              param_value: p.param_value,
              param_count: total_count,
              param_index: p.param_index,
              param_id: p.param_id,
              param_type: p.param_type,
            }),
          ]
        }
        return []
      }
      for p in self.params {
        if p.param_id == req.param_id {
          return [
            MsgParamValue({
              param_value: p.param_value,
              param_count: total_count,
              param_index: p.param_index,
              param_id: p.param_id,
              param_type: p.param_type,
            }),
          ]
        }
      }
      []
    }
    MsgParamSet(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      for i = 0; i < self.params.length(); i = i + 1 {
        if self.params[i].param_id == req.param_id &&
          self.params[i].param_type == req.param_type {
          self.params[i].param_value = req.param_value
          let p = self.params[i]
          return [
            MsgParamValue({
              param_value: p.param_value,
              param_count: total_count,
              param_index: p.param_index,
              param_id: p.param_id,
              param_type: p.param_type,
            }),
          ]
        }
      }
      []
    }
    _ => []
  }
}

// ============================================================================
// 3. Mission Protocol Microservice (Upload Client, Download Client & Server)
// ============================================================================

///|
/// State of a MAVLink Mission Upload or Download transaction.
pub(all) enum MissionTxState {
  Idle
  AwaitingRequest
  AwaitingCount
  AwaitingItem(UInt32)
  Completed
  Failed(MavMissionResult)
} derive(Eq, Debug)

///|
pub extend MissionTxState with Eq::{not_equal, equal}

///|
pub extend MissionTxState with @debug.Debug::{to_repr}

///|
/// GCS-side MAVLink Mission Upload state machine (`MISSION_COUNT` -> `MISSION_REQUEST_INT` -> `MISSION_ITEM_INT` -> `MISSION_ACK`).
pub(all) struct MissionUploadClient {
  target_system : Byte
  target_component : Byte
  mission_type : Byte
  timeout_ms : UInt64
  max_retries : Int32
  mut state : MissionTxState
  mut last_action_ms : UInt64
  mut retries : Int32
  mut last_requested_seq : Int32
  items : Array[MissionItemInt]
} derive(Eq, Debug)

///|
pub extend MissionUploadClient with Eq::{not_equal, equal}

///|
pub extend MissionUploadClient with @debug.Debug::{to_repr}

///|
/// Create a new `MissionUploadClient`.
pub fn MissionUploadClient::new(
  target_system : Byte,
  target_component : Byte,
  mission_type~ : Byte = b'\x00',
  timeout_ms~ : UInt64 = 1500UL,
  max_retries~ : Int32 = 5,
) -> MissionUploadClient {
  {
    target_system,
    target_component,
    mission_type,
    timeout_ms,
    max_retries,
    state: Idle,
    last_action_ms: 0UL,
    retries: 0,
    last_requested_seq: -1,
    items: [],
  }
}

///|
/// Start a mission upload transaction by emitting `MISSION_COUNT` (#44).
pub fn MissionUploadClient::start_upload(
  self : MissionUploadClient,
  waypoints : Array[MissionItemInt],
  now_ms : UInt64,
) -> MavMessage {
  self.items.clear()
  for wp in waypoints {
    self.items.push(wp)
  }
  self.state = AwaitingRequest
  self.last_action_ms = now_ms
  self.retries = 0
  self.last_requested_seq = -1
  MsgMissionCount({
    count: self.items.length().reinterpret_as_uint(),
    target_system: self.target_system,
    target_component: self.target_component,
    mission_type: self.mission_type,
    opaque_id: 0U,
  })
}

///|
/// Process an incoming `MISSION_REQUEST_INT` (#51), `MISSION_REQUEST` (#40), or `MISSION_ACK` (#47).
pub fn MissionUploadClient::on_message(
  self : MissionUploadClient,
  msg : MavMessage,
  now_ms : UInt64,
) -> MavMessage? {
  if self.state != AwaitingRequest {
    return None
  }
  match msg {
    MsgMissionRequestInt(req) => {
      self.last_action_ms = now_ms
      self.retries = 0
      let idx = req.seq.reinterpret_as_int()
      if idx >= 0 && idx < self.items.length() {
        self.last_requested_seq = idx
        Some(MsgMissionItemInt(self.items[idx]))
      } else {
        self.state = Failed(MavMissionInvalidSequence)
        Some(
          MsgMissionAck({
            target_system: self.target_system,
            target_component: self.target_component,
            mav_type: MavMissionResult::MavMissionInvalidSequence
            .to_uint()
            .to_byte(),
            mission_type: self.mission_type,
            opaque_id: 0U,
          }),
        )
      }
    }
    MsgMissionRequest(req) => {
      self.last_action_ms = now_ms
      self.retries = 0
      let idx = req.seq.reinterpret_as_int()
      if idx >= 0 && idx < self.items.length() {
        self.last_requested_seq = idx
        Some(MsgMissionItemInt(self.items[idx]))
      } else {
        self.state = Failed(MavMissionInvalidSequence)
        None
      }
    }
    MsgMissionAck(ack) => {
      self.last_action_ms = now_ms
      match MavMissionResult::from_uint(ack.mav_type.to_uint()) {
        Some(MavMissionAccepted) => self.state = Completed
        Some(err_code) => self.state = Failed(err_code)
        None => self.state = Failed(MavMissionError)
      }
      None
    }
    _ => None
  }
}

///|
/// Poll for upload timeout retransmission.
pub fn MissionUploadClient::poll_timeout(
  self : MissionUploadClient,
  now_ms : UInt64,
) -> MavMessage? {
  if self.state != AwaitingRequest ||
    now_ms < self.last_action_ms ||
    now_ms - self.last_action_ms < self.timeout_ms {
    return None
  }
  if self.retries >= self.max_retries {
    self.state = Failed(MavMissionError)
    return None
  }
  self.retries = self.retries + 1
  self.last_action_ms = now_ms
  if self.last_requested_seq >= 0 &&
    self.last_requested_seq < self.items.length() {
    Some(MsgMissionItemInt(self.items[self.last_requested_seq]))
  } else {
    Some(
      MsgMissionCount({
        count: self.items.length().reinterpret_as_uint(),
        target_system: self.target_system,
        target_component: self.target_component,
        mission_type: self.mission_type,
        opaque_id: 0U,
      }),
    )
  }
}

///|
/// GCS-side MAVLink Mission Download state machine (`MISSION_REQUEST_LIST` -> `MISSION_COUNT` -> `MISSION_REQUEST_INT` -> `MISSION_ITEM_INT` -> `MISSION_ACK`).
pub(all) struct MissionDownloadClient {
  target_system : Byte
  target_component : Byte
  mission_type : Byte
  timeout_ms : UInt64
  max_retries : Int32
  mut state : MissionTxState
  mut expected_count : UInt32
  mut last_action_ms : UInt64
  mut retries : Int32
  downloaded_items : Array[MissionItemInt]
} derive(Eq, Debug)

///|
pub extend MissionDownloadClient with Eq::{not_equal, equal}

///|
pub extend MissionDownloadClient with @debug.Debug::{to_repr}

///|
/// Create a new `MissionDownloadClient`.
pub fn MissionDownloadClient::new(
  target_system : Byte,
  target_component : Byte,
  mission_type~ : Byte = b'\x00',
  timeout_ms~ : UInt64 = 1500UL,
  max_retries~ : Int32 = 5,
) -> MissionDownloadClient {
  {
    target_system,
    target_component,
    mission_type,
    timeout_ms,
    max_retries,
    state: Idle,
    expected_count: 0U,
    last_action_ms: 0UL,
    retries: 0,
    downloaded_items: [],
  }
}

///|
/// Initiate a mission download transaction (`MISSION_REQUEST_LIST` #43).
pub fn MissionDownloadClient::start_download(
  self : MissionDownloadClient,
  now_ms : UInt64,
) -> MavMessage {
  self.state = AwaitingCount
  self.expected_count = 0U
  self.last_action_ms = now_ms
  self.retries = 0
  self.downloaded_items.clear()
  MsgMissionRequestList({
    target_system: self.target_system,
    target_component: self.target_component,
    mission_type: self.mission_type,
  })
}

///|
/// Process an incoming `MISSION_COUNT` (#44) or `MISSION_ITEM_INT` (#73) during mission download.
pub fn MissionDownloadClient::on_message(
  self : MissionDownloadClient,
  msg : MavMessage,
  now_ms : UInt64,
) -> MavMessage? {
  match (self.state, msg) {
    (AwaitingCount, MsgMissionCount(mc)) => {
      self.last_action_ms = now_ms
      self.retries = 0
      self.expected_count = mc.count
      if mc.count == 0U {
        self.state = Completed
        Some(
          MsgMissionAck({
            target_system: self.target_system,
            target_component: self.target_component,
            mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
            mission_type: self.mission_type,
            opaque_id: 0U,
          }),
        )
      } else {
        self.state = AwaitingItem(0U)
        Some(
          MsgMissionRequestInt({
            seq: 0U,
            target_system: self.target_system,
            target_component: self.target_component,
            mission_type: self.mission_type,
          }),
        )
      }
    }
    (AwaitingItem(expected_seq), MsgMissionItemInt(item)) => {
      if item.seq != expected_seq {
        return None
      }
      self.last_action_ms = now_ms
      self.retries = 0
      self.downloaded_items.push(item)
      let next_seq = expected_seq + 1U
      if next_seq >= self.expected_count {
        self.state = Completed
        Some(
          MsgMissionAck({
            target_system: self.target_system,
            target_component: self.target_component,
            mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
            mission_type: self.mission_type,
            opaque_id: 0U,
          }),
        )
      } else {
        self.state = AwaitingItem(next_seq)
        Some(
          MsgMissionRequestInt({
            seq: next_seq,
            target_system: self.target_system,
            target_component: self.target_component,
            mission_type: self.mission_type,
          }),
        )
      }
    }
    _ => None
  }
}

///|
/// Vehicle-side MAVLink Mission Protocol server supporting upload, download, clear, and current waypoint selection.
pub(all) struct MissionServer {
  sysid : Byte
  compid : Byte
  mut active_seq : UInt32
  mut upload_expected : UInt32
  mut uploading : Bool
  staging_items : Array[MissionItemInt]
  stored_items : Array[MissionItemInt]
} derive(Eq, Debug)

///|
pub extend MissionServer with Eq::{not_equal, equal}

///|
pub extend MissionServer with @debug.Debug::{to_repr}

///|
/// Create a new vehicle-side `MissionServer`.
pub fn MissionServer::new(sysid : Byte, compid : Byte) -> MissionServer {
  {
    sysid,
    compid,
    active_seq: 0U,
    upload_expected: 0U,
    uploading: false,
    staging_items: [],
    stored_items: [],
  }
}

///|
/// Handle an incoming MAVLink Mission Protocol message on the vehicle side.
pub fn MissionServer::handle_message(
  self : MissionServer,
  sender_sysid : Byte,
  sender_compid : Byte,
  msg : MavMessage,
) -> MavMessage? {
  match msg {
    MsgMissionCount(mc) => {
      self.staging_items.clear()
      self.upload_expected = mc.count
      if mc.count == 0U {
        self.stored_items.clear()
        self.uploading = false
        Some(
          MsgMissionAck({
            target_system: sender_sysid,
            target_component: sender_compid,
            mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
            mission_type: mc.mission_type,
            opaque_id: 1U,
          }),
        )
      } else {
        self.uploading = true
        Some(
          MsgMissionRequestInt({
            seq: 0U,
            target_system: sender_sysid,
            target_component: sender_compid,
            mission_type: mc.mission_type,
          }),
        )
      }
    }
    MsgMissionItemInt(item) => {
      if !self.uploading {
        return None
      }
      let expected_seq = self.staging_items.length().reinterpret_as_uint()
      if item.seq != expected_seq {
        return Some(
          MsgMissionAck({
            target_system: sender_sysid,
            target_component: sender_compid,
            mav_type: MavMissionResult::MavMissionInvalidSequence
            .to_uint()
            .to_byte(),
            mission_type: item.mission_type,
            opaque_id: 0U,
          }),
        )
      }
      self.staging_items.push(item)
      let next_seq = expected_seq + 1U
      if next_seq >= self.upload_expected {
        self.stored_items.clear()
        for st in self.staging_items {
          self.stored_items.push(st)
        }
        self.uploading = false
        Some(
          MsgMissionAck({
            target_system: sender_sysid,
            target_component: sender_compid,
            mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
            mission_type: item.mission_type,
            opaque_id: 1U,
          }),
        )
      } else {
        Some(
          MsgMissionRequestInt({
            seq: next_seq,
            target_system: sender_sysid,
            target_component: sender_compid,
            mission_type: item.mission_type,
          }),
        )
      }
    }
    MsgMissionRequestList(req) =>
      Some(
        MsgMissionCount({
          count: self.stored_items.length().reinterpret_as_uint(),
          target_system: sender_sysid,
          target_component: sender_compid,
          mission_type: req.mission_type,
          opaque_id: 1U,
        }),
      )
    MsgMissionRequestInt(req) => {
      let idx = req.seq.reinterpret_as_int()
      if idx >= 0 && idx < self.stored_items.length() {
        Some(MsgMissionItemInt(self.stored_items[idx]))
      } else {
        Some(
          MsgMissionAck({
            target_system: sender_sysid,
            target_component: sender_compid,
            mav_type: MavMissionResult::MavMissionInvalidSequence
            .to_uint()
            .to_byte(),
            mission_type: req.mission_type,
            opaque_id: 0U,
          }),
        )
      }
    }
    MsgMissionClearAll(req) => {
      self.stored_items.clear()
      self.staging_items.clear()
      self.active_seq = 0U
      self.uploading = false
      Some(
        MsgMissionAck({
          target_system: sender_sysid,
          target_component: sender_compid,
          mav_type: MavMissionResult::MavMissionAccepted.to_uint().to_byte(),
          mission_type: req.mission_type,
          opaque_id: 0U,
        }),
      )
    }
    MsgMissionSetCurrent(req) => {
      let idx = req.seq.reinterpret_as_int()
      if idx >= 0 && idx < self.stored_items.length() {
        self.active_seq = req.seq
        Some(
          MsgMissionCurrent({
            seq: self.active_seq,
            total: self.stored_items.length().reinterpret_as_uint(),
            mission_state: b'\x03',
            mission_mode: b'\x01',
          }),
        )
      } else {
        None
      }
    }
    _ => None
  }
}

// ============================================================================
// 4. Command Protocol Microservice (COMMAND_LONG / COMMAND_ACK / COMMAND_CANCEL)
// ============================================================================

///|
/// Execution state of a MAVLink Command transaction (`COMMAND_LONG` #76 / `COMMAND_ACK` #77).
pub(all) enum CommandTxState {
  Idle
  Pending(UInt32, Byte)
  InProgress(UInt32, Byte)
  Finished(UInt32, MavResult)
  TimedOut(UInt32)
} derive(Eq, Debug)

///|
pub extend CommandTxState with Eq::{not_equal, equal}

///|
pub extend CommandTxState with @debug.Debug::{to_repr}

///|
/// GCS-side MAVLink Command Protocol state machine with automatic `confirmation` counter
/// increment on retransmission, `MAV_RESULT_IN_PROGRESS` tracking, and `COMMAND_CANCEL`.
pub(all) struct CommandClient {
  target_system : Byte
  target_component : Byte
  timeout_ms : UInt64
  max_retries : Int32
  mut state : CommandTxState
  mut active_cmd : CommandLong?
  mut last_sent_ms : UInt64
  mut retries : Int32
} derive(Eq, Debug)

///|
pub extend CommandClient with Eq::{not_equal, equal}

///|
pub extend CommandClient with @debug.Debug::{to_repr}

///|
/// Create a new `CommandClient`.
pub fn CommandClient::new(
  target_system : Byte,
  target_component : Byte,
  timeout_ms~ : UInt64 = 1000UL,
  max_retries~ : Int32 = 3,
) -> CommandClient {
  {
    target_system,
    target_component,
    timeout_ms,
    max_retries,
    state: Idle,
    active_cmd: None,
    last_sent_ms: 0UL,
    retries: 0,
  }
}

///|
/// Send a `COMMAND_LONG` (#76) with initial `confirmation = 0`.
pub fn CommandClient::send_command_long(
  self : CommandClient,
  command : UInt32,
  now_ms : UInt64,
  param1~ : Float = (0.0 : Float),
  param2~ : Float = (0.0 : Float),
  param3~ : Float = (0.0 : Float),
  param4~ : Float = (0.0 : Float),
  param5~ : Float = (0.0 : Float),
  param6~ : Float = (0.0 : Float),
  param7~ : Float = (0.0 : Float),
) -> MavMessage {
  let cmd : CommandLong = {
    param1,
    param2,
    param3,
    param4,
    param5,
    param6,
    param7,
    command,
    target_system: self.target_system,
    target_component: self.target_component,
    confirmation: b'\x00',
  }
  self.active_cmd = Some(cmd)
  self.state = Pending(command, b'\x00')
  self.last_sent_ms = now_ms
  self.retries = 0
  MsgCommandLong(cmd)
}

///|
/// Process an incoming `COMMAND_ACK` (#77) message.
pub fn CommandClient::on_command_ack(
  self : CommandClient,
  ack : CommandAck,
  now_ms : UInt64,
) -> Unit {
  let active_id = match self.state {
    Pending(cid, _) | InProgress(cid, _) => cid
    _ => return ()
  }
  if ack.command != active_id {
    return ()
  }
  self.last_sent_ms = now_ms
  match MavResult::from_uint(ack.result.to_uint()) {
    Some(InProgress) => self.state = InProgress(active_id, ack.progress)
    Some(final_res) => {
      self.state = Finished(active_id, final_res)
      self.active_cmd = None
    }
    None => {
      self.state = Finished(active_id, Failed)
      self.active_cmd = None
    }
  }
}

///|
/// Poll for timeout retransmission. Per official MAVLink Command Microservice specification,
/// each retransmission increments the `confirmation` field (`0 -> 1 -> 2...`).
pub fn CommandClient::poll_timeout(
  self : CommandClient,
  now_ms : UInt64,
) -> MavMessage? {
  let cid = match self.state {
    Pending(c, _) | InProgress(c, _) => c
    _ => return None
  }
  if now_ms < self.last_sent_ms || now_ms - self.last_sent_ms < self.timeout_ms {
    return None
  }
  if self.retries >= self.max_retries {
    self.state = TimedOut(cid)
    self.active_cmd = None
    return None
  }
  match self.active_cmd {
    Some(cmd) => {
      self.retries = self.retries + 1
      let next_conf = ((cmd.confirmation.to_int() + 1) & 0xFF).to_byte()
      let updated_cmd : CommandLong = { ..cmd, confirmation: next_conf, }
      self.active_cmd = Some(updated_cmd)
      self.state = Pending(cid, next_conf)
      self.last_sent_ms = now_ms
      Some(MsgCommandLong(updated_cmd))
    }
    None => None
  }
}

///|
/// Cancel the currently active long-running command by emitting `COMMAND_CANCEL` (#80).
pub fn CommandClient::cancel_active(
  self : CommandClient,
  now_ms : UInt64,
) -> MavMessage? {
  let cid = match self.state {
    Pending(c, _) | InProgress(c, _) => c
    _ => return None
  }
  self.last_sent_ms = now_ms
  self.state = Finished(cid, Cancelled)
  self.active_cmd = None
  Some(
    MsgCommandCancel({
      command: cid,
      target_system: self.target_system,
      target_component: self.target_component,
    }),
  )
}

// ============================================================================
// 5. Timesync & Link RTT Estimator (`TIMESYNC` #111)
// ============================================================================

///|
/// Result of a completed two-way `TIMESYNC` (#111) probe.
pub(all) struct TimesyncSample {
  rtt_ns : Int64
  clock_offset_ns : Int64
} derive(Eq, Debug)

///|
pub extend TimesyncSample with Eq::{not_equal, equal}

///|
pub extend TimesyncSample with @debug.Debug::{to_repr}

///|
/// Two-way MAVLink `TIMESYNC` (#111) clock offset and round-trip latency estimator
/// with exponential moving average (EMA) jitter smoothing.
pub(all) struct TimesyncEstimator {
  mut sample_count : Int32
  mut min_rtt_ns : Int64
  mut ema_rtt_ns : Int64
  mut ema_offset_ns : Int64
} derive(Eq, Debug)

///|
pub extend TimesyncEstimator with Eq::{not_equal, equal}

///|
pub extend TimesyncEstimator with @debug.Debug::{to_repr}

///|
/// Create a new `TimesyncEstimator`.
pub fn TimesyncEstimator::new() -> TimesyncEstimator {
  {
    sample_count: 0,
    min_rtt_ns: 0x7FFFFFFFFFFFFFFFL,
    ema_rtt_ns: 0L,
    ema_offset_ns: 0L,
  }
}

///|
/// Create an outbound `TIMESYNC` (#111) probe request (`tc1 = 0`, `ts1 = local_time_ns`).
pub fn TimesyncEstimator::create_probe(
  local_time_ns : Int64,
  target_system~ : Byte = b'\x01',
  target_component~ : Byte = b'\x01',
) -> MavMessage {
  MsgTimesync({ tc1: 0L, ts1: local_time_ns, target_system, target_component, })
}

///|
/// Respond to an incoming `TIMESYNC` probe request (`tc1 == 0`) by stamping `tc1 = local_time_ns`.
pub fn TimesyncEstimator::respond_to_probe(
  incoming : Timesync,
  local_time_ns : Int64,
  sender_sysid : Byte,
  sender_compid : Byte,
) -> MavMessage? {
  if incoming.tc1 != 0L {
    return None
  }
  Some(
    MsgTimesync({
      tc1: local_time_ns,
      ts1: incoming.ts1,
      target_system: sender_sysid,
      target_component: sender_compid,
    }),
  )
}

///|
/// Process a returned `TIMESYNC` probe (`tc1 != 0`) at local receive timestamp `rx_time_ns`,
/// updating RTT and clock offset estimates.
pub fn TimesyncEstimator::on_probe_return(
  self : TimesyncEstimator,
  incoming : Timesync,
  rx_time_ns : Int64,
) -> TimesyncSample? {
  if incoming.tc1 == 0L || rx_time_ns < incoming.ts1 {
    return None
  }
  let rtt_ns = rx_time_ns - incoming.ts1
  let midpoint_ns = incoming.ts1 + rtt_ns / 2L
  let clock_offset_ns = incoming.tc1 - midpoint_ns

  if rtt_ns < self.min_rtt_ns {
    self.min_rtt_ns = rtt_ns
  }
  if self.sample_count == 0 {
    self.ema_rtt_ns = rtt_ns
    self.ema_offset_ns = clock_offset_ns
  } else {
    // Exponential moving average with alpha = 1/4 (integer arithmetic)
    self.ema_rtt_ns = (self.ema_rtt_ns * 3L + rtt_ns) / 4L
    self.ema_offset_ns = (self.ema_offset_ns * 3L + clock_offset_ns) / 4L
  }
  self.sample_count = self.sample_count + 1
  Some({ rtt_ns, clock_offset_ns, })
}

// ============================================================================
// 6. MAVLink File Transfer Protocol (`FILE_TRANSFER_PROTOCOL` #110) Codec
// ============================================================================

///|
/// Official MAVLink FTP opcodes carried inside the 251-byte `FILE_TRANSFER_PROTOCOL` (#110) payload.
pub(all) enum FtpOpcode {
  FtpNone
  TerminateSession
  ResetSessions
  ListDirectory
  OpenFileRO
  ReadFile
  CreateFile
  WriteFile
  RemoveFile
  CreateDirectory
  RemoveDirectory
  OpenFileWO
  TruncateFile
  Rename
  CalcFileCRC32
  BurstReadFile
  Ack
  Nak
} derive(Eq, Debug)

///|
pub extend FtpOpcode with Eq::{not_equal, equal}

///|
pub extend FtpOpcode with @debug.Debug::{to_repr}

///|
/// Convert `FtpOpcode` to its wire byte code.
pub fn FtpOpcode::to_byte(self : FtpOpcode) -> Byte {
  match self {
    FtpNone => b'\x00'
    TerminateSession => b'\x01'
    ResetSessions => b'\x02'
    ListDirectory => b'\x03'
    OpenFileRO => b'\x04'
    ReadFile => b'\x05'
    CreateFile => b'\x06'
    WriteFile => b'\x07'
    RemoveFile => b'\x08'
    CreateDirectory => b'\x09'
    RemoveDirectory => b'\x0A'
    OpenFileWO => b'\x0B'
    TruncateFile => b'\x0C'
    Rename => b'\x0D'
    CalcFileCRC32 => b'\x0E'
    BurstReadFile => b'\x0F'
    Ack => b'\x80'
    Nak => b'\x81'
  }
}

///|
/// Decode `FtpOpcode` from its wire byte code.
pub fn FtpOpcode::from_byte(b : Byte) -> FtpOpcode? {
  match b.to_int() & 0xFF {
    0 => Some(FtpNone)
    1 => Some(TerminateSession)
    2 => Some(ResetSessions)
    3 => Some(ListDirectory)
    4 => Some(OpenFileRO)
    5 => Some(ReadFile)
    6 => Some(CreateFile)
    7 => Some(WriteFile)
    8 => Some(RemoveFile)
    9 => Some(CreateDirectory)
    10 => Some(RemoveDirectory)
    11 => Some(OpenFileWO)
    12 => Some(TruncateFile)
    13 => Some(Rename)
    14 => Some(CalcFileCRC32)
    15 => Some(BurstReadFile)
    128 => Some(Ack)
    129 => Some(Nak)
    _ => None
  }
}

///|
/// Structured MAVLink FTP sub-packet (12-byte little-endian header + up to 239 data bytes = 251 bytes max).
pub(all) struct FtpPacket {
  seq_number : UInt32
  session : Byte
  opcode : FtpOpcode
  req_opcode : FtpOpcode
  burst_complete : Bool
  offset : UInt32
  data : Bytes
} derive(Eq, Debug)

///|
pub extend FtpPacket with Eq::{not_equal, equal}

///|
pub extend FtpPacket with @debug.Debug::{to_repr}

///|
/// Encode `FtpPacket` into a `FILE_TRANSFER_PROTOCOL` (#110) `MavMessage`.
/// Returns `Err(PayloadTooLarge(_))` if `data.length() > 239`.
pub fn FtpPacket::to_mav_message(
  self : FtpPacket,
  target_network~ : Byte = b'\x00',
  target_system~ : Byte = b'\x01',
  target_component~ : Byte = b'\x01',
) -> Result[MavMessage, MavError] {
  if self.data.length() > 239 {
    return Err(PayloadTooLarge(self.data.length()))
  }
  let buf = FixedArray::make(251, b'\x00')
  buf[0] = (self.seq_number & 0xFFU).to_byte()
  buf[1] = ((self.seq_number >> 8) & 0xFFU).to_byte()
  buf[2] = self.session
  buf[3] = self.opcode.to_byte()
  buf[4] = self.data.length().to_byte()
  buf[5] = self.req_opcode.to_byte()
  buf[6] = if self.burst_complete { b'\x01' } else { b'\x00' }
  buf[7] = b'\x00'
  buf[8] = (self.offset & 0xFFU).to_byte()
  buf[9] = ((self.offset >> 8) & 0xFFU).to_byte()
  buf[10] = ((self.offset >> 16) & 0xFFU).to_byte()
  buf[11] = ((self.offset >> 24) & 0xFFU).to_byte()
  for i = 0; i < self.data.length(); i = i + 1 {
    buf[12 + i] = self.data[i]
  }
  Ok(
    MsgFileTransferProtocol({
      target_network,
      target_system,
      target_component,
      payload: buf,
    }),
  )
}

///|
/// Decode an `FtpPacket` from a `FileTransferProtocol` (#110) struct.
pub fn FtpPacket::from_file_transfer_protocol(
  ftp : FileTransferProtocol,
) -> Result[FtpPacket, MavError] {
  if ftp.payload.length() < 12 {
    return Err(PayloadTooShort(12, ftp.payload.length()))
  }
  let seq_number = ftp.payload[0].to_uint() | (ftp.payload[1].to_uint() << 8)
  let session = ftp.payload[2]
  let opcode = match FtpOpcode::from_byte(ftp.payload[3]) {
    Some(op) => op
    None => return Err(SchemaError("Unknown MAVLink FTP opcode"))
  }
  let data_size = ftp.payload[4].to_int() & 0xFF
  if data_size > 239 || 12 + data_size > ftp.payload.length() {
    return Err(PayloadTooLarge(data_size))
  }
  let req_opcode = match FtpOpcode::from_byte(ftp.payload[5]) {
    Some(op) => op
    None => FtpNone
  }
  let burst_complete = ftp.payload[6] != b'\x00'
  let offset = ftp.payload[8].to_uint() |
    (ftp.payload[9].to_uint() << 8) |
    (ftp.payload[10].to_uint() << 16) |
    (ftp.payload[11].to_uint() << 24)
  let data_arr : Array[Byte] = Array(capacity=data_size)
  for i = 0; i < data_size; i = i + 1 {
    data_arr.push(ftp.payload[12 + i])
  }
  Ok({
    seq_number,
    session,
    opcode,
    req_opcode,
    burst_complete,
    offset,
    data: Bytes::from_array(data_arr),
  })
}

// ============================================================================
// 7. Telemetry Stream Rate & Bandwidth Analyzer (`TelemetryRateTracker`)
// ============================================================================

///|
/// Per-message-ID reception counter and byte volume tracked by `TelemetryRateTracker`.
pub(all) struct MessageRateStat {
  msgid : UInt32
  mut frame_count : Int32
  mut payload_bytes : Int32
  mut wire_bytes : Int32
} derive(Eq, Debug)

///|
pub extend MessageRateStat with Eq::{not_equal, equal}

///|
pub extend MessageRateStat with @debug.Debug::{to_repr}

///|
/// Telemetry stream analyzer for computing per-message Hz frequency and link bandwidth utilization.
pub(all) struct TelemetryRateTracker {
  mut total_frames : Int32
  mut total_wire_bytes : Int32
  stats : Array[MessageRateStat]
} derive(Eq, Debug)

///|
pub extend TelemetryRateTracker with Eq::{not_equal, equal}

///|
pub extend TelemetryRateTracker with @debug.Debug::{to_repr}

///|
/// Create a new `TelemetryRateTracker`.
pub fn TelemetryRateTracker::new() -> TelemetryRateTracker {
  { total_frames: 0, total_wire_bytes: 0, stats: [], }
}

///|
/// Record a received `MavFrame` and its total wire byte length.
pub fn TelemetryRateTracker::record_frame(
  self : TelemetryRateTracker,
  frame : MavFrame,
  wire_len : Int32,
) -> Unit {
  self.total_frames = self.total_frames + 1
  self.total_wire_bytes = self.total_wire_bytes + wire_len
  let mid = frame.header.msgid
  let plen = frame.payload.length()
  for i = 0; i < self.stats.length(); i = i + 1 {
    if self.stats[i].msgid == mid {
      self.stats[i].frame_count = self.stats[i].frame_count + 1
      self.stats[i].payload_bytes = self.stats[i].payload_bytes + plen
      self.stats[i].wire_bytes = self.stats[i].wire_bytes + wire_len
      return ()
    }
  }
  self.stats.push({
    msgid: mid,
    frame_count: 1,
    payload_bytes: plen,
    wire_bytes: wire_len,
  })
}

///|
/// Compute the average message rate in Hz for `msgid` over a duration of `window_ms` milliseconds.
pub fn TelemetryRateTracker::message_rate_hz(
  self : TelemetryRateTracker,
  msgid : UInt32,
  window_ms : UInt64,
) -> Double {
  if window_ms == 0UL {
    return 0.0
  }
  for s in self.stats {
    if s.msgid == msgid {
      return s.frame_count.to_double() * 1000.0 / window_ms.to_double()
    }
  }
  0.0
}

///|
/// Compute total link bandwidth in Bytes/second over `window_ms` milliseconds.
pub fn TelemetryRateTracker::total_bandwidth_bytes_per_sec(
  self : TelemetryRateTracker,
  window_ms : UInt64,
) -> Double {
  if window_ms == 0UL {
    return 0.0
  }
  self.total_wire_bytes.to_double() * 1000.0 / window_ms.to_double()
}

// ============================================================================
// 8. Extended Parameter Protocol Microservice (`PARAM_EXT_*` #320..#324)
// ============================================================================

///|
/// Extended 128-byte parameter entry for camera, gimbal, and smart payload subsystems.
pub(all) struct ExtParameterEntry {
  param_id : String
  mut param_value : String
  param_type : Byte
  param_index : UInt32
} derive(Eq, Debug)

///|
pub extend ExtParameterEntry with Eq::{not_equal, equal}

///|
pub extend ExtParameterEntry with @debug.Debug::{to_repr}

///|
/// Vehicle/payload-side server for the MAVLink Extended Parameter Protocol
/// (`PARAM_EXT_REQUEST_LIST` #321, `PARAM_EXT_REQUEST_READ` #320, `PARAM_EXT_SET` #323 -> `PARAM_EXT_ACK` #324).
pub(all) struct ExtendedParameterServer {
  sysid : Byte
  compid : Byte
  params : Array[ExtParameterEntry]
} derive(Eq, Debug)

///|
pub extend ExtendedParameterServer with Eq::{not_equal, equal}

///|
pub extend ExtendedParameterServer with @debug.Debug::{to_repr}

///|
/// Create a new `ExtendedParameterServer` initialized with `(param_id, param_value, param_type)` entries.
pub fn ExtendedParameterServer::new(
  sysid : Byte,
  compid : Byte,
  initial_params : Array[(String, String, Byte)],
) -> ExtendedParameterServer {
  let params : Array[ExtParameterEntry] = []
  for i = 0; i < initial_params.length(); i = i + 1 {
    let (id, val, ptype) = initial_params[i]
    params.push({
      param_id: id,
      param_value: val,
      param_type: ptype,
      param_index: i.reinterpret_as_uint(),
    })
  }
  { sysid, compid, params, }
}

///|
/// Handle an incoming `PARAM_EXT_*` message and return the outbound responses.
pub fn ExtendedParameterServer::handle_message(
  self : ExtendedParameterServer,
  msg : MavMessage,
) -> Array[MavMessage] {
  let total_count = self.params.length().reinterpret_as_uint()
  match msg {
    MsgParamExtRequestList(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      let out : Array[MavMessage] = []
      for p in self.params {
        out.push(
          MsgParamExtValue({
            param_count: total_count,
            param_index: p.param_index,
            param_id: p.param_id,
            param_value: p.param_value,
            param_type: p.param_type,
          }),
        )
      }
      out
    }
    MsgParamExtRequestRead(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      if req.param_index >= 0 {
        let idx = req.param_index
        if idx < self.params.length() {
          let p = self.params[idx]
          return [
            MsgParamExtValue({
              param_count: total_count,
              param_index: p.param_index,
              param_id: p.param_id,
              param_value: p.param_value,
              param_type: p.param_type,
            }),
          ]
        }
        return []
      }
      for p in self.params {
        if p.param_id == req.param_id {
          return [
            MsgParamExtValue({
              param_count: total_count,
              param_index: p.param_index,
              param_id: p.param_id,
              param_value: p.param_value,
              param_type: p.param_type,
            }),
          ]
        }
      }
      []
    }
    MsgParamExtSet(req) => {
      if req.target_system != b'\x00' && req.target_system != self.sysid {
        return []
      }
      for i = 0; i < self.params.length(); i = i + 1 {
        if self.params[i].param_id == req.param_id {
          if self.params[i].param_type != req.param_type {
            return [
              MsgParamExtAck({
                param_id: self.params[i].param_id,
                param_value: self.params[i].param_value,
                param_type: self.params[i].param_type,
                param_result: ParamAck::ValueUnsupported.to_uint().to_byte(),
              }),
            ]
          }
          self.params[i].param_value = req.param_value
          return [
            MsgParamExtAck({
              param_id: self.params[i].param_id,
              param_value: self.params[i].param_value,
              param_type: self.params[i].param_type,
              param_result: ParamAck::Accepted.to_uint().to_byte(),
            }),
          ]
        }
      }
      [
        MsgParamExtAck({
          param_id: req.param_id,
          param_value: req.param_value,
          param_type: req.param_type,
          param_result: ParamAck::Failed.to_uint().to_byte(),
        }),
      ]
    }
    _ => []
  }
}

///|
/// GCS-side client for the MAVLink Extended Parameter Protocol (`PARAM_EXT_*` #320..#324).
pub(all) struct ExtendedParameterClient {
  target_system : Byte
  target_component : Byte
  mut last_ack_result : ParamAck?
  params : Array[ExtParameterEntry]
} derive(Eq, Debug)

///|
pub extend ExtendedParameterClient with Eq::{not_equal, equal}

///|
pub extend ExtendedParameterClient with @debug.Debug::{to_repr}

///|
/// Create a new `ExtendedParameterClient`.
pub fn ExtendedParameterClient::new(
  target_system : Byte,
  target_component : Byte,
) -> ExtendedParameterClient {
  { target_system, target_component, last_ack_result: None, params: [], }
}

///|
/// Request all extended parameters (`PARAM_EXT_REQUEST_LIST` #321).
pub fn ExtendedParameterClient::request_list(
  self : ExtendedParameterClient,
) -> MavMessage {
  self.params.clear()
  MsgParamExtRequestList({
    target_system: self.target_system,
    target_component: self.target_component,
  })
}

///|
/// Send a `PARAM_EXT_SET` (#323) command to update an extended parameter.
pub fn ExtendedParameterClient::set_param(
  self : ExtendedParameterClient,
  param_id : String,
  param_value : String,
  param_type : Byte,
) -> MavMessage {
  self.last_ack_result = None
  MsgParamExtSet({
    target_system: self.target_system,
    target_component: self.target_component,
    param_id,
    param_value,
    param_type,
  })
}

///|
/// Process an incoming `PARAM_EXT_VALUE` (#322) or `PARAM_EXT_ACK` (#324) message.
pub fn ExtendedParameterClient::on_message(
  self : ExtendedParameterClient,
  msg : MavMessage,
) -> Unit {
  match msg {
    MsgParamExtValue(pev) => {
      for i = 0; i < self.params.length(); i = i + 1 {
        if self.params[i].param_id == pev.param_id {
          self.params[i] = {
            param_id: pev.param_id,
            param_value: pev.param_value,
            param_type: pev.param_type,
            param_index: pev.param_index,
          }
          return ()
        }
      }
      self.params.push({
        param_id: pev.param_id,
        param_value: pev.param_value,
        param_type: pev.param_type,
        param_index: pev.param_index,
      })
    }
    MsgParamExtAck(ack) => {
      self.last_ack_result = ParamAck::from_uint(ack.param_result.to_uint())
      if self.last_ack_result == Some(Accepted) {
        for i = 0; i < self.params.length(); i = i + 1 {
          if self.params[i].param_id == ack.param_id {
            self.params[i].param_value = ack.param_value
            return ()
          }
        }
      }
    }
    _ => ()
  }
}

///|
/// Virtual file entry stored inside `FtpServer`.
pub(all) struct FtpVirtualFile {
  path : String
  content : Bytes
} derive(Eq, Debug)

///|
pub extend FtpVirtualFile with Eq::{not_equal, equal}

///|
pub extend FtpVirtualFile with @debug.Debug::{to_repr}

///|
/// Vehicle-side MAVLink FTP (`FILE_TRANSFER_PROTOCOL` #110) virtual filesystem server
/// supporting `OpenFileRO`, `ReadFile`, `ListDirectory`, `TerminateSession`, and `ResetSessions`.
pub(all) struct FtpServer {
  active_session : Byte
  mut open_file_idx : Int32
  files : Array[FtpVirtualFile]
} derive(Eq, Debug)

///|
pub extend FtpServer with Eq::{not_equal, equal}

///|
pub extend FtpServer with @debug.Debug::{to_repr}

///|
/// Create a new `FtpServer` populated with virtual files.
pub fn FtpServer::new(
  files : Array[(String, Bytes)],
  session_id~ : Byte = b'\x01',
) -> FtpServer {
  let vf : Array[FtpVirtualFile] = []
  for pair in files {
    vf.push({ path: pair.0, content: pair.1, })
  }
  { active_session: session_id, open_file_idx: -1, files: vf, }
}

///|
fn bytes_to_ascii_path(data : Bytes) -> String {
  let sb = StringBuilder()
  for i = 0; i < data.length(); i = i + 1 {
    if data[i] == b'\x00' {
      break
    }
    sb.write_char(Int32::unsafe_to_char(data[i].to_int() & 0xFF))
  }
  sb.to_string()
}

///|
/// Process an incoming `FtpPacket` request and return the corresponding `Ack` or `Nak` `FtpPacket`.
pub fn FtpServer::handle_packet(self : FtpServer, req : FtpPacket) -> FtpPacket {
  let next_seq = (req.seq_number + 1U) & 0xFFFFU
  match req.opcode {
    OpenFileRO => {
      let path = bytes_to_ascii_path(req.data)
      for i = 0; i < self.files.length(); i = i + 1 {
        if self.files[i].path == path {
          self.open_file_idx = i
          let flen = self.files[i].content.length().reinterpret_as_uint()
          let size_bytes : Array[Byte] = [
            (flen & 0xFFU).to_byte(),
            ((flen >> 8) & 0xFFU).to_byte(),
            ((flen >> 16) & 0xFFU).to_byte(),
            ((flen >> 24) & 0xFFU).to_byte(),
          ]
          return {
            seq_number: next_seq,
            session: self.active_session,
            opcode: Ack,
            req_opcode: OpenFileRO,
            burst_complete: false,
            offset: 0U,
            data: Bytes::from_array(size_bytes),
          }
        }
      }
      {
        seq_number: next_seq,
        session: b'\x00',
        opcode: Nak,
        req_opcode: OpenFileRO,
        burst_complete: false,
        offset: 0U,
        data: b"\x0A", // FileNotFound (10)
      }
    }
    ReadFile => {
      if req.session != self.active_session ||
        self.open_file_idx < 0 ||
        self.open_file_idx >= self.files.length() {
        return {
          seq_number: next_seq,
          session: req.session,
          opcode: Nak,
          req_opcode: ReadFile,
          burst_complete: false,
          offset: req.offset,
          data: b"\x03", // InvalidSession (3)
        }
      }
      let content = self.files[self.open_file_idx].content
      let start = req.offset.reinterpret_as_int()
      if start < 0 || start >= content.length() {
        return {
          seq_number: next_seq,
          session: self.active_session,
          opcode: Nak,
          req_opcode: ReadFile,
          burst_complete: false,
          offset: req.offset,
          data: b"\x06", // EOF (6)
        }
      }
      let max_chunk = 64
      let end = if start + max_chunk < content.length() {
        start + max_chunk
      } else {
        content.length()
      }
      let chunk : Array[Byte] = Array(capacity=end - start)
      for i = start; i < end; i = i + 1 {
        chunk.push(content[i])
      }
      {
        seq_number: next_seq,
        session: self.active_session,
        opcode: Ack,
        req_opcode: ReadFile,
        burst_complete: end >= content.length(),
        offset: req.offset,
        data: Bytes::from_array(chunk),
      }
    }
    ListDirectory => {
      let out : Array[Byte] = []
      for f in self.files {
        let entry_str = "F" + f.path
        for ch in entry_str {
          out.push((ch.to_int() & 0xFF).to_byte())
        }
        out.push(b'\x00')
      }
      {
        seq_number: next_seq,
        session: b'\x00',
        opcode: Ack,
        req_opcode: ListDirectory,
        burst_complete: true,
        offset: req.offset,
        data: Bytes::from_array(out),
      }
    }
    TerminateSession | ResetSessions => {
      self.open_file_idx = -1
      {
        seq_number: next_seq,
        session: b'\x00',
        opcode: Ack,
        req_opcode: req.opcode,
        burst_complete: false,
        offset: 0U,
        data: b"",
      }
    }
    _ =>
      {
        seq_number: next_seq,
        session: req.session,
        opcode: Nak,
        req_opcode: req.opcode,
        burst_complete: false,
        offset: req.offset,
        data: b"\x05", // UnknownCommand
      }
  }
}
