///|
/// Primitive element types defined in the official MAVLink XML schema.
pub(all) enum MavPrimitiveType {
  UInt8
  Int8
  UInt16
  Int16
  UInt32
  Int32
  UInt64
  Int64
  Float32
  Float64
  Char
} derive(Eq, Debug)

///|
pub extend MavPrimitiveType with Eq::{not_equal, equal}

///|
pub extend MavPrimitiveType with @debug.Debug::{to_repr}

///|
/// Return the wire size in bytes of a `MavPrimitiveType`.
pub fn MavPrimitiveType::byte_size(self : MavPrimitiveType) -> Int32 {
  match self {
    UInt64 | Int64 | Float64 => 8
    UInt32 | Int32 | Float32 => 4
    UInt16 | Int16 => 2
    UInt8 | Int8 | Char => 1
  }
}

///|
/// Parsed field type representation (scalar or fixed-length array).
pub(all) enum MavFieldType {
  Scalar(MavPrimitiveType, Bool)
  FixedArrayType(MavPrimitiveType, Int32)
} derive(Eq, Debug)

///|
pub extend MavFieldType with Eq::{not_equal, equal}

///|
pub extend MavFieldType with @debug.Debug::{to_repr}

///|
/// Element byte width used for MAVLink wire field reordering.
pub fn MavFieldType::order_weight(self : MavFieldType) -> Int32 {
  match self {
    Scalar(prim, _) => prim.byte_size()
    FixedArrayType(prim, _) => prim.byte_size()
  }
}

///|
/// Total wire byte length occupied by a field.
pub fn MavFieldType::total_byte_len(self : MavFieldType) -> Int32 {
  match self {
    Scalar(prim, _) => prim.byte_size()
    FixedArrayType(prim, len) => prim.byte_size() * len
  }
}

///|
/// Parse a MAVLink XML `type` attribute string into `MavFieldType`.
pub fn parse_mav_field_type(
  wire_type : String,
) -> Result[MavFieldType, MavError] {
  let (norm_base, _, arr_len) = match parse_wire_type_spec(wire_type) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let is_version_field = wire_type == "uint8_t_mavlink_version"
  let prim = match norm_base {
    "uint8_t" => UInt8
    "int8_t" => Int8
    "uint16_t" => UInt16
    "int16_t" => Int16
    "uint32_t" => UInt32
    "int32_t" => Int32
    "uint64_t" => UInt64
    "int64_t" => Int64
    "float" => Float32
    "double" => Float64
    "char" => Char
    _ => return Err(SchemaError("Unsupported MAVLink field type: " + wire_type))
  }
  if arr_len > 0 {
    Ok(FixedArrayType(prim, arr_len))
  } else {
    Ok(Scalar(prim, is_version_field))
  }
}

///|
/// Single `<entry>` inside a MAVLink `<enum>`.
pub(all) struct XmlEnumEntry {
  name : String
  value : UInt32
  description : String
} derive(Eq, Debug)

///|
pub extend XmlEnumEntry with Eq::{not_equal, equal}

///|
pub extend XmlEnumEntry with @debug.Debug::{to_repr}

///|
/// Parsed `<enum>` definition from a MAVLink XML file.
pub(all) struct XmlEnumDef {
  name : String
  bitmask : Bool
  description : String
  entries : Array[XmlEnumEntry]
} derive(Eq, Debug)

///|
pub extend XmlEnumDef with Eq::{not_equal, equal}

///|
pub extend XmlEnumDef with @debug.Debug::{to_repr}

///|
/// Parsed `<field>` definition inside a MAVLink `<message>`, enriched with wire layout metadata.
pub(all) struct XmlFieldDef {
  wire_type : String
  parsed_type : MavFieldType
  name : String
  enum_name : String?
  units : String?
  description : String
  is_extension : Bool
  wire_offset : Int32
} derive(Eq, Debug)

///|
pub extend XmlFieldDef with Eq::{not_equal, equal}

///|
pub extend XmlFieldDef with @debug.Debug::{to_repr}

///|
/// Parsed `<message>` definition from a MAVLink XML file, including wire-reordered fields
/// and precomputed `crc_extra`, `base_payload_len`, and `max_payload_len`.
pub(all) struct XmlMessageDef {
  id : UInt32
  name : String
  description : String
  fields : Array[XmlFieldDef]
  wire_ordered_fields : Array[XmlFieldDef]
  base_payload_len : Int32
  max_payload_len : Int32
  crc_extra : Byte
} derive(Eq, Debug)

