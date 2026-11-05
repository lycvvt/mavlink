///|
/// Convert an `UPPER_SNAKE_CASE` or `snake_case` identifier to `PascalCase`.
pub fn to_pascal_case(raw : String) -> String {
  let chars = raw.to_array()
  let sb = StringBuilder()
  let mut cap_next = true
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '_' || c == '-' || c == ' ' {
      cap_next = true
    } else if cap_next {
      if c >= 'a' && c <= 'z' {
        sb.write_char(Int32::unsafe_to_char(c.to_int() - 32))
      } else {
        sb.write_char(c)
      }
      cap_next = false
    } else if c >= 'A' && c <= 'Z' {
      sb.write_char(Int32::unsafe_to_char(c.to_int() + 32))
    } else {
      sb.write_char(c)
    }
  }
  let res = sb.to_string()
  let res_chars = res.to_array()
  if res_chars.length() > 0 && res_chars[0] >= '0' && res_chars[0] <= '9' {
    "V" + res
  } else if res == "" {
    "Unnamed"
  } else {
    res
  }
}

///|
/// Sanitize a MAVLink XML field name so that MoonBit reserved keywords (such as `type`)
/// become valid struct field identifiers.
pub fn sanitize_field_name(name : String) -> String {
  match name {
    "type" => "mav_type"
    "match" => "mav_match"
    "fn" => "mav_fn"
    "let" => "mav_let"
    "struct" => "mav_struct"
    "enum" => "mav_enum"
    "pub" => "mav_pub"
    "priv" => "mav_priv"
    "test" => "mav_test"
    "in" => "mav_in"
    "is" => "mav_is"
    _ => name
  }
}

///|
/// Convert an enum entry name into a clean `PascalCase` variant name by stripping
/// a redundant `ENUM_NAME_` prefix when present.
pub fn enum_entry_variant_name(
  enum_name : String,
  entry_name : String,
) -> String {
  let prefix = enum_name + "_"
  let e_chars = entry_name.to_array()
  let p_chars = prefix.to_array()
  if e_chars.length() > p_chars.length() {
    let mut matches = true
    for i = 0; i < p_chars.length(); i = i + 1 {
      if e_chars[i] != p_chars[i] {
        matches = false
        break
      }
    }
    if matches {
      let rest_sb = StringBuilder()
      for i = p_chars.length(); i < e_chars.length(); i = i + 1 {
        rest_sb.write_char(e_chars[i])
      }
      return to_pascal_case(rest_sb.to_string())
    }
  }
  to_pascal_case(entry_name)
}

///|
/// Map a `MavPrimitiveType` to its MoonBit scalar type name.
pub fn primitive_moonbit_type(prim : MavPrimitiveType) -> String {
  match prim {
    UInt8 | Char => "Byte"
    Int8 | Int16 | Int32 => "Int"
    UInt16 | UInt32 => "UInt"
    UInt64 => "UInt64"
    Int64 => "Int64"
    Float32 => "Float"
    Float64 => "Double"
  }
}

///|
/// Map a `MavFieldType` to its idiomatic MoonBit type annotation.
pub fn field_moonbit_type(ft : MavFieldType) -> String {
  match ft {
    Scalar(prim, _) => primitive_moonbit_type(prim)
    FixedArrayType(Char, _) => "String"
    FixedArrayType(prim, _) =>
      "FixedArray[" + primitive_moonbit_type(prim) + "]"
  }
}

///|
fn default_scalar_expr(prim : MavPrimitiveType) -> String {
  match prim {
    UInt8 | Char => "b'\\x00'"
    Int8 | Int16 | Int32 => "0"
    UInt16 | UInt32 => "0U"
    UInt64 => "0UL"
    Int64 => "0L"
    Float32 => "(0.0 : Float)"
    Float64 => "0.0"
  }
}

///|
fn write_scalar_method(prim : MavPrimitiveType) -> String {
  match prim {
    UInt8 | Char => "write_uint8"
    Int8 => "write_int8"
    UInt16 => "write_uint16"
    Int16 => "write_int16"
    UInt32 => "write_uint32"
    Int32 => "write_int32"
    UInt64 => "write_uint64"
    Int64 => "write_int64"
    Float32 => "write_float"
    Float64 => "write_double"
  }
}

