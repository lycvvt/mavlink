///|
/// Little-endian binary buffer builder for MAVLink message payloads.
pub(all) struct PayloadWriter {
  buf : Array[Byte]
} derive(Eq, Debug)

///|
pub extend PayloadWriter with Eq::{not_equal, equal}

///|
pub extend PayloadWriter with @debug.Debug::{to_repr}

///|
/// Create a new payload writer with optional initial capacity.
pub fn PayloadWriter::new(capacity~ : Int = 64) -> PayloadWriter {
  { buf: Array(capacity~) }
}

///|
/// Current byte length written so far.
pub fn PayloadWriter::length(self : PayloadWriter) -> Int {
  self.buf.length()
}

///|
/// Write a single unsigned 8-bit integer (`uint8_t`).
pub fn PayloadWriter::write_uint8(self : PayloadWriter, v : Byte) -> Unit {
  self.buf.push(v)
}

///|
/// Write a single signed 8-bit integer (`int8_t` represented as `Int`).
pub fn PayloadWriter::write_int8(self : PayloadWriter, v : Int) -> Unit {
  self.buf.push((v & 0xFF).to_byte())
}

///|
/// Write a 16-bit unsigned integer (`uint16_t`, little-endian).
pub fn PayloadWriter::write_uint16(self : PayloadWriter, v : UInt) -> Unit {
  self.buf.push((v & 0xFFU).to_byte())
  self.buf.push(((v >> 8) & 0xFFU).to_byte())
}

///|
/// Write a 16-bit signed integer (`int16_t` represented as `Int`, little-endian).
pub fn PayloadWriter::write_int16(self : PayloadWriter, v : Int) -> Unit {
  let u = v.reinterpret_as_uint()
  self.write_uint16(u)
}

///|
/// Write a 24-bit unsigned integer (`uint24_t`, used for MAVLink v2 message IDs, little-endian).
pub fn PayloadWriter::write_uint24(self : PayloadWriter, v : UInt) -> Unit {
  self.buf.push((v & 0xFFU).to_byte())
  self.buf.push(((v >> 8) & 0xFFU).to_byte())
  self.buf.push(((v >> 16) & 0xFFU).to_byte())
}

///|
/// Write a 32-bit unsigned integer (`uint32_t`, little-endian).
pub fn PayloadWriter::write_uint32(self : PayloadWriter, v : UInt) -> Unit {
  self.buf.push((v & 0xFFU).to_byte())
  self.buf.push(((v >> 8) & 0xFFU).to_byte())
  self.buf.push(((v >> 16) & 0xFFU).to_byte())
  self.buf.push(((v >> 24) & 0xFFU).to_byte())
}

///|
/// Write a 32-bit signed integer (`int32_t`, little-endian).
pub fn PayloadWriter::write_int32(self : PayloadWriter, v : Int) -> Unit {
  self.write_uint32(v.reinterpret_as_uint())
}

///|
/// Write a 64-bit unsigned integer (`uint64_t`, little-endian).
pub fn PayloadWriter::write_uint64(self : PayloadWriter, v : UInt64) -> Unit {
  for shift = 0; shift < 64; shift = shift + 8 {
    self.buf.push(((v >> shift) & 0xFFUL).to_byte())
  }
}

///|
/// Write a 64-bit signed integer (`int64_t`, little-endian).
pub fn PayloadWriter::write_int64(self : PayloadWriter, v : Int64) -> Unit {
  self.write_uint64(v.reinterpret_as_uint64())
}

///|
/// Write an IEEE-754 32-bit floating-point number (`float`, little-endian).
pub fn PayloadWriter::write_float(self : PayloadWriter, v : Float) -> Unit {
  self.write_uint32(v.reinterpret_as_uint())
}

///|
/// Write an IEEE-754 64-bit floating-point number (`double`, little-endian).
pub fn PayloadWriter::write_double(self : PayloadWriter, v : Double) -> Unit {
  self.write_uint64(v.reinterpret_as_uint64())
}