///|
pub extend XmlMessageDef with Eq::{not_equal, equal}

///|
pub extend XmlMessageDef with @debug.Debug::{to_repr}

///|
/// Complete parsed MAVLink XML dialect schema (`<mavlink>`).
pub(all) struct DialectSchema {
  version : Int32
  dialect : Int32
  includes : Array[String]
  enums : Array[XmlEnumDef]
  messages : Array[XmlMessageDef]
} derive(Eq, Debug)

///|
pub extend DialectSchema with Eq::{not_equal, equal}

///|
pub extend DialectSchema with @debug.Debug::{to_repr}

///|
/// Resolve the MAVLink wire layout, field offsets, payload lengths, and `CRC_EXTRA`
/// for a message definition.
pub fn resolve_message_layout(
  id : UInt32,
  name : String,
  description : String,
  raw_fields : Array[XmlFieldDef],
) -> Result[XmlMessageDef, MavError] {
  let base_indexed : Array[(Int32, Int32, XmlFieldDef)] = []
  let ext_fields : Array[XmlFieldDef] = []
  let crc_specs : Array[CrcFieldSpec] = []

  for i = 0; i < raw_fields.length(); i = i + 1 {
    let f = raw_fields[i]
    crc_specs.push(
      CrcFieldSpec::new(f.wire_type, f.name, is_extension=f.is_extension),
    )
    if f.is_extension {
      ext_fields.push(f)
    } else {
      base_indexed.push((f.parsed_type.order_weight(), i, f))
    }
  }

  base_indexed.sort_by(fn(a, b) {
    if a.0 != b.0 {
      b.0.compare(a.0)
    } else {
      a.1.compare(b.1)
    }
  })

  let wire_ordered : Array[XmlFieldDef] = []
  let offset_by_name : Array[(String, Int32)] = []
  let mut offset = 0

  for item in base_indexed {
    let f = item.2
    let updated : XmlFieldDef = { ..f, wire_offset: offset, }
    wire_ordered.push(updated)
    offset_by_name.push((f.name, offset))
    offset = offset + f.parsed_type.total_byte_len()
  }
  let base_payload_len = offset

  for f in ext_fields {
    let updated : XmlFieldDef = { ..f, wire_offset: offset, }
    wire_ordered.push(updated)
    offset_by_name.push((f.name, offset))
    offset = offset + f.parsed_type.total_byte_len()
  }
  let max_payload_len = offset

  if max_payload_len > MAX_PAYLOAD_LEN {
    return Err(
      SchemaError("Message " + name + " exceeds 255-byte maximum payload size"),
    )
  }

  let updated_decl_fields : Array[XmlFieldDef] = []
  for f in raw_fields {
    let mut found_offset = 0
    for pair in offset_by_name {
      if pair.0 == f.name {
        found_offset = pair.1
        break
      }
    }
    updated_decl_fields.push({ ..f, wire_offset: found_offset, })
  }

  let crc_extra = match compute_crc_extra(name, crc_specs) {
    Ok(c) => c
    Err(e) => return Err(e)
  }

  Ok({
    id,
    name,
    description,
    fields: updated_decl_fields,
    wire_ordered_fields: wire_ordered,
    base_payload_len,
    max_payload_len,
    crc_extra,
  })
}

///|
priv struct XmlNode {
  tag : String
  attrs : Array[(String, String)]
  text : String
  children : Array[XmlNode]
}

