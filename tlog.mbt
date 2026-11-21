///|
/// Single timestamped MAVLink frame entry from a QGroundControl / MissionPlanner `.tlog` telemetry log.
pub(all) struct TlogEntry {
  timestamp_usec : UInt64
  frame : MavFrame
} derive(Eq, Debug)

///|
pub extend TlogEntry with Eq::{not_equal, equal}

///|
pub extend TlogEntry with @debug.Debug::{to_repr}

///|
/// Encode a single QGroundControl `.tlog` binary record:
/// 8-byte Big-Endian UNIX timestamp in microseconds (`uint64_t BE`) followed by the raw MAVLink wire frame.
pub fn encode_tlog_entry(timestamp_usec : UInt64, wire_frame : Bytes) -> Bytes {
  let buf : Array[Byte] = Array(capacity=8 + wire_frame.length())
  for shift = 56; shift >= 0; shift = shift - 8 {
    buf.push(((timestamp_usec >> shift) & 0xFFUL).to_byte())
  }
  for i = 0; i < wire_frame.length(); i = i + 1 {
    buf.push(wire_frame[i])
  }
  Bytes::from_array(buf)
}

///|
/// Read a 64-bit Big-Endian unsigned integer from `data[offset .. offset + 8]`.
fn read_be_uint64(data : Bytes, offset : Int32) -> UInt64 {
  let mut acc = 0UL
  for i = 0; i < 8; i = i + 1 {
    acc = (acc << 8) | (data[offset + i].to_uint64() & 0xFFUL)
  }
  acc
}

///|
/// Decode a complete QGroundControl / MissionPlanner `.tlog` binary byte stream into
/// an ordered array of `TlogEntry` records.
pub fn decode_tlog_stream(
  data : Bytes,
  crc_extra_lookup : (UInt32) -> Byte?,
  signing~ : SigningContext? = None,
) -> Result[Array[TlogEntry], MavError] {
  let entries : Array[TlogEntry] = []
  let mut pos = 0
  let total = data.length()

  while pos < total {
    if pos + 8 > total {
      return Err(IncompleteFrame(pos + 8, total))
    }
    let ts_usec = read_be_uint64(data, pos)
    pos = pos + 8
    let rem_len = total - pos
    let rem_buf : Array[Byte] = Array(capacity=rem_len)
    for i = 0; i < rem_len; i = i + 1 {
      rem_buf.push(data[pos + i])
    }
    match decode_frame(Bytes::from_array(rem_buf), crc_extra_lookup, signing~) {
      Ok((frame, consumed)) => {
        entries.push({ timestamp_usec: ts_usec, frame, })
        pos = pos + consumed
      }
      Err(e) => return Err(e)
    }
  }
  Ok(entries)
}

///|
/// Stateful QGroundControl `.tlog` binary telemetry recorder.
pub(all) struct TlogRecorder {
  buf : Array[Byte]
  mut entry_count : Int32
} derive(Eq, Debug)

///|
pub extend TlogRecorder with Eq::{not_equal, equal}

///|
pub extend TlogRecorder with @debug.Debug::{to_repr}

///|
/// Create a new `TlogRecorder`.
pub fn TlogRecorder::new() -> TlogRecorder {
  { buf: [], entry_count: 0, }
}

///|
/// Append an already-encoded MAVLink wire frame with a 64-bit microsecond UNIX timestamp.
pub fn TlogRecorder::record_wire_frame(
  self : TlogRecorder,
  timestamp_usec : UInt64,
  wire_frame : Bytes,
) -> Unit {
  for shift = 56; shift >= 0; shift = shift - 8 {
    self.buf.push(((timestamp_usec >> shift) & 0xFFUL).to_byte())
  }
  for i = 0; i < wire_frame.length(); i = i + 1 {
    self.buf.push(wire_frame[i])
  }
  self.entry_count = self.entry_count + 1
}

///|
/// Encode a `MavMessage` and append it to the `.tlog` buffer with `timestamp_usec`.
pub fn TlogRecorder::record_message(
  self : TlogRecorder,
  timestamp_usec : UInt64,
  msg : MavMessage,
  seq~ : Byte,
  sysid~ : Byte,
  compid~ : Byte,
  version~ : ProtocolVersion = V2,
  signing~ : SigningContext? = None,
) -> Result[Unit, MavError] {
  match msg.encode_to_frame(seq~, sysid~, compid~, version~, signing~) {
    Ok((wire, _)) => {
      self.record_wire_frame(timestamp_usec, wire)
      Ok(())
    }
    Err(e) => Err(e)
  }
}

///|
/// Export the accumulated `.tlog` binary stream as `Bytes`.
pub fn TlogRecorder::to_bytes(self : TlogRecorder) -> Bytes {
  Bytes::from_array(self.buf)
}

///|
/// Filter `.tlog` entries within the inclusive timestamp interval `[start_usec, end_usec]`.
pub fn filter_tlog_by_time_range(
  entries : Array[TlogEntry],
  start_usec : UInt64,
  end_usec : UInt64,
) -> Array[TlogEntry] {
  let out : Array[TlogEntry] = []
  for e in entries {
    if e.timestamp_usec >= start_usec && e.timestamp_usec <= end_usec {
      out.push(e)
    }
  }
  out
}

///|
/// Filter `.tlog` entries matching a specific 24-bit MAVLink `msgid`.
pub fn filter_tlog_by_msgid(
  entries : Array[TlogEntry],
  msgid : UInt32,
) -> Array[TlogEntry] {
  let out : Array[TlogEntry] = []
  for e in entries {
    if e.frame.header.msgid == msgid {
      out.push(e)
    }
  }
  out
}