///|
/// Write a fixed-length `char[fixed_len]` field, padding with trailing `0x00` bytes
/// or truncating if `s` exceeds `fixed_len` bytes.
pub fn PayloadWriter::write_char_array(
  self : PayloadWriter,
  s : String,
  fixed_len : Int,
) -> Unit {
  let chars = s.to_array()
  for i = 0; i < fixed_len; i = i + 1 {
    if i < chars.length() {
      let code = chars[i].to_int() & 0xFF
      self.buf.push(code.to_byte())
    } else {
      self.buf.push(b'\x00')
    }
  }
}

///|
/// Write raw bytes directly into the payload buffer.
pub fn PayloadWriter::write_bytes(self : PayloadWriter, data : Bytes) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.buf.push(data[i])
  }
}

///|
/// Convert the buffer into raw `Bytes` without MAVLink v2 zero-truncation.
pub fn PayloadWriter::to_bytes(self : PayloadWriter) -> Bytes {
  Bytes::from_array(self.buf)
}

///|
/// Convert the buffer into `Bytes`, applying MAVLink v2 trailing zero-byte truncation
/// when `truncate_zeros` is `true`.
///
/// Per official MAVLink v2 specification:
/// - Trailing `0x00` bytes at the end of the serialized payload are stripped.
/// - The very first byte of a non-empty payload is NEVER removed, even if all bytes are `0x00`.
pub fn PayloadWriter::to_wire_bytes(
  self : PayloadWriter,
  truncate_zeros~ : Bool = true,
) -> Bytes {
  if !truncate_zeros || self.buf.length() == 0 {
    return Bytes::from_array(self.buf)
  }
  let mut effective_len = self.buf.length()
  while effective_len > 1 && self.buf[effective_len - 1] == b'\x00' {
    effective_len = effective_len - 1
  }
  let trimmed : Array[Byte] = Array(capacity=effective_len)
  for i = 0; i < effective_len; i = i + 1 {
    trimmed.push(self.buf[i])
  }
  Bytes::from_array(trimmed)
}

///|
/// Apply MAVLink v2 trailing zero-byte truncation to an existing `Bytes` payload.
pub fn truncate_trailing_zeros(payload : Bytes) -> Bytes {
  if payload.length() <= 1 {
    return payload
  }
  let mut effective_len = payload.length()
  while effective_len > 1 && payload[effective_len - 1] == b'\x00' {
    effective_len = effective_len - 1
  }
  if effective_len == payload.length() {
    return payload
  }
  let trimmed : Array[Byte] = Array(capacity=effective_len)
  for i = 0; i < effective_len; i = i + 1 {
    trimmed.push(payload[i])
  }
  Bytes::from_array(trimmed)
}

///|
/// Little-endian binary reader for MAVLink payloads with automatic MAVLink v2
/// zero-extension for truncated trailing bytes and extension fields.
pub(all) struct PayloadReader {
  data : Bytes
  mut pos : Int
  zero_extend : Bool
} derive(Eq, Debug)

///|
pub extend PayloadReader with Eq::{not_equal, equal}

///|
pub extend PayloadReader with @debug.Debug::{to_repr}

///|
/// Create a new `PayloadReader`. When `zero_extend` is `true` (default for MAVLink v2),
/// reads beyond `data.length()` transparently return `0x00`.
pub fn PayloadReader::new(
  data : Bytes,
  zero_extend~ : Bool = true,
) -> PayloadReader {
  { data, pos: 0, zero_extend }
}

///|
/// Read a single byte at the current cursor position.
pub fn PayloadReader::read_byte(self : PayloadReader) -> Result[Byte, MavError] {
  if self.pos < self.data.length() {
    let b = self.data[self.pos]
    self.pos = self.pos + 1
    Ok(b)
  } else if self.zero_extend {
    self.pos = self.pos + 1
    Ok(b'\x00')
  } else {
    Err(PayloadTooShort(self.pos + 1, self.data.length()))
  }
}

///|
/// Read an unsigned 8-bit integer (`uint8_t`).
pub fn PayloadReader::read_uint8(
  self : PayloadReader,
) -> Result[Byte, MavError] {
  self.read_byte()
}

