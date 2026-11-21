///|
/// Learned routing table entry mapping a MAVLink `(sysid, compid)` address to a physical/logical link port.
pub(all) struct RouteEntry {
  sysid : Byte
  compid : Byte
  mut port_id : Int32
  mut frames_routed : Int32
} derive(Eq, Debug)

///|
pub extend RouteEntry with Eq::{not_equal, equal}

///|
pub extend RouteEntry with @debug.Debug::{to_repr}

///|
/// Extract the destination `(target_system, target_component)` pair from a `MavMessage`
/// if the message type carries explicit target addressing; returns `None` for broadcast
/// telemetry messages (such as `HEARTBEAT`, `ATTITUDE`, `GPS_RAW_INT`, `STATUSTEXT`).
pub fn extract_message_target(msg : MavMessage) -> (Byte, Byte)? {
  match msg {
    MsgPing(m) => Some((m.target_system, m.target_component))
    MsgSetMode(m) => Some((m.target_system, b'\x00'))
    MsgParamRequestRead(m) => Some((m.target_system, m.target_component))
    MsgParamRequestList(m) => Some((m.target_system, m.target_component))
    MsgParamSet(m) => Some((m.target_system, m.target_component))
    MsgMissionWritePartialList(m) => Some((m.target_system, m.target_component))
    MsgMissionItem(m) => Some((m.target_system, m.target_component))
    MsgMissionRequest(m) => Some((m.target_system, m.target_component))
    MsgMissionSetCurrent(m) => Some((m.target_system, m.target_component))
    MsgMissionRequestList(m) => Some((m.target_system, m.target_component))
    MsgMissionCount(m) => Some((m.target_system, m.target_component))
    MsgMissionClearAll(m) => Some((m.target_system, m.target_component))
    MsgMissionAck(m) => Some((m.target_system, m.target_component))
    MsgMissionRequestInt(m) => Some((m.target_system, m.target_component))
    MsgManualControl(m) => Some((m.target, b'\x00'))
    MsgMissionItemInt(m) => Some((m.target_system, m.target_component))
    MsgCommandInt(m) => Some((m.target_system, m.target_component))
    MsgCommandLong(m) => Some((m.target_system, m.target_component))
    MsgCommandAck(m) => Some((m.target_system, m.target_component))
    MsgCommandCancel(m) => Some((m.target_system, m.target_component))
    MsgSetAttitudeTarget(m) => Some((m.target_system, m.target_component))
    MsgSetPositionTargetLocalNed(m) =>
      Some((m.target_system, m.target_component))
    MsgFileTransferProtocol(m) => Some((m.target_system, m.target_component))
    MsgTimesync(m) => Some((m.target_system, m.target_component))
    MsgLoggingData(m) => Some((m.target_system, m.target_component))
    MsgLoggingAck(m) => Some((m.target_system, m.target_component))
    MsgParamExtRequestRead(m) => Some((m.target_system, m.target_component))
    MsgParamExtRequestList(m) => Some((m.target_system, m.target_component))
    MsgParamExtSet(m) => Some((m.target_system, m.target_component))
    _ => None
  }
}

///|
/// Multi-link MAVLink v2 packet router (modeled after `mavlink-router` / `MAVProxy`)
/// with automatic source-address learning, unicast target resolution, and split-horizon loop prevention.
pub(all) struct MavRouter {
  ports : Array[Int32]
  routes : Array[RouteEntry]
  mut unicast_forwarded : Int32
  mut broadcast_flooded : Int32
} derive(Eq, Debug)

///|
pub extend MavRouter with Eq::{not_equal, equal}

///|
pub extend MavRouter with @debug.Debug::{to_repr}

///|
/// Create a new `MavRouter` configured with a list of link port IDs (e.g. `[0, 1, 2]` for UART0, UART1, UDP0).
pub fn MavRouter::new(port_ids : Array[Int32]) -> MavRouter {
  let ports : Array[Int32] = []
  for p in port_ids {
    ports.push(p)
  }
  { ports, routes: [], unicast_forwarded: 0, broadcast_flooded: 0, }
}

///|
/// Learn or update the ingress `port_id` for `(sysid, compid)`.
pub fn MavRouter::learn_source(
  self : MavRouter,
  sysid : Byte,
  compid : Byte,
  port_id : Int32,
) -> Unit {
  for i = 0; i < self.routes.length(); i = i + 1 {
    if self.routes[i].sysid == sysid && self.routes[i].compid == compid {
      self.routes[i].port_id = port_id
      self.routes[i].frames_routed = self.routes[i].frames_routed + 1
      return ()
    }
  }
  self.routes.push({ sysid, compid, port_id, frames_routed: 1, })
}

///|
fn flood_other_ports(
  ports : Array[Int32],
  ingress_port : Int32,
) -> Array[Int32] {
  let out : Array[Int32] = []
  for p in ports {
    if p != ingress_port {
      out.push(p)
    }
  }
  out
}

///|
/// Compute the list of egress link port IDs to which an incoming `MavFrame` arriving on `ingress_port`
/// should be forwarded.
///
/// Rules:
/// 1. Records `(frame.header.sysid, frame.header.compid) -> ingress_port` in the routing table.
/// 2. If the message is broadcast (`target_system == 0` or untargeted telemetry), returns all ports except `ingress_port`.
/// 3. If the message targets a learned `(target_system, target_component)` (or `target_component == 0`),
///    forwards only to the matching egress port(s) (excluding `ingress_port`).
/// 4. If the target address has not yet been learned, falls back to flooding all non-ingress ports.
pub fn MavRouter::route_frame(
  self : MavRouter,
  ingress_port : Int32,
  frame : MavFrame,
) -> Array[Int32] {
  self.learn_source(frame.header.sysid, frame.header.compid, ingress_port)

  let target_opt = match MavMessage::decode_from_frame(frame) {
    Ok(msg) => extract_message_target(msg)
    Err(_) => None
  }

  match target_opt {
    None => {
      self.broadcast_flooded = self.broadcast_flooded + 1
      flood_other_ports(self.ports, ingress_port)
    }
    Some((target_sys, target_comp)) => {
      if target_sys == b'\x00' {
        self.broadcast_flooded = self.broadcast_flooded + 1
        return flood_other_ports(self.ports, ingress_port)
      }
      let matched_ports : Array[Int32] = []
      let mut target_known = false
      for r in self.routes {
        if r.sysid == target_sys &&
          (target_comp == b'\x00' || r.compid == target_comp) {
          target_known = true
          if r.port_id != ingress_port {
            let mut already = false
            for mp in matched_ports {
              if mp == r.port_id {
                already = true
                break
              }
            }
            if !already {
              matched_ports.push(r.port_id)
            }
          }
        }
      }
      if target_known {
        self.unicast_forwarded = self.unicast_forwarded + 1
        matched_ports
      } else {
        self.broadcast_flooded = self.broadcast_flooded + 1
        flood_other_ports(self.ports, ingress_port)
      }
    }
  }
}
