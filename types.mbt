///|
/// MAVLink v1 start-of-text magic marker (`0xFE`).
pub const MAVLINK_STX_V1 : Byte = b'\xFE'

///|
/// MAVLink v2 start-of-text magic marker (`0xFD`).
pub const MAVLINK_STX_V2 : Byte = b'\xFD'

///|
/// Maximum payload length in bytes for both MAVLink v1 and v2 frames.
pub const MAX_PAYLOAD_LEN : Int32 = 255

///|
/// MAVLink v1 header length in bytes (`len`, `seq`, `sysid`, `compid`, `msgid`).
pub const V1_HEADER_LEN : Int32 = 5

///|
/// MAVLink v2 header length in bytes (`len`, `incompat_flags`, `compat_flags`, `seq`, `sysid`, `compid`, `msgid[3]`).
pub const V2_HEADER_LEN : Int32 = 9

///|
/// MAVLink v2 packet signature length in bytes (`link_id[1] + timestamp[6] + signature[6]`).
pub const V2_SIGNATURE_LEN : Int32 = 13

///|
/// MAVLink v2 incompatibility flag indicating the frame carries a 13-byte signature trailer.
pub const IFLAG_SIGNED : Byte = b'\x01'

///|
/// Protocol wire version selector.
pub(all) enum ProtocolVersion {
  V1
  V2
} derive(Eq, Debug)

///|
pub extend ProtocolVersion with Eq::{not_equal, equal}

///|
pub extend ProtocolVersion with @debug.Debug::{to_repr}

///|
/// Comprehensive error type covering wire framing, checksum verification,
/// payload serialization, packet signing, and XML schema code generation.
pub(all) enum MavError {
  InvalidMagic(Byte)
  IncompleteFrame(Int32, Int32)
  PayloadTooLarge(Int32)
  PayloadTooShort(Int32, Int32)
  UnsupportedV1MessageId(UInt32)
  UnsupportedIncompatFlags(Byte)
  UnknownMessageId(UInt32)
  CrcMismatch(UInt32, UInt32)
  SignatureMissing
  SignatureInvalid(String)
  InvalidEnumValue(String, UInt32)
  XmlParseError(String)
  SchemaError(String)
} derive(Eq, Debug)

///|
pub extend MavError with Eq::{not_equal, equal}

///|
pub extend MavError with @debug.Debug::{to_repr}

///|
/// Metadata header for a MAVLink v1 or v2 packet.
pub(all) struct MavHeader {
  version : ProtocolVersion
  incompat_flags : Byte
  compat_flags : Byte
  seq : Byte
  sysid : Byte
  compid : Byte
  msgid : UInt32
} derive(Eq, Debug)

///|
pub extend MavHeader with Eq::{not_equal, equal}

///|
pub extend MavHeader with @debug.Debug::{to_repr}

///|
/// Construct a standard MAVLink v2 header.
pub fn MavHeader::new_v2(
  seq~ : Byte,
  sysid~ : Byte,
  compid~ : Byte,
  msgid~ : UInt32,
  incompat_flags~ : Byte = b'\x00',
  compat_flags~ : Byte = b'\x00',
) -> MavHeader {
  { version: V2, incompat_flags, compat_flags, seq, sysid, compid, msgid, }
}

///|
/// Construct a legacy MAVLink v1 header.
pub fn MavHeader::new_v1(
  seq~ : Byte,
  sysid~ : Byte,
  compid~ : Byte,
  msgid~ : UInt32,
) -> MavHeader {
  {
    version: V1,
    incompat_flags: b'\x00',
    compat_flags: b'\x00',
    seq,
    sysid,
    compid,
    msgid,
  }
}

///|
/// 13-byte MAVLink v2 packet authentication trailer.
/// - `link_id`: 8-bit communication channel identifier
/// - `timestamp`: 48-bit timestamp in 10-microsecond units since Jan 1, 2015 GMT
/// - `signature`: 6-byte (48-bit) truncated SHA-256 digest
pub(all) struct MavSignature {
  link_id : Byte
  timestamp : UInt64
  signature : FixedArray[Byte]
} derive(Eq, Debug)

///|
pub extend MavSignature with Eq::{not_equal, equal}

///|
pub extend MavSignature with @debug.Debug::{to_repr}

///|
/// Decoded or ready-to-encode raw MAVLink wire frame.
pub(all) struct MavFrame {
  header : MavHeader
  payload : Bytes
  checksum : UInt32
  signature : MavSignature?
} derive(Eq, Debug)

///|
pub extend MavFrame with Eq::{not_equal, equal}

///|
pub extend MavFrame with @debug.Debug::{to_repr}