///|
/// Read a signed 8-bit integer (`int8_t`) sign-extended to `Int`.
pub fn PayloadReader::read_int8(self : PayloadReader) -> Result[Int, MavError] {
  match self.read_byte() {
    Ok(b) => {
      let u = b.to_int() & 0xFF
      Ok(if u >= 128 { u - 256 } else { u })
    }
    Err(e) => Err(e)
  }
}

///|
/// Read a 16-bit unsigned integer (`uint16_t`, little-endian).
pub fn PayloadReader::read_uint16(
  self : PayloadReader,
) -> Result[UInt, MavError] {
  let b0 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  let b1 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  Ok(b0 | (b1 << 8))
}

///|
/// Read a 16-bit signed integer (`int16_t`, little-endian) sign-extended to `Int`.
pub fn PayloadReader::read_int16(self : PayloadReader) -> Result[Int, MavError] {
  match self.read_uint16() {
    Ok(u) => {
      let iv = u.reinterpret_as_int()
      Ok(if iv >= 32768 { iv - 65536 } else { iv })
    }
    Err(e) => Err(e)
  }
}

///|
/// Read a 32-bit unsigned integer (`uint32_t`, little-endian).
pub fn PayloadReader::read_uint32(
  self : PayloadReader,
) -> Result[UInt, MavError] {
  let b0 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  let b1 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  let b2 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  let b3 = match self.read_byte() {
    Ok(v) => v.to_uint()
    Err(e) => return Err(e)
  }
  Ok(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
}

///|
/// Read a 32-bit signed integer (`int32_t`, little-endian).
pub fn PayloadReader::read_int32(self : PayloadReader) -> Result[Int, MavError] {
  match self.read_uint32() {
    Ok(u) => Ok(u.reinterpret_as_int())
    Err(e) => Err(e)
  }
}

///|
/// Read a 64-bit unsigned integer (`uint64_t`, little-endian).
pub fn PayloadReader::read_uint64(
  self : PayloadReader,
) -> Result[UInt64, MavError] {
  let mut acc = 0UL
  for shift = 0; shift < 64; shift = shift + 8 {
    match self.read_byte() {
      Ok(b) => acc = acc | (b.to_uint64() << shift)
      Err(e) => return Err(e)
    }
  }
  Ok(acc)
}

///|
/// Read a 64-bit signed integer (`int64_t`, little-endian).
pub fn PayloadReader::read_int64(
  self : PayloadReader,
) -> Result[Int64, MavError] {
  match self.read_uint64() {
    Ok(u) => Ok(u.reinterpret_as_int64())
    Err(e) => Err(e)
  }
}

///|
/// Read an IEEE-754 32-bit floating-point number (`float`, little-endian).
pub fn PayloadReader::read_float(
  self : PayloadReader,
) -> Result[Float, MavError] {
  match self.read_uint32() {
    Ok(u) => Ok(Float::reinterpret_from_uint(u))
    Err(e) => Err(e)
  }
}

///|
/// Read an IEEE-754 64-bit floating-point number (`double`, little-endian).
pub fn PayloadReader::read_double(
  self : PayloadReader,
) -> Result[Double, MavError] {
  match self.read_uint64() {
    Ok(u) => Ok(u.reinterpret_as_double())
    Err(e) => Err(e)
  }
}

///|
/// Read a fixed-length `char[fixed_len]` field, stopping string construction at the first NUL (`0x00`)
/// while advancing the cursor by the full `fixed_len` bytes.
pub fn PayloadReader::read_char_array(
  self : PayloadReader,
  fixed_len : Int,
) -> Result[String, MavError] {
  let sb = StringBuilder()
  let mut nul_seen = false
  for i = 0; i < fixed_len; i = i + 1 {
    match self.read_byte() {
      Ok(b) =>
        if b == b'\x00' {
          nul_seen = true
        } else if !nul_seen {
          sb.write_char(Int::unsafe_to_char(b.to_int() & 0xFF))
        }
      Err(e) => return Err(e)
    }
  }
  Ok(sb.to_string())
}
