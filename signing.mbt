///|
/// Standard SHA-256 round constants `K[0..63]` (first 32 bits of the fractional parts of cube roots of first 64 primes).
let sha256_k : FixedArray[UInt32] = [
  0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U, 0x923f82a4U,
  0xab1c5ed5U, 0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U, 0x72be5d74U, 0x80deb1feU,
  0x9bdc06a7U, 0xc19bf174U, 0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU,
  0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU, 0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
  0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U, 0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU,
  0x53380d13U, 0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U, 0xa2bfe8a1U, 0xa81a664bU,
  0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U, 0x19a4c116U,
  0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
  0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U, 0x90befffaU, 0xa4506cebU, 0xbef9a3f7U,
  0xc67178f2U,
]

///|
fn rotr32(x : UInt32, n : Int32) -> UInt32 {
  (x >> n) | (x << (32 - n))
}

///|
/// Compute the 32-byte SHA-256 digest of `input` (FIPS 180-4).
pub fn sha256_digest(input : Bytes) -> FixedArray[Byte] {
  let mut h0 = 0x6a09e667U
  let mut h1 = 0xbb67ae85U
  let mut h2 = 0x3c6ef372U
  let mut h3 = 0xa54ff53aU
  let mut h4 = 0x510e527fU
  let mut h5 = 0x9b05688cU
  let mut h6 = 0x1f83d9abU
  let mut h7 = 0x5be0cd19U

  let msg_len = input.length()
  let bit_len = msg_len.to_uint64() * 8UL
  let padded : Array[Byte] = Array(capacity=msg_len + 72)
  for i = 0; i < msg_len; i = i + 1 {
    padded.push(input[i])
  }
  padded.push(b'\x80')
  while padded.length() % 64 != 56 {
    padded.push(b'\x00')
  }
  for shift = 56; shift >= 0; shift = shift - 8 {
    padded.push(((bit_len >> shift) & 0xFFUL).to_byte())
  }

  let w = FixedArray::make(64, 0U)
  let num_blocks = padded.length() / 64
  for blk = 0; blk < num_blocks; blk = blk + 1 {
    let base = blk * 64
    for i = 0; i < 16; i = i + 1 {
      let idx = base + i * 4
      let b0 = padded[idx].to_uint()
      let b1 = padded[idx + 1].to_uint()
      let b2 = padded[idx + 2].to_uint()
      let b3 = padded[idx + 3].to_uint()
      w[i] = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }
    for i = 16; i < 64; i = i + 1 {
      let s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3)
      let s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10)
      w[i] = w[i - 16] + s0 + w[i - 7] + s1
    }

    let mut a = h0
    let mut b = h1
    let mut c = h2
    let mut d = h3
    let mut e = h4
    let mut f = h5
    let mut g = h6
    let mut h = h7

    for i = 0; i < 64; i = i + 1 {
      let s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)
      let ch = (e & f) ^ (e.lnot() & g)
      let temp1 = h + s1 + ch + sha256_k[i] + w[i]
      let s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)
      let maj = (a & b) ^ (a & c) ^ (b & c)
      let temp2 = s0 + maj

      h = g
      g = f
      f = e
      e = d + temp1
      d = c
      c = b
      b = a
      a = temp1 + temp2
    }

    h0 = h0 + a
    h1 = h1 + b
    h2 = h2 + c
    h3 = h3 + d
    h4 = h4 + e
    h5 = h5 + f
    h6 = h6 + g
    h7 = h7 + h
  }

  let out = FixedArray::make(32, b'\x00')
  let words : FixedArray[UInt32] = [h0, h1, h2, h3, h4, h5, h6, h7]
  for i = 0; i < 8; i = i + 1 {
    let v = words[i]
    out[i * 4] = ((v >> 24) & 0xFFU).to_byte()
    out[i * 4 + 1] = ((v >> 16) & 0xFFU).to_byte()
    out[i * 4 + 2] = ((v >> 8) & 0xFFU).to_byte()
    out[i * 4 + 3] = (v & 0xFFU).to_byte()
  }
  out
}