///|
fn get_attr(attrs : Array[(String, String)], key : String) -> String? {
  for pair in attrs {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
fn is_ws(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
fn is_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-' ||
  c == ':' ||
  c == '.'
}

///|
fn trim_string(s : String) -> String {
  let chars = s.to_array()
  let mut start = 0
  let mut end = chars.length()
  while start < end && is_ws(chars[start]) {
    start = start + 1
  }
  while end > start && is_ws(chars[end - 1]) {
    end = end - 1
  }
  let sb = StringBuilder()
  for i = start; i < end; i = i + 1 {
    sb.write_char(chars[i])
  }
  sb.to_string()
}

///|
fn unescape_xml(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '&' {
      let mut semi = -1
      for j = i + 1; j < chars.length() && j < i + 10; j = j + 1 {
        if chars[j] == ';' {
          semi = j
          break
        }
      }
      if semi > i {
        let ent_sb = StringBuilder()
        for j = i + 1; j < semi; j = j + 1 {
          ent_sb.write_char(chars[j])
        }
        let ent = ent_sb.to_string()
        match ent {
          "lt" => sb.write_char('<')
          "gt" => sb.write_char('>')
          "amp" => sb.write_char('&')
          "quot" => sb.write_char('"')
          "apos" => sb.write_char('\'')
          _ => {
            sb.write_char('&')
            sb.write_string(ent)
            sb.write_char(';')
          }
        }
        i = semi + 1
        continue
      }
    }
    sb.write_char(chars[i])
    i = i + 1
  }
  sb.to_string()
}

///|
fn parse_uint_literal(raw : String) -> Result[UInt32, MavError] {
  let s = trim_string(raw)
  let chars = s.to_array()
  if chars.length() == 0 {
    return Err(XmlParseError("Empty numeric attribute"))
  }
  if chars.length() > 2 &&
    chars[0] == '0' &&
    (chars[1] == 'x' || chars[1] == 'X') {
    let mut acc = 0U
    for i = 2; i < chars.length(); i = i + 1 {
      let c = chars[i]
      let digit = if c >= '0' && c <= '9' {
        (c.to_int() - '0'.to_int()).reinterpret_as_uint()
      } else if c >= 'a' && c <= 'f' {
        (c.to_int() - 'a'.to_int() + 10).reinterpret_as_uint()
      } else if c >= 'A' && c <= 'F' {
        (c.to_int() - 'A'.to_int() + 10).reinterpret_as_uint()
      } else {
        return Err(XmlParseError("Invalid hex integer literal: " + s))
      }
      acc = (acc << 4) | digit
    }
    Ok(acc)
  } else {
    let mut acc = 0U
    for i = 0; i < chars.length(); i = i + 1 {
      let c = chars[i]
      if c < '0' || c > '9' {
        return Err(XmlParseError("Invalid decimal integer literal: " + s))
      }
      acc = acc * 10U + (c.to_int() - '0'.to_int()).reinterpret_as_uint()
    }
    Ok(acc)
  }
}

///|
fn match_seq(chars : Array[Char], pos : Int32, target : String) -> Bool {
  let tchars = target.to_array()
  if pos + tchars.length() > chars.length() {
    return false
  }
  for i = 0; i < tchars.length(); i = i + 1 {
    if chars[pos + i] != tchars[i] {
      return false
    }
  }
  true
}

///|
fn parse_xml_element(
  chars : Array[Char],
  start_pos : Int32,
) -> Result[(XmlNode, Int32), MavError] {
  let mut pos = start_pos
  let n = chars.length()
  if pos >= n || chars[pos] != '<' {
    return Err(XmlParseError("Expected '<' at start of XML element"))
  }
  pos = pos + 1
  let tag_sb = StringBuilder()
  while pos < n && is_name_char(chars[pos]) {
    tag_sb.write_char(chars[pos])
    pos = pos + 1
  }
  let tag = tag_sb.to_string()
  if tag == "" {
    return Err(XmlParseError("Empty XML element tag name"))
  }

  let attrs : Array[(String, String)] = []
  let mut self_closing = false
  while pos < n {
    while pos < n && is_ws(chars[pos]) {
      pos = pos + 1
    }
    if pos >= n {
      return Err(XmlParseError("Unclosed start tag for <" + tag + ">"))
    }
    if chars[pos] == '>' {
      pos = pos + 1
      break
    }
    if pos + 1 < n && chars[pos] == '/' && chars[pos + 1] == '>' {
      self_closing = true
      pos = pos + 2
      break
    }
    let attr_sb = StringBuilder()
    while pos < n && is_name_char(chars[pos]) {
      attr_sb.write_char(chars[pos])
      pos = pos + 1
    }
    let attr_name = attr_sb.to_string()
    if attr_name == "" {
      return Err(
        XmlParseError("Unexpected character in attributes of <" + tag + ">"),
      )
    }
    while pos < n && is_ws(chars[pos]) {
      pos = pos + 1
    }
    if pos >= n || chars[pos] != '=' {
      return Err(
        XmlParseError(
          "Expected '=' after attribute " + attr_name + " in <" + tag + ">",
        ),
      )
    }
    pos = pos + 1
    while pos < n && is_ws(chars[pos]) {
      pos = pos + 1
    }
    if pos >= n || (chars[pos] != '"' && chars[pos] != '\'') {
      return Err(XmlParseError("Expected quote for attribute " + attr_name))
    }
    let quote_ch = chars[pos]
    pos = pos + 1
    let val_sb = StringBuilder()
    while pos < n && chars[pos] != quote_ch {
      val_sb.write_char(chars[pos])
      pos = pos + 1
    }
    if pos >= n {
      return Err(XmlParseError("Unterminated attribute value for " + attr_name))
    }
    pos = pos + 1
    attrs.push((attr_name, unescape_xml(val_sb.to_string())))
  }

  if self_closing {
    return Ok(({ tag, attrs, text: "", children: [], }, pos))
  }

  let children : Array[XmlNode] = []
  let text_sb = StringBuilder()
  while pos < n {
    if match_seq(chars, pos, "<!--") {
      pos = pos + 4
      while pos < n && !match_seq(chars, pos, "-->") {
        pos = pos + 1
      }
      if pos >= n {
        return Err(XmlParseError("Unterminated XML comment"))
      }
      pos = pos + 3
      continue
    }
    if pos + 1 < n && chars[pos] == '<' && chars[pos + 1] == '/' {
      pos = pos + 2
      let close_sb = StringBuilder()
      while pos < n && is_name_char(chars[pos]) {
        close_sb.write_char(chars[pos])
        pos = pos + 1
      }
      let close_tag = close_sb.to_string()
      while pos < n && is_ws(chars[pos]) {
        pos = pos + 1
      }
      if pos >= n || chars[pos] != '>' {
        return Err(XmlParseError("Malformed closing tag </" + close_tag + ">"))
      }
      pos = pos + 1
      if close_tag != tag {
        return Err(
          XmlParseError(
            "Mismatched closing tag: expected </" +
            tag +
            ">, found </" +
            close_tag +
            ">",
          ),
        )
      }
      return Ok(
        (
          {
            tag,
            attrs,
            text: trim_string(unescape_xml(text_sb.to_string())),
            children,
          },
          pos,
        ),
      )
    }
    if chars[pos] == '<' {
      match parse_xml_element(chars, pos) {
        Ok((child_node, next_pos)) => {
          children.push(child_node)
          pos = next_pos
        }
        Err(e) => return Err(e)
      }
    } else {
      text_sb.write_char(chars[pos])
      pos = pos + 1
    }
  }
  Err(XmlParseError("Unclosed XML element <" + tag + ">"))
}

///|
fn parse_xml_root(xml_text : String) -> Result[XmlNode, MavError] {
  let chars = xml_text.to_array()
  let n = chars.length()
  let mut pos = 0
  while pos < n {
    while pos < n && is_ws(chars[pos]) {
      pos = pos + 1
    }
    if pos >= n {
      break
    }
    if match_seq(chars, pos, "<?") {
      pos = pos + 2
      while pos < n && !match_seq(chars, pos, "?>") {
        pos = pos + 1
      }
      if pos >= n {
        return Err(XmlParseError("Unterminated XML processing instruction"))
      }
      pos = pos + 2
      continue
    }
    if match_seq(chars, pos, "<!--") {
      pos = pos + 4
      while pos < n && !match_seq(chars, pos, "-->") {
        pos = pos + 1
      }
      if pos >= n {
        return Err(XmlParseError("Unterminated XML comment"))
      }
      pos = pos + 3
      continue
    }
    if chars[pos] == '<' {
      match parse_xml_element(chars, pos) {
        Ok((root, _)) => return Ok(root)
        Err(e) => return Err(e)
      }
    } else {
      return Err(XmlParseError("Unexpected content before root element"))
    }
  }
  Err(XmlParseError("No root XML element found"))
}

///|
/// Parse an official MAVLink XML message definition document (`<mavlink>...</mavlink>`)
/// into a validated `DialectSchema`.
pub fn parse_dialect_xml(xml_text : String) -> Result[DialectSchema, MavError] {
  let root = match parse_xml_root(xml_text) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  if root.tag != "mavlink" {
    return Err(
      XmlParseError("Expected root element <mavlink>, found <" + root.tag + ">"),
    )
  }

  let mut version = 3
  let mut dialect = 0
  let includes : Array[String] = []
  let enums : Array[XmlEnumDef] = []
  let messages : Array[XmlMessageDef] = []
  let seen_msg_ids : Array[UInt32] = []

  for section in root.children {
    match section.tag {
      "version" =>
        if section.text != "" {
          match parse_uint_literal(section.text) {
            Ok(v) => version = v.reinterpret_as_int()
            Err(e) => return Err(e)
          }
        }
      "dialect" =>
        if section.text != "" {
          match parse_uint_literal(section.text) {
            Ok(d) => dialect = d.reinterpret_as_int()
            Err(e) => return Err(e)
          }
        }
      "include" => if section.text != "" { includes.push(section.text) }
      "enums" =>
        for enum_node in section.children {
          if enum_node.tag != "enum" {
            continue
          }
          let enum_name = match get_attr(enum_node.attrs, "name") {
            Some(n) => n
            None =>
              return Err(
                XmlParseError("<enum> missing required 'name' attribute"),
              )
          }
          let bitmask = match get_attr(enum_node.attrs, "bitmask") {
            Some(v) => v == "true" || v == "1"
            None => false
          }
          let mut enum_desc = ""
          let entries : Array[XmlEnumEntry] = []
          let mut next_auto_val = 0U
          for child in enum_node.children {
            match child.tag {
              "description" => enum_desc = child.text
              "entry" => {
                let entry_name = match get_attr(child.attrs, "name") {
                  Some(en) => en
                  None =>
                    return Err(
                      XmlParseError(
                        "<entry> in enum " + enum_name + " missing 'name'",
                      ),
                    )
                }
                let entry_val = match get_attr(child.attrs, "value") {
                  Some(val_str) =>
                    match parse_uint_literal(val_str) {
                      Ok(v) => v
                      Err(e) => return Err(e)
                    }
                  None => next_auto_val
                }
                next_auto_val = entry_val + 1U
                let mut entry_desc = child.text
                for ec in child.children {
                  if ec.tag == "description" {
                    entry_desc = ec.text
                  }
                }
                entries.push({
                  name: entry_name,
                  value: entry_val,
                  description: entry_desc,
                })
              }
              _ => ()
            }
          }
          enums.push({
            name: enum_name,
            bitmask,
            description: enum_desc,
            entries,
          })
        }
      "messages" =>
        for msg_node in section.children {
          if msg_node.tag != "message" {
            continue
          }
          let msg_id_str = match get_attr(msg_node.attrs, "id") {
            Some(id_s) => id_s
            None =>
              return Err(
                XmlParseError("<message> missing required 'id' attribute"),
              )
          }
          let msg_id = match parse_uint_literal(msg_id_str) {
            Ok(id_v) => id_v
            Err(e) => return Err(e)
          }
          let msg_name = match get_attr(msg_node.attrs, "name") {
            Some(n) => n
            None =>
              return Err(
                XmlParseError("<message> missing required 'name' attribute"),
              )
          }
          for existing_id in seen_msg_ids {
            if existing_id == msg_id {
              return Err(
                SchemaError("Duplicate message id in dialect XML: " + msg_name),
              )
            }
          }
          seen_msg_ids.push(msg_id)

          let mut msg_desc = ""
          let mut in_extensions = false
          let raw_fields : Array[XmlFieldDef] = []

          for child in msg_node.children {
            match child.tag {
              "description" => msg_desc = child.text
              "extensions" => in_extensions = true
              "field" => {
                let wire_type = match get_attr(child.attrs, "type") {
                  Some(t) => t
                  None =>
                    return Err(
                      XmlParseError(
                        "<field> in message " + msg_name + " missing 'type'",
                      ),
                    )
                }
                let field_name = match get_attr(child.attrs, "name") {
                  Some(fnm) => fnm
                  None =>
                    return Err(
                      XmlParseError(
                        "<field> in message " + msg_name + " missing 'name'",
                      ),
                    )
                }
                let parsed_type = match parse_mav_field_type(wire_type) {
                  Ok(pt) => pt
                  Err(e) => return Err(e)
                }
                let enum_name = get_attr(child.attrs, "enum")
                let units = get_attr(child.attrs, "units")
                raw_fields.push({
                  wire_type,
                  parsed_type,
                  name: field_name,
                  enum_name,
                  units,
                  description: child.text,
                  is_extension: in_extensions,
                  wire_offset: 0,
                })
              }
              _ => ()
            }
          }

          let resolved_msg = match
            resolve_message_layout(msg_id, msg_name, msg_desc, raw_fields) {
            Ok(m) => m
            Err(e) => return Err(e)
          }
          messages.push(resolved_msg)
        }
      _ => ()
    }
  }

  Ok({ version, dialect, includes, enums, messages, })
}