///|
fn read_scalar_method(prim : MavPrimitiveType) -> String {
  match prim {
    UInt8 | Char => "read_uint8"
    Int8 => "read_int8"
    UInt16 => "read_uint16"
    Int16 => "read_int16"
    UInt32 => "read_uint32"
    Int32 => "read_int32"
    UInt64 => "read_uint64"
    Int64 => "read_int64"
    Float32 => "read_float"
    Float64 => "read_double"
  }
}

///|
fn uint_to_dec(v : UInt32) -> String {
  if v == 0U {
    return "0"
  }
  let digits : Array[Char] = []
  let mut cur = v
  while cur > 0U {
    let rem = (cur % 10U).reinterpret_as_int()
    digits.push(Int32::unsafe_to_char('0'.to_int() + rem))
    cur = cur / 10U
  }
  let sb = StringBuilder()
  for i = digits.length() - 1; i >= 0; i = i - 1 {
    sb.write_char(digits[i])
  }
  sb.to_string()
}

///|
fn int_to_dec(v : Int32) -> String {
  if v < 0 {
    "-" + uint_to_dec((-v).reinterpret_as_uint())
  } else {
    uint_to_dec(v.reinterpret_as_uint())
  }
}

///|
fn byte_to_hex_literal(b : Byte) -> String {
  let hex = "0123456789ABCDEF".to_array()
  let u = b.to_int() & 0xFF
  let hi = hex[(u >> 4) & 0x0F]
  let lo = hex[u & 0x0F]
  let sb = StringBuilder()
  sb.write_string("b'\\x")
  sb.write_char(hi)
  sb.write_char(lo)
  sb.write_char('\'')
  sb.to_string()
}

///|
fn single_line_doc(text : String) -> String {
  let chars = text.to_array()
  let sb = StringBuilder()
  let mut prev_space = false
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '\r' || c == '\n' || c == '\t' || c == ' ' {
      if !prev_space {
        sb.write_char(' ')
        prev_space = true
      }
    } else {
      sb.write_char(c)
      prev_space = false
    }
  }
  trim_string(sb.to_string())
}

