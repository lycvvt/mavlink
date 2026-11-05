///|
/// Encode a MAVLink v1 or v2 packet into wire bytes, computing the X.25 CRC-16 with `crc_extra`
/// and optionally appending a 13-byte MAVLink v2 signature when `signing` is provided.
pub fn encode_frame(
  header : MavHeader,
  raw_payload : Bytes,
  crc_extra : Byte,
  truncate_v2_zeros~ : Bool = true,
  signing~ : SigningContext? = None,
) -> Result[(Bytes, MavFrame), MavError] {
  if raw_payload.length() > MAX_PAYLOAD_LEN {
    return Err(PayloadTooLarge(raw_payload.length()))
  }
  match header.version {
    V1 => {
      if header.msgid > 255U {
        return Err(UnsupportedV1MessageId(header.msgid))
      }
      let payload_len = raw_payload.length()
      let body_writer = PayloadWriter::new(capacity=V1_HEADER_LEN + payload_len)
      body_writer.write_uint8(payload_len.to_byte())
      body_writer.write_uint8(header.seq)
      body_writer.write_uint8(header.sysid)
      body_writer.write_uint8(header.compid)
      body_writer.write_uint8((header.msgid & 0xFFU).to_byte())
      body_writer.write_bytes(raw_payload)
      let body_bytes = body_writer.to_bytes()
      let checksum = crc16_calculate_with_extra(body_bytes, crc_extra)

      let wire_writer = PayloadWriter::new(
        capacity=1 + body_bytes.length() + 2,
      )
      wire_writer.write_uint8(MAVLINK_STX_V1)
      wire_writer.write_bytes(body_bytes)
      wire_writer.write_uint16(checksum)
      let frame : MavFrame = {
        header,
        payload: raw_payload,
        checksum,
        signature: None,
      }
      Ok((wire_writer.to_bytes(), frame))
    }
    V2 => {
      if header.msgid > 0xFFFFFFU {
        return Err(UnsupportedV1MessageId(header.msgid))
      }
      let payload = if truncate_v2_zeros {
        truncate_trailing_zeros(raw_payload)
      } else {
        raw_payload
      }
      let payload_len = payload.length()
      let effective_incompat = match signing {
        Some(_) =>
          (header.incompat_flags.to_uint() | IFLAG_SIGNED.to_uint()).to_byte()
        None => header.incompat_flags
      }
      let body_writer = PayloadWriter::new(capacity=V2_HEADER_LEN + payload_len)
      body_writer.write_uint8(payload_len.to_byte())
      body_writer.write_uint8(effective_incompat)
      body_writer.write_uint8(header.compat_flags)
      body_writer.write_uint8(header.seq)
      body_writer.write_uint8(header.sysid)
      body_writer.write_uint8(header.compid)
      body_writer.write_uint24(header.msgid)
      body_writer.write_bytes(payload)
      let body_bytes = body_writer.to_bytes()
      let checksum = crc16_calculate_with_extra(body_bytes, crc_extra)

      let unsigned_writer = PayloadWriter::new(
        capacity=1 + body_bytes.length() + 2,
      )
      unsigned_writer.write_uint8(MAVLINK_STX_V2)
      unsigned_writer.write_bytes(body_bytes)
      unsigned_writer.write_uint16(checksum)
      let unsigned_bytes = unsigned_writer.to_bytes()

      let effective_header : MavHeader = {
        ..header,
        incompat_flags: effective_incompat,
      }
      match signing {
        Some(ctx) => {
          let sig = ctx.sign_frame_bytes(unsigned_bytes)
          let signed_writer = PayloadWriter::new(
            capacity=unsigned_bytes.length() + V2_SIGNATURE_LEN,
          )
          signed_writer.write_bytes(unsigned_bytes)
          signed_writer.write_uint8(sig.link_id)
          for shift = 0; shift < 48; shift = shift + 8 {
            signed_writer.write_uint8(
              ((sig.timestamp >> shift) & 0xFFUL).to_byte(),
            )
          }
          for i = 0; i < 6; i = i + 1 {
            signed_writer.write_uint8(sig.signature[i])
          }
          let frame : MavFrame = {
            header: effective_header,
            payload,
            checksum,
            signature: Some(sig),
          }
          Ok((signed_writer.to_bytes(), frame))
        }
        None => {
          let frame : MavFrame = {
            header: effective_header,
            payload,
            checksum,
            signature: None,
          }
          Ok((unsigned_bytes, frame))
        }
      }
    }
  }
}

