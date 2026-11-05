///|
/// Initial seed value for MAVLink X.25 CRC-16-MCRF4XX calculation.
pub const X25_INIT_CRC : UInt32 = 0xFFFFU

///|
/// Stateful X.25 CRC-16-MCRF4XX accumulator used by MAVLink v1 and v2.
pub(all) struct X25Crc {
  mut value : UInt32
} derive(Eq, Debug)

///|
pub extend X25Crc with Eq::{not_equal, equal}

///|
pub extend X25Crc with @debug.Debug::{to_repr}

///|
/// Create a new X.25 CRC accumulator initialized to `0xFFFF`.
pub fn X25Crc::new() -> X25Crc {
  { value: X25_INIT_CRC, }
}

///|
/// Reset the accumulator to `0xFFFF`.
pub fn X25Crc::reset(self : X25Crc) -> Unit {
  self.value = X25_INIT_CRC
}

///|
/// Accumulate a single byte into the X.25 CRC-16 state.
pub fn X25Crc::accumulate_byte(self : X25Crc, b : Byte) -> Unit {
  let byte_val = b.to_uint() & 0xFFU
  let mut tmp = byte_val ^ (self.value & 0xFFU)
  tmp = (tmp ^ (tmp << 4)) & 0xFFU
  self.value = ((self.value >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) &
    0xFFFFU
}

///|
/// Accumulate a slice of bytes into the X.25 CRC-16 state.
pub fn X25Crc::accumulate_bytes(
  self : X25Crc,
  data : Bytes,
  start~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Unit {
  let actual_len = if len < 0 { data.length() - start } else { len }
  for i = 0; i < actual_len; i = i + 1 {
    self.accumulate_byte(data[start + i])
  }
}

///|
/// Accumulate an ASCII string into the X.25 CRC-16 state.
pub fn X25Crc::accumulate_ascii(self : X25Crc, text : String) -> Unit {
  for ch in text {
    self.accumulate_byte((ch.to_int() & 0xFF).to_byte())
  }
}

///|
/// Return the low byte of the 16-bit CRC.
pub fn X25Crc::low_byte(self : X25Crc) -> Byte {
  (self.value & 0xFFU).to_byte()
}

///|
/// Return the high byte of the 16-bit CRC.
pub fn X25Crc::high_byte(self : X25Crc) -> Byte {
  ((self.value >> 8) & 0xFFU).to_byte()
}

///|
/// Fold the 16-bit CRC into a 1-byte `CRC_EXTRA` value: `(crc & 0xFF) ^ (crc >> 8)`.
pub fn X25Crc::to_crc_extra(self : X25Crc) -> Byte {
  (((self.value & 0xFFU) ^ (self.value >> 8)) & 0xFFU).to_byte()
}

///|
/// Compute the X.25 CRC-16 over a byte buffer.
pub fn crc16_calculate(data : Bytes) -> UInt32 {
  let crc = X25Crc::new()
  crc.accumulate_bytes(data)
  crc.value
}

///|
/// Compute the MAVLink frame checksum over header/payload bytes plus the message `crc_extra` byte.
pub fn crc16_calculate_with_extra(data : Bytes, crc_extra : Byte) -> UInt32 {
  let crc = X25Crc::new()
  crc.accumulate_bytes(data)
  crc.accumulate_byte(crc_extra)
  crc.value
}

///|
/// Field descriptor used for MAVLink wire ordering and `CRC_EXTRA` computation.
pub(all) struct CrcFieldSpec {
  wire_type : String
  name : String
  is_extension : Bool
} derive(Eq, Debug)

///|
pub extend CrcFieldSpec with Eq::{not_equal, equal}

///|
pub extend CrcFieldSpec with @debug.Debug::{to_repr}

///|
/// Construct a field specification for `CRC_EXTRA` calculation.
pub fn CrcFieldSpec::new(
  wire_type : String,
  name : String,
  is_extension~ : Bool = false,
) -> CrcFieldSpec {
  { wire_type, name, is_extension, }
}

///|
/// Return the element byte width of a MAVLink primitive type name.
pub fn primitive_type_size(base_type : String) -> Result[Int32, MavError] {
  match base_type {
    "uint64_t" | "int64_t" | "double" => Ok(8)
    "uint32_t" | "int32_t" | "float" => Ok(4)
    "uint16_t" | "int16_t" => Ok(2)
    "uint8_t" | "int8_t" | "char" | "uint8_t_mavlink_version" => Ok(1)
    _ => Err(SchemaError("Unknown MAVLink field base type: " + base_type))
  }
}

///|
/// Parse a MAVLink type string (e.g. `"uint16_t[4]"` or `"uint8_t_mavlink_version"`)
/// into `(normalized_base_type, element_size_bytes, array_len)`.
/// For scalar fields, `array_len` is `0`.
pub fn parse_wire_type_spec(
  wire_type : String,
) -> Result[(String, Int32, Int32), MavError] {
  let mut bracket_pos = -1
  let mut close_pos = -1
  let chars = wire_type.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '[' {
      bracket_pos = i
    } else if chars[i] == ']' {
      close_pos = i
    }
  }
  let (raw_base, arr_len) = if bracket_pos >= 0 {
    if close_pos <= bracket_pos + 1 {
      return Err(
        SchemaError("Malformed array type specification: " + wire_type),
      )
    }
    let base_buf = StringBuilder()
    for i = 0; i < bracket_pos; i = i + 1 {
      base_buf.write_char(chars[i])
    }
    let mut len_val = 0
    for i = bracket_pos + 1; i < close_pos; i = i + 1 {
      let c = chars[i]
      if c < '0' || c > '9' {
        return Err(
          SchemaError("Non-numeric array length in type: " + wire_type),
        )
      }
      len_val = len_val * 10 + (c.to_int() - '0'.to_int())
    }
    if len_val <= 0 || len_val > 255 {
      return Err(
        SchemaError("Array length out of valid range (1..255): " + wire_type),
      )
    }
    (base_buf.to_string(), len_val)
  } else {
    (wire_type, 0)
  }
  let size = match primitive_type_size(raw_base) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let norm_base = if raw_base == "uint8_t_mavlink_version" {
    "uint8_t"
  } else {
    raw_base
  }
  Ok((norm_base, size, arr_len))
}

///|
/// Calculate the official MAVLink `CRC_EXTRA` seed byte for a message definition.
///
/// Follows the official MAVLink specification:
/// 1. Only non-extension fields (`is_extension == false`) are included.
/// 2. Fields are stably sorted in descending order of their primitive element byte width (8, 4, 2, 1).
/// 3. The message name (uppercase + trailing space) is accumulated first.
/// 4. Each sorted field accumulates `"<normalized_base_type> <field_name> "`, followed by
///    `array_length` as a single byte if the field is a fixed-length array.
/// 5. The resulting 16-bit X.25 CRC is folded via `(crc & 0xFF) ^ (crc >> 8)`.
pub fn compute_crc_extra(
  message_name : String,
  fields : Array[CrcFieldSpec],
) -> Result[Byte, MavError] {
  let parsed : Array[(Int32, Int32, String, String, Int32)] = []
  for i = 0; i < fields.length(); i = i + 1 {
    let f = fields[i]
    if !f.is_extension {
      match parse_wire_type_spec(f.wire_type) {
        Ok((norm_base, elem_size, arr_len)) =>
          parsed.push((elem_size, i, norm_base, f.name, arr_len))
        Err(e) => return Err(e)
      }
    }
  }
  // Stable sort by element size descending (8 -> 4 -> 2 -> 1), then original index ascending
  parsed.sort_by(fn(a, b) {
    if a.0 != b.0 {
      b.0.compare(a.0)
    } else {
      a.1.compare(b.1)
    }
  })
  let crc = X25Crc::new()
  crc.accumulate_ascii(message_name + " ")
  for item in parsed {
    let (_, _, norm_base, field_name, arr_len) = item
    crc.accumulate_ascii(norm_base + " " + field_name + " ")
    if arr_len > 0 {
      crc.accumulate_byte(arr_len.to_byte())
    }
  }
  Ok(crc.to_crc_extra())
}