///|
/// Stateful MAVLink v2 packet signing and verification context.
///
/// Per the MAVLink v2 Packet Signing specification:
/// - `secret_key` is a 32-byte shared secret.
/// - `link_id` identifies the communication link (`0..255`).
/// - `timestamp` is a 48-bit monotonically increasing counter in 10-microsecond units since 2015-01-01.
/// - Signature is the first 6 bytes of `SHA256(secret_key || frame_without_sig || link_id || timestamp_le6)`.
pub(all) struct SigningContext {
  secret_key : FixedArray[Byte]
  link_id : Byte
  mut timestamp : UInt64
} derive(Eq, Debug)

///|
pub extend SigningContext with Eq::{not_equal, equal}

///|
pub extend SigningContext with @debug.Debug::{to_repr}

///|
/// Create a new `SigningContext` with a 32-byte secret key, `link_id`, and initial 48-bit `timestamp`.
pub fn SigningContext::new(
  secret_key : Bytes,
  link_id~ : Byte = b'\x00',
  initial_timestamp~ : UInt64 = 1UL,
) -> Result[SigningContext, MavError] {
  if secret_key.length() != 32 {
    return Err(
      SignatureInvalid("MAVLink v2 signing secret key must be exactly 32 bytes"),
    )
  }
  let key_arr = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    key_arr[i] = secret_key[i]
  }
  Ok({
    secret_key: key_arr,
    link_id,
    timestamp: initial_timestamp & 0xFFFFFFFFFFFFUL,
  })
}

///|
/// Compute the 6-byte truncated SHA-256 signature for the given unsigned frame bytes
/// (`STX` through `CRC`, inclusive), `link_id`, and 48-bit `timestamp`.
pub fn compute_v2_signature_bytes(
  secret_key : FixedArray[Byte],
  unsigned_frame_bytes : Bytes,
  link_id : Byte,
  timestamp : UInt64,
) -> FixedArray[Byte] {
  let buf : Array[Byte] = Array(capacity=32 + unsigned_frame_bytes.length() + 7)
  for i = 0; i < 32; i = i + 1 {
    buf.push(secret_key[i])
  }
  for i = 0; i < unsigned_frame_bytes.length(); i = i + 1 {
    buf.push(unsigned_frame_bytes[i])
  }
  buf.push(link_id)
  for shift = 0; shift < 48; shift = shift + 8 {
    buf.push(((timestamp >> shift) & 0xFFUL).to_byte())
  }
  let digest = sha256_digest(Bytes::from_array(buf))
  let sig = FixedArray::make(6, b'\x00')
  for i = 0; i < 6; i = i + 1 {
    sig[i] = digest[i]
  }
  sig
}

///|
/// Generate the next `MavSignature` for an outgoing MAVLink v2 frame and increment the context timestamp.
pub fn SigningContext::sign_frame_bytes(
  self : SigningContext,
  unsigned_frame_bytes : Bytes,
) -> MavSignature {
  let ts = self.timestamp & 0xFFFFFFFFFFFFUL
  let sig = compute_v2_signature_bytes(
    self.secret_key,
    unsigned_frame_bytes,
    self.link_id,
    ts,
  )
  self.timestamp = (ts + 1UL) & 0xFFFFFFFFFFFFUL
  { link_id: self.link_id, timestamp: ts, signature: sig, }
}

///|
/// Verify an incoming MAVLink v2 frame signature and enforce monotonic timestamp replay protection.
pub fn SigningContext::verify_frame_signature(
  self : SigningContext,
  unsigned_frame_bytes : Bytes,
  sig : MavSignature,
  enforce_replay_protection~ : Bool = true,
) -> Result[Unit, MavError] {
  if enforce_replay_protection && sig.timestamp < self.timestamp {
    return Err(
      SignatureInvalid(
        "Replay detected: incoming timestamp is older than last accepted timestamp",
      ),
    )
  }
  let expected = compute_v2_signature_bytes(
    self.secret_key,
    unsigned_frame_bytes,
    sig.link_id,
    sig.timestamp,
  )
  for i = 0; i < 6; i = i + 1 {
    if expected[i] != sig.signature[i] {
      return Err(SignatureInvalid("Packet signature digest mismatch"))
    }
  }
  if enforce_replay_protection && sig.timestamp >= self.timestamp {
    self.timestamp = (sig.timestamp + 1UL) & 0xFFFFFFFFFFFFUL
  }
  Ok(())
}