///|
/// Decode a single MAVLink v1 or v2 frame from `wire` starting at byte offset `start`.
/// Returns `(decoded_frame, bytes_consumed)` on success.
pub fn decode_frame(
  wire : Bytes,
  crc_extra_lookup : (UInt) -> Byte?,
  start~ : Int = 0,
  signing~ : SigningContext? = None,
) -> Result[(MavFrame, Int), MavError] {
  let avail = wire.length() - start
  if avail <= 0 {
    return Err(IncompleteFrame(1, 0))
  }
  let stx = wire[start]
  if stx == MAVLINK_STX_V1 {
    if avail < 1 + V1_HEADER_LEN + 2 {
      return Err(IncompleteFrame(1 + V1_HEADER_LEN + 2, avail))
    }
    let payload_len = wire[start + 1].to_int() & 0xFF
    let total_len = 1 + V1_HEADER_LEN + payload_len + 2
    if avail < total_len {
      return Err(IncompleteFrame(total_len, avail))
    }
    let seq = wire[start + 2]
    let sysid = wire[start + 3]
    let compid = wire[start + 4]
    let msgid = wire[start + 5].to_uint() & 0xFFU

    let crc_extra = match crc_extra_lookup(msgid) {
      Some(ce) => ce
      None => return Err(UnknownMessageId(msgid))
    }
    let crc = X25Crc::new()
    crc.accumulate_bytes(wire, start=start + 1, len=V1_HEADER_LEN + payload_len)
    crc.accumulate_byte(crc_extra)
    let crc_offset = start + 1 + V1_HEADER_LEN + payload_len
    let wire_crc = wire[crc_offset].to_uint() |
      (wire[crc_offset + 1].to_uint() << 8)
    if crc.value != wire_crc {
      return Err(CrcMismatch(crc.value, wire_crc))
    }
    let payload_arr : Array[Byte] = Array(capacity=payload_len)
    for i = 0; i < payload_len; i = i + 1 {
      payload_arr.push(wire[start + 1 + V1_HEADER_LEN + i])
    }
    let header = MavHeader::new_v1(seq~, sysid~, compid~, msgid~)
    let frame : MavFrame = {
      header,
      payload: Bytes::from_array(payload_arr),
      checksum: wire_crc,
      signature: None,
    }
    Ok((frame, total_len))
  } else if stx == MAVLINK_STX_V2 {
    if avail < 1 + V2_HEADER_LEN + 2 {
      return Err(IncompleteFrame(1 + V2_HEADER_LEN + 2, avail))
    }
    let payload_len = wire[start + 1].to_int() & 0xFF
    let incompat_flags = wire[start + 2]
    let compat_flags = wire[start + 3]
    if (incompat_flags.to_uint() & IFLAG_SIGNED.to_uint().lnot() & 0xFFU) != 0U {
      return Err(UnsupportedIncompatFlags(incompat_flags))
    }
    let is_signed = (incompat_flags.to_uint() & IFLAG_SIGNED.to_uint()) != 0U
    let sig_len = if is_signed { V2_SIGNATURE_LEN } else { 0 }
    let unsigned_len = 1 + V2_HEADER_LEN + payload_len + 2
    let total_len = unsigned_len + sig_len
    if avail < total_len {
      return Err(IncompleteFrame(total_len, avail))
    }
    let seq = wire[start + 4]
    let sysid = wire[start + 5]
    let compid = wire[start + 6]
    let msgid = wire[start + 7].to_uint() |
      (wire[start + 8].to_uint() << 8) |
      (wire[start + 9].to_uint() << 16)

    let crc_extra = match crc_extra_lookup(msgid) {
      Some(ce) => ce
      None => return Err(UnknownMessageId(msgid))
    }
    let crc = X25Crc::new()
    crc.accumulate_bytes(wire, start=start + 1, len=V2_HEADER_LEN + payload_len)
    crc.accumulate_byte(crc_extra)
    let crc_offset = start + 1 + V2_HEADER_LEN + payload_len
    let wire_crc = wire[crc_offset].to_uint() |
      (wire[crc_offset + 1].to_uint() << 8)
    if crc.value != wire_crc {
      return Err(CrcMismatch(crc.value, wire_crc))
    }
    let payload_arr : Array[Byte] = Array(capacity=payload_len)
    for i = 0; i < payload_len; i = i + 1 {
      payload_arr.push(wire[start + 1 + V2_HEADER_LEN + i])
    }
    let signature = if is_signed {
      let sig_offset = start + unsigned_len
      let link_id = wire[sig_offset]
      let mut ts = 0UL
      for i = 0; i < 6; i = i + 1 {
        ts = ts | (wire[sig_offset + 1 + i].to_uint64() << (i * 8))
      }
      let sig_bytes = FixedArray::make(6, b'\x00')
      for i = 0; i < 6; i = i + 1 {
        sig_bytes[i] = wire[sig_offset + 7 + i]
      }
      let parsed_sig : MavSignature = {
        link_id,
        timestamp: ts,
        signature: sig_bytes,
      }
      match signing {
        Some(ctx) => {
          let unsigned_arr : Array[Byte] = Array(capacity=unsigned_len)
          for i = 0; i < unsigned_len; i = i + 1 {
            unsigned_arr.push(wire[start + i])
          }
          match
            ctx.verify_frame_signature(
              Bytes::from_array(unsigned_arr),
              parsed_sig,
            ) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
        None => ()
      }
      Some(parsed_sig)
    } else {
      match signing {
        Some(_) => return Err(SignatureMissing)
        None => None
      }
    }
    let header = MavHeader::new_v2(
      seq~,
      sysid~,
      compid~,
      msgid~,
      incompat_flags~,
      compat_flags~,
    )
    let frame : MavFrame = {
      header,
      payload: Bytes::from_array(payload_arr),
      checksum: wire_crc,
      signature,
    }
    Ok((frame, total_len))
  } else {
    Err(InvalidMagic(stx))
  }
}

///|
/// Streaming parser event emitted when feeding arbitrary byte chunks.
pub(all) enum ParseStreamEvent {
  FrameDecoded(MavFrame)
  FrameError(MavError)
} derive(Eq, Debug)

///|
pub extend ParseStreamEvent with Eq::{not_equal, equal}

///|
pub extend ParseStreamEvent with @debug.Debug::{to_repr}

///|
/// Stateful streaming MAVLink v1/v2 frame parser with noise recovery,
/// partial-packet buffering, and sequence-gap packet-drop tracking.
pub(all) struct FrameParser {
  buffer : Array[Byte]
  mut packets_received : UInt
  mut packets_dropped : UInt
  mut crc_errors : UInt
  mut noise_bytes_skipped : UInt
  mut last_seq : Int
} derive(Eq, Debug)

///|
pub extend FrameParser with Eq::{not_equal, equal}

///|
pub extend FrameParser with @debug.Debug::{to_repr}

///|
/// Create a new streaming `FrameParser`.
pub fn FrameParser::new() -> FrameParser {
  {
    buffer: [],
    packets_received: 0U,
    packets_dropped: 0U,
    crc_errors: 0U,
    noise_bytes_skipped: 0U,
    last_seq: -1,
  }
}

///|
fn FrameParser::discard_prefix(self : FrameParser, count : Int) -> Unit {
  if count <= 0 {
    return
  }
  let remaining = self.buffer.length() - count
  if remaining <= 0 {
    self.buffer.clear()
    return
  }
  for i = 0; i < remaining; i = i + 1 {
    self.buffer[i] = self.buffer[i + count]
  }
  while self.buffer.length() > remaining {
    let _ = self.buffer.pop()
  }
}

///|
/// Feed a chunk of incoming bytes (e.g. from UART or UDP) into the parser and return
/// all decoded frames and protocol errors encountered.
pub fn FrameParser::push_bytes(
  self : FrameParser,
  chunk : Bytes,
  crc_extra_lookup : (UInt) -> Byte?,
  signing~ : SigningContext? = None,
) -> Array[ParseStreamEvent] {
  for i = 0; i < chunk.length(); i = i + 1 {
    self.buffer.push(chunk[i])
  }
  let events : Array[ParseStreamEvent] = []
  while self.buffer.length() > 0 {
    let stx = self.buffer[0]
    if stx != MAVLINK_STX_V1 && stx != MAVLINK_STX_V2 {
      self.noise_bytes_skipped = self.noise_bytes_skipped + 1U
      self.discard_prefix(1)
      continue
    }
    let snapshot = Bytes::from_array(self.buffer)
    match decode_frame(snapshot, crc_extra_lookup, signing~) {
      Ok((frame, consumed)) => {
        let cur_seq = frame.header.seq.to_int() & 0xFF
        if self.last_seq >= 0 {
          let expected_seq = (self.last_seq + 1) & 0xFF
          if cur_seq != expected_seq {
            let gap = (cur_seq - expected_seq + 256) & 0xFF
            self.packets_dropped = self.packets_dropped +
              gap.reinterpret_as_uint()
          }
        }
        self.last_seq = cur_seq
        self.packets_received = self.packets_received + 1U
        self.discard_prefix(consumed)
        events.push(FrameDecoded(frame))
      }
      Err(IncompleteFrame(_, _)) => break
      Err(CrcMismatch(expected, actual)) => {
        self.crc_errors = self.crc_errors + 1U
        self.discard_prefix(1)
        events.push(FrameError(CrcMismatch(expected, actual)))
      }
      Err(other_err) => {
        self.discard_prefix(1)
        events.push(FrameError(other_err))
      }
    }
  }
  events
}