///|
/// Generate complete, self-contained MoonBit source code (`.mbt`) for a `DialectSchema`,
/// including strongly typed enums, message structs, wire-reordered payload encoders/decoders,
/// `CRC_EXTRA` lookup table, and top-level `MavMessage` frame router.
pub fn generate_moonbit_code(schema : DialectSchema) -> String {
  let sb = StringBuilder()
  sb.write_string(
    "// ============================================================================\n",
  )
  sb.write_string(
    "// AUTO-GENERATED BY lycvvt/mavlink XML Code Generator — DO NOT EDIT MANUALLY\n",
  )
  sb.write_string(
    "// Dialect version: " +
    int_to_dec(schema.version) +
    ", dialect id: " +
    int_to_dec(schema.dialect) +
    "\n",
  )
  sb.write_string(
    "// ============================================================================\n\n",
  )

  // 1. Enums
  for en in schema.enums {
    if en.entries.length() == 0 {
      continue
    }
    let enum_pascal = to_pascal_case(en.name)
    sb.write_string("///|\n")
    if en.description != "" {
      sb.write_string("/// " + single_line_doc(en.description) + "\n")
    } else {
      sb.write_string("/// MAVLink enum `" + en.name + "`.\n")
    }
    sb.write_string("pub(all) enum " + enum_pascal + " {\n")
    for entry in en.entries {
      let var_name = enum_entry_variant_name(en.name, entry.name)
      sb.write_string("  " + var_name + "\n")
    }
    sb.write_string("} derive(Eq, Debug)\n\n")
    sb.write_string("///|\n")
    sb.write_string(
      "pub extend " + enum_pascal + " with Eq::{not_equal, equal}\n\n",
    )
    sb.write_string("///|\n")
    sb.write_string(
      "pub extend " + enum_pascal + " with @debug.Debug::{to_repr}\n\n",
    )

    // to_uint
    sb.write_string("///|\n")
    sb.write_string(
      "/// Convert `" + enum_pascal + "` to its raw MAVLink numeric value.\n",
    )
    sb.write_string(
      "pub fn " +
      enum_pascal +
      "::to_uint(self : " +
      enum_pascal +
      ") -> UInt {\n",
    )
    sb.write_string("  match self {\n")
    for entry in en.entries {
      let var_name = enum_entry_variant_name(en.name, entry.name)
      sb.write_string(
        "    " + var_name + " => " + uint_to_dec(entry.value) + "U\n",
      )
    }
    sb.write_string("  }\n}\n\n")

    // from_uint
    sb.write_string("///|\n")
    sb.write_string(
      "/// Decode `" + enum_pascal + "` from its raw MAVLink numeric value.\n",
    )
    sb.write_string(
      "pub fn " +
      enum_pascal +
      "::from_uint(v : UInt) -> " +
      enum_pascal +
      "? {\n",
    )
    sb.write_string("  match v {\n")
    let seen_vals : Array[UInt32] = []
    for entry in en.entries {
      let mut dup = false
      for sv in seen_vals {
        if sv == entry.value {
          dup = true
          break
        }
      }
      if !dup {
        seen_vals.push(entry.value)
        let var_name = enum_entry_variant_name(en.name, entry.name)
        sb.write_string(
          "    " + uint_to_dec(entry.value) + "U => Some(" + var_name + ")\n",
        )
      }
    }
    sb.write_string("    _ => None\n  }\n}\n\n")
  }

  // 2. Messages
  for msg in schema.messages {
    let msg_pascal = to_pascal_case(msg.name)
    let id_str = uint_to_dec(msg.id)
    let crc_hex = byte_to_hex_literal(msg.crc_extra)
    let crc_dec = int_to_dec(msg.crc_extra.to_int() & 0xFF)

    sb.write_string("///|\n")
    if msg.description != "" {
      sb.write_string("/// " + single_line_doc(msg.description) + "\n")
    }
    sb.write_string(
      "/// - MAVLink Message `" +
      msg.name +
      "` (ID: " +
      id_str +
      ", CRC_EXTRA: " +
      crc_dec +
      ", base_len: " +
      int_to_dec(msg.base_payload_len) +
      "B, max_len: " +
      int_to_dec(msg.max_payload_len) +
      "B)\n",
    )
    sb.write_string("pub(all) struct " + msg_pascal + " {\n")
    for f in msg.fields {
      let fname = sanitize_field_name(f.name)
      let ftype = field_moonbit_type(f.parsed_type)
      sb.write_string("  " + fname + " : " + ftype + "\n")
    }
    sb.write_string("} derive(Eq, Debug)\n\n")
    sb.write_string("///|\n")
    sb.write_string(
      "pub extend " + msg_pascal + " with Eq::{not_equal, equal}\n\n",
    )
    sb.write_string("///|\n")
    sb.write_string(
      "pub extend " + msg_pascal + " with @debug.Debug::{to_repr}\n\n",
    )

    // Metadata helpers
    sb.write_string("///|\n")
    sb.write_string("pub fn " + msg_pascal + "::msg_id() -> UInt {\n")
    sb.write_string("  " + id_str + "U\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("pub fn " + msg_pascal + "::crc_extra() -> Byte {\n")
    sb.write_string("  " + crc_hex + "\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("pub fn " + msg_pascal + "::base_payload_len() -> Int {\n")
    sb.write_string("  " + int_to_dec(msg.base_payload_len) + "\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("pub fn " + msg_pascal + "::max_payload_len() -> Int {\n")
    sb.write_string("  " + int_to_dec(msg.max_payload_len) + "\n}\n\n")

    // encode_payload
    sb.write_string("///|\n")
    sb.write_string(
      "/// Serialize `" +
      msg_pascal +
      "` into wire-ordered little-endian payload bytes.\n",
    )
    sb.write_string(
      "pub fn " +
      msg_pascal +
      "::encode_payload(self : " +
      msg_pascal +
      ", v2~ : Bool = true) -> Bytes {\n",
    )
    sb.write_string(
      "  let w = PayloadWriter::new(capacity=" +
      int_to_dec(msg.max_payload_len) +
      ")\n",
    )

    let mut has_ext = false
    for wf in msg.wire_ordered_fields {
      if wf.is_extension && !has_ext {
        has_ext = true
        sb.write_string("  if v2 {\n")
      }
      let indent = if wf.is_extension { "    " } else { "  " }
      let fname = sanitize_field_name(wf.name)
      match wf.parsed_type {
        Scalar(prim, _) =>
          sb.write_string(
            indent + "w." + write_scalar_method(prim) + "(self." + fname + ")\n",
          )
        FixedArrayType(Char, len) =>
          sb.write_string(
            indent +
            "w.write_char_array(self." +
            fname +
            ", " +
            int_to_dec(len) +
            ")\n",
          )
        FixedArrayType(prim, len) => {
          sb.write_string(
            indent + "for i = 0; i < " + int_to_dec(len) + "; i = i + 1 {\n",
          )
          sb.write_string(
            indent +
            "  let elem = if i < self." +
            fname +
            ".length() { self." +
            fname +
            "[i] } else { " +
            default_scalar_expr(prim) +
            " }\n",
          )
          sb.write_string(
            indent + "  w." + write_scalar_method(prim) + "(elem)\n",
          )
          sb.write_string(indent + "}\n")
        }
      }
    }
    if has_ext {
      sb.write_string("  }\n")
    }
    sb.write_string("  w.to_wire_bytes(truncate_zeros=v2)\n}\n\n")

    // decode_payload
    sb.write_string("///|\n")
    sb.write_string(
      "/// Deserialize `" +
      msg_pascal +
      "` from wire-ordered little-endian payload bytes.\n",
    )
    sb.write_string(
      "pub fn " +
      msg_pascal +
      "::decode_payload(payload : Bytes, v2~ : Bool = true) -> Result[" +
      msg_pascal +
      ", MavError] {\n",
    )
    sb.write_string("  let r = PayloadReader::new(payload, zero_extend=v2)\n")
    for wf in msg.wire_ordered_fields {
      let fname = sanitize_field_name(wf.name)
      match wf.parsed_type {
        Scalar(prim, _) => {
          sb.write_string(
            "  let " +
            fname +
            " = match r." +
            read_scalar_method(prim) +
            "() {\n",
          )
          sb.write_string("    Ok(v) => v\n    Err(e) => return Err(e)\n  }\n")
        }
        FixedArrayType(Char, len) => {
          sb.write_string(
            "  let " +
            fname +
            " = match r.read_char_array(" +
            int_to_dec(len) +
            ") {\n",
          )
          sb.write_string("    Ok(v) => v\n    Err(e) => return Err(e)\n  }\n")
        }
        FixedArrayType(prim, len) => {
          sb.write_string(
            "  let " +
            fname +
            " = FixedArray::make(" +
            int_to_dec(len) +
            ", " +
            default_scalar_expr(prim) +
            ")\n",
          )
          sb.write_string(
            "  for i = 0; i < " + int_to_dec(len) + "; i = i + 1 {\n",
          )
          sb.write_string("    match r." + read_scalar_method(prim) + "() {\n")
          sb.write_string("      Ok(v) => " + fname + "[i] = v\n")
          sb.write_string("      Err(e) => return Err(e)\n    }\n  }\n")
        }
      }
    }
    sb.write_string("  Ok({\n")
    for f in msg.fields {
      let fname = sanitize_field_name(f.name)
      sb.write_string("    " + fname + ",\n")
    }
    sb.write_string("  })\n}\n\n")
  }

  // 3. Top-level MavMessage router & CRC_EXTRA table
  if schema.messages.length() > 0 {
    sb.write_string("///|\n")
    sb.write_string(
      "/// Look up the precomputed `CRC_EXTRA` byte for a known MAVLink message ID.\n",
    )
    sb.write_string(
      "pub fn lookup_message_crc_extra(msgid : UInt) -> Byte? {\n",
    )
    sb.write_string("  match msgid {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string(
        "    " +
        uint_to_dec(msg.id) +
        "U => Some(" +
        msg_pascal +
        "::crc_extra())\n",
      )
    }
    sb.write_string("    _ => None\n  }\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("/// Unified top-level MAVLink dialect message sum type.\n")
    sb.write_string("pub(all) enum MavMessage {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string("  Msg" + msg_pascal + "(" + msg_pascal + ")\n")
    }
    sb.write_string("} derive(Eq, Debug)\n\n")
    sb.write_string("///|\n")
    sb.write_string("pub extend MavMessage with Eq::{not_equal, equal}\n\n")
    sb.write_string("///|\n")
    sb.write_string("pub extend MavMessage with @debug.Debug::{to_repr}\n\n")

    sb.write_string("///|\n")
    sb.write_string("/// Return the numeric MAVLink message ID of `self`.\n")
    sb.write_string("pub fn MavMessage::msg_id(self : MavMessage) -> UInt {\n")
    sb.write_string("  match self {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string(
        "    Msg" + msg_pascal + "(_) => " + uint_to_dec(msg.id) + "U\n",
      )
    }
    sb.write_string("  }\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("/// Return the `CRC_EXTRA` seed byte of `self`.\n")
    sb.write_string(
      "pub fn MavMessage::crc_extra(self : MavMessage) -> Byte {\n",
    )
    sb.write_string("  match self {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string(
        "    Msg" + msg_pascal + "(_) => " + msg_pascal + "::crc_extra()\n",
      )
    }
    sb.write_string("  }\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string("/// Encode `self` into a wire payload.\n")
    sb.write_string(
      "pub fn MavMessage::encode_payload(self : MavMessage, v2~ : Bool = true) -> Bytes {\n",
    )
    sb.write_string("  match self {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string("    Msg" + msg_pascal + "(m) => m.encode_payload(v2~)\n")
    }
    sb.write_string("  }\n}\n\n")

    sb.write_string("///|\n")
    sb.write_string(
      "/// Encode `self` into a complete MAVLink v1 or v2 wire frame.\n",
    )
    sb.write_string(
      "pub fn MavMessage::encode_to_frame(\n  self : MavMessage,\n  seq~ : Byte,\n  sysid~ : Byte,\n  compid~ : Byte,\n  version~ : ProtocolVersion = V2,\n  signing~ : SigningContext? = None,\n) -> Result[(Bytes, MavFrame), MavError] {\n",
    )
    sb.write_string("  let is_v2 = version == V2\n")
    sb.write_string("  let raw_payload = self.encode_payload(v2=is_v2)\n")
    sb.write_string("  let header : MavHeader = {\n")
    sb.write_string("    version,\n")
    sb.write_string("    incompat_flags: b'\\x00',\n")
    sb.write_string("    compat_flags: b'\\x00',\n")
    sb.write_string("    seq,\n")
    sb.write_string("    sysid,\n")
    sb.write_string("    compid,\n")
    sb.write_string("    msgid: self.msg_id(),\n")
    sb.write_string("  }\n")
    sb.write_string(
      "  encode_frame(header, raw_payload, self.crc_extra(), truncate_v2_zeros=is_v2, signing~)\n}\n\n",
    )

    sb.write_string("///|\n")
    sb.write_string("/// Decode a `MavMessage` from a verified `MavFrame`.\n")
    sb.write_string(
      "pub fn MavMessage::decode_from_frame(frame : MavFrame) -> Result[MavMessage, MavError] {\n",
    )
    sb.write_string("  let is_v2 = frame.header.version == V2\n")
    sb.write_string("  match frame.header.msgid {\n")
    for msg in schema.messages {
      let msg_pascal = to_pascal_case(msg.name)
      sb.write_string("    " + uint_to_dec(msg.id) + "U =>\n")
      sb.write_string(
        "      match " +
        msg_pascal +
        "::decode_payload(frame.payload, v2=is_v2) {\n",
      )
      sb.write_string("        Ok(m) => Ok(Msg" + msg_pascal + "(m))\n")
      sb.write_string("        Err(e) => Err(e)\n      }\n")
    }
    sb.write_string("    other => Err(UnknownMessageId(other))\n  }\n}\n")
  }

  sb.to_string()
}

///|
/// Parse an official MAVLink XML string and generate MoonBit source code in one step.
pub fn generate_moonbit_from_xml(
  xml_text : String,
) -> Result[(DialectSchema, String), MavError] {
  match parse_dialect_xml(xml_text) {
    Ok(schema) => Ok((schema, generate_moonbit_code(schema)))
    Err(e) => Err(e)
  }
}
