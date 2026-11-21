///|
/// Reference golden vector entry for a standard MAVLink message (`ID`, `name`, `CRC_EXTRA`, `base_len`, `max_len`).
pub(all) struct GoldenDialectEntry {
  msg_id : UInt32
  name : String
  expected_crc_extra : Byte
  expected_base_len : Int32
  expected_max_len : Int32
} derive(Eq, Debug)

///|
pub extend GoldenDialectEntry with Eq::{not_equal, equal}

///|
pub extend GoldenDialectEntry with @debug.Debug::{to_repr}

///|
/// Official C `c_library_v2` / `pymavlink` golden metadata table for all 45 built-in messages.
pub fn official_45_golden_table() -> Array[GoldenDialectEntry] {
  [
    {
      msg_id: 0U,
      name: "HEARTBEAT",
      expected_crc_extra: b'\x32',
      expected_base_len: 9,
      expected_max_len: 9,
    },
    {
      msg_id: 1U,
      name: "SYS_STATUS",
      expected_crc_extra: b'\x7c',
      expected_base_len: 31,
      expected_max_len: 31,
    },
    {
      msg_id: 2U,
      name: "SYSTEM_TIME",
      expected_crc_extra: b'\x89',
      expected_base_len: 12,
      expected_max_len: 12,
    },
    {
      msg_id: 4U,
      name: "PING",
      expected_crc_extra: b'\xed',
      expected_base_len: 14,
      expected_max_len: 14,
    },
    {
      msg_id: 11U,
      name: "SET_MODE",
      expected_crc_extra: b'\x59',
      expected_base_len: 6,
      expected_max_len: 6,
    },
    {
      msg_id: 20U,
      name: "PARAM_REQUEST_READ",
      expected_crc_extra: b'\xd6',
      expected_base_len: 20,
      expected_max_len: 20,
    },
    {
      msg_id: 21U,
      name: "PARAM_REQUEST_LIST",
      expected_crc_extra: b'\x9f',
      expected_base_len: 2,
      expected_max_len: 2,
    },
    {
      msg_id: 22U,
      name: "PARAM_VALUE",
      expected_crc_extra: b'\xdc',
      expected_base_len: 25,
      expected_max_len: 25,
    },
    {
      msg_id: 23U,
      name: "PARAM_SET",
      expected_crc_extra: b'\xa8',
      expected_base_len: 23,
      expected_max_len: 23,
    },
    {
      msg_id: 24U,
      name: "GPS_RAW_INT",
      expected_crc_extra: b'\x18',
      expected_base_len: 30,
      expected_max_len: 52,
    },
    {
      msg_id: 26U,
      name: "SCALED_IMU",
      expected_crc_extra: b'\xaa',
      expected_base_len: 22,
      expected_max_len: 24,
    },
    {
      msg_id: 27U,
      name: "RAW_IMU",
      expected_crc_extra: b'\x90',
      expected_base_len: 26,
      expected_max_len: 29,
    },
    {
      msg_id: 29U,
      name: "SCALED_PRESSURE",
      expected_crc_extra: b'\x73',
      expected_base_len: 14,
      expected_max_len: 16,
    },
    {
      msg_id: 30U,
      name: "ATTITUDE",
      expected_crc_extra: b'\x27',
      expected_base_len: 28,
      expected_max_len: 28,
    },
    {
      msg_id: 31U,
      name: "ATTITUDE_QUATERNION",
      expected_crc_extra: b'\xf6',
      expected_base_len: 32,
      expected_max_len: 48,
    },
    {
      msg_id: 32U,
      name: "LOCAL_POSITION_NED",
      expected_crc_extra: b'\xb9',
      expected_base_len: 28,
      expected_max_len: 28,
    },
    {
      msg_id: 33U,
      name: "GLOBAL_POSITION_INT",
      expected_crc_extra: b'\x68',
      expected_base_len: 28,
      expected_max_len: 28,
    },
    {
      msg_id: 35U,
      name: "RC_CHANNELS_RAW",
      expected_crc_extra: b'\xf4',
      expected_base_len: 22,
      expected_max_len: 22,
    },
    {
      msg_id: 36U,
      name: "SERVO_OUTPUT_RAW",
      expected_crc_extra: b'\xde',
      expected_base_len: 21,
      expected_max_len: 37,
    },
    {
      msg_id: 40U,
      name: "MISSION_REQUEST",
      expected_crc_extra: b'\xe6',
      expected_base_len: 4,
      expected_max_len: 5,
    },
    {
      msg_id: 41U,
      name: "MISSION_SET_CURRENT",
      expected_crc_extra: b'\x1c',
      expected_base_len: 4,
      expected_max_len: 4,
    },
    {
      msg_id: 42U,
      name: "MISSION_CURRENT",
      expected_crc_extra: b'\x1c',
      expected_base_len: 2,
      expected_max_len: 6,
    },
    {
      msg_id: 43U,
      name: "MISSION_REQUEST_LIST",
      expected_crc_extra: b'\x84',
      expected_base_len: 2,
      expected_max_len: 3,
    },
    {
      msg_id: 44U,
      name: "MISSION_COUNT",
      expected_crc_extra: b'\xdd',
      expected_base_len: 4,
      expected_max_len: 9,
    },
    {
      msg_id: 45U,
      name: "MISSION_CLEAR_ALL",
      expected_crc_extra: b'\xe8',
      expected_base_len: 2,
      expected_max_len: 3,
    },
    {
      msg_id: 46U,
      name: "MISSION_ITEM_REACHED",
      expected_crc_extra: b'\x0b',
      expected_base_len: 2,
      expected_max_len: 2,
    },
    {
      msg_id: 47U,
      name: "MISSION_ACK",
      expected_crc_extra: b'\x99',
      expected_base_len: 3,
      expected_max_len: 8,
    },
    {
      msg_id: 51U,
      name: "MISSION_REQUEST_INT",
      expected_crc_extra: b'\xc4',
      expected_base_len: 4,
      expected_max_len: 5,
    },
    {
      msg_id: 65U,
      name: "RC_CHANNELS",
      expected_crc_extra: b'\x76',
      expected_base_len: 42,
      expected_max_len: 42,
    },
    {
      msg_id: 69U,
      name: "MANUAL_CONTROL",
      expected_crc_extra: b'\xf3',
      expected_base_len: 11,
      expected_max_len: 18,
    },
    {
      msg_id: 73U,
      name: "MISSION_ITEM_INT",
      expected_crc_extra: b'\x26',
      expected_base_len: 37,
      expected_max_len: 38,
    },
    {
      msg_id: 74U,
      name: "VFR_HUD",
      expected_crc_extra: b'\x14',
      expected_base_len: 20,
      expected_max_len: 20,
    },
    {
      msg_id: 75U,
      name: "COMMAND_INT",
      expected_crc_extra: b'\x9e',
      expected_base_len: 35,
      expected_max_len: 35,
    },
    {
      msg_id: 76U,
      name: "COMMAND_LONG",
      expected_crc_extra: b'\x98',
      expected_base_len: 33,
      expected_max_len: 33,
    },
    {
      msg_id: 77U,
      name: "COMMAND_ACK",
      expected_crc_extra: b'\x8f',
      expected_base_len: 3,
      expected_max_len: 10,
    },
    {
      msg_id: 80U,
      name: "COMMAND_CANCEL",
      expected_crc_extra: b'\x0e',
      expected_base_len: 4,
      expected_max_len: 4,
    },
    {
      msg_id: 82U,
      name: "SET_ATTITUDE_TARGET",
      expected_crc_extra: b'\x31',
      expected_base_len: 39,
      expected_max_len: 39,
    },
    {
      msg_id: 111U,
      name: "TIMESYNC",
      expected_crc_extra: b'\x22',
      expected_base_len: 16,
      expected_max_len: 18,
    },
    {
      msg_id: 132U,
      name: "DISTANCE_SENSOR",
      expected_crc_extra: b'\x55',
      expected_base_len: 14,
      expected_max_len: 39,
    },
    {
      msg_id: 147U,
      name: "BATTERY_STATUS",
      expected_crc_extra: b'\x9a',
      expected_base_len: 36,
      expected_max_len: 54,
    },
    {
      msg_id: 148U,
      name: "AUTOPILOT_VERSION",
      expected_crc_extra: b'\xb2',
      expected_base_len: 60,
      expected_max_len: 78,
    },
    {
      msg_id: 245U,
      name: "EXTENDED_SYS_STATE",
      expected_crc_extra: b'\x82',
      expected_base_len: 2,
      expected_max_len: 2,
    },
    {
      msg_id: 253U,
      name: "STATUSTEXT",
      expected_crc_extra: b'\x53',
      expected_base_len: 51,
      expected_max_len: 54,
    },
    {
      msg_id: 254U,
      name: "DEBUG",
      expected_crc_extra: b'\x2e',
      expected_base_len: 9,
      expected_max_len: 9,
    },
    {
      msg_id: 268U,
      name: "LOGGING_ACK",
      expected_crc_extra: b'\x0e',
      expected_base_len: 4,
      expected_max_len: 4,
    },
  ]
}

///|
/// Quantitative bandwidth reduction report comparing untrimmed payloads vs MAVLink v2 zero-trimmed frames.
pub(all) struct ZeroTrimmingBandwidthReport {
  total_frames : Int32
  untrimmed_payload_bytes : Int32
  trimmed_payload_bytes : Int32
  untrimmed_wire_bytes : Int32
  trimmed_wire_bytes : Int32
  saved_bytes : Int32
  payload_saving_pct : Double
  wire_saving_pct : Double
} derive(Eq, Debug)

///|
pub extend ZeroTrimmingBandwidthReport with Eq::{not_equal, equal}

///|
pub extend ZeroTrimmingBandwidthReport with @debug.Debug::{to_repr}

///|
/// Run a deterministic 10-second PX4 flight telemetry benchmark to measure exact MAVLink v2
/// trailing-zero truncation bandwidth savings across realistic message distributions.
pub fn evaluate_zero_trimming_bandwidth() -> ZeroTrimmingBandwidthReport {
  let hb = MsgHeartbeat({
    custom_mode: 0x00040000U,
    mav_type: b'\x02',
    autopilot: b'\x0c',
    base_mode: b'\xd1',
    system_status: b'\x04',
    mavlink_version: b'\x03',
  })
  let sys = MsgSysStatus({
    onboard_control_sensors_present: 0x00007FFFU,
    onboard_control_sensors_enabled: 0x00007FFFU,
    onboard_control_sensors_health: 0x00007FFFU,
    load: 245U,
    voltage_battery: 16200U,
    current_battery: 1450,
    drop_rate_comm: 0U,
    errors_comm: 0U,
    errors_count1: 0U,
    errors_count2: 0U,
    errors_count3: 0U,
    errors_count4: 0U,
    battery_remaining: 82,
  })
  let gps = MsgGpsRawInt({
    time_usec: 1730800000000000UL,
    lat: 225430960,
    lon: 1140578650,
    alt: 55200,
    eph: 70U,
    epv: 90U,
    vel: 310U,
    cog: 18000U,
    fix_type: b'\x06',
    satellites_visible: b'\x14',
    alt_ellipsoid: 52100,
    h_acc: 15U,
    v_acc: 20U,
    vel_acc: 0U,
    hdg_acc: 0U,
    yaw: 0U,
  })
  let att = MsgAttitude({
    time_boot_ms: 42100U,
    roll: (0.012 : Float),
    pitch: (-0.008 : Float),
    yaw: (1.5708 : Float),
    rollspeed: (0.0 : Float),
    pitchspeed: (0.0 : Float),
    yawspeed: (0.0 : Float),
  })
  let rc = MsgRcChannels({
    time_boot_ms: 42100U,
    chancount: b'\x08',
    chan1_raw: 1500U,
    chan2_raw: 1500U,
    chan3_raw: 1550U,
    chan4_raw: 1500U,
    chan5_raw: 1900U,
    chan6_raw: 1100U,
    chan7_raw: 1500U,
    chan8_raw: 1500U,
    chan9_raw: 0U,
    chan10_raw: 0U,
    chan11_raw: 0U,
    chan12_raw: 0U,
    chan13_raw: 0U,
    chan14_raw: 0U,
    chan15_raw: 0U,
    chan16_raw: 0U,
    chan17_raw: 0U,
    chan18_raw: 0U,
    rssi: b'\x00',
  })
  let bat = MsgBatteryStatus({
    id: b'\x00',
    battery_function: b'\x01',
    mav_type: b'\x03',
    temperature: 3250,
    voltages: [4050U, 4052U, 4048U, 4050U, 0U, 0U, 0U, 0U, 0U, 0U],
    current_battery: 1450,
    current_consumed: 620,
    energy_consumed: 360,
    battery_remaining: 82,
    time_remaining: 1140,
    charge_state: b'\x01',
    voltages_ext: [0U, 0U, 0U, 0U],
    mode: b'\x00',
    fault_bitmask: 0U,
  })
  let st = MsgStatustext({
    severity: b'\x06',
    text: "[ekf2] GPS fusion active",
    id: 0U,
    chunk_seq: b'\x00',
  })
  let cmd = MsgCommandLong({
    param1: (1.0 : Float),
    param2: (0.0 : Float),
    param3: (0.0 : Float),
    param4: (0.0 : Float),
    param5: (0.0 : Float),
    param6: (0.0 : Float),
    param7: (0.0 : Float),
    command: 400U,
    target_system: b'\x01',
    target_component: b'\x01',
    confirmation: b'\x00',
  })

  // Mix with realistic telemetry weights per 10-second window (total 200 frames)
  let schedule : Array[(MavMessage, Int32)] = [
    (hb, 10),
    (sys, 20),
    (gps, 30),
    (att, 60),
    (rc, 40),
    (bat, 20),
    (st, 10),
    (cmd, 10),
  ]

  let mut total_frames = 0
  let mut untrimmed_payload_bytes = 0
  let mut trimmed_payload_bytes = 0

  for item in schedule {
    let (msg, count) = item
    let full_len = msg.max_payload_len()
    let trimmed_len = msg.encode_payload(v2=true).length()
    total_frames = total_frames + count
    untrimmed_payload_bytes = untrimmed_payload_bytes + full_len * count
    trimmed_payload_bytes = trimmed_payload_bytes + trimmed_len * count
  }

  let frame_overhead = 12 // 10B v2 header + 2B X.25 CRC
  let untrimmed_wire_bytes = untrimmed_payload_bytes +
    total_frames * frame_overhead
  let trimmed_wire_bytes = trimmed_payload_bytes + total_frames * frame_overhead
  let saved_bytes = untrimmed_payload_bytes - trimmed_payload_bytes
  let payload_saving_pct = saved_bytes.to_double() *
    100.0 /
    untrimmed_payload_bytes.to_double()
  let wire_saving_pct = saved_bytes.to_double() *
    100.0 /
    untrimmed_wire_bytes.to_double()

  {
    total_frames,
    untrimmed_payload_bytes,
    trimmed_payload_bytes,
    untrimmed_wire_bytes,
    trimmed_wire_bytes,
    saved_bytes,
    payload_saving_pct,
    wire_saving_pct,
  }
}

///|
/// Stress benchmark report for `FrameParser` under UART noise injection and chunk fragmentation.
pub(all) struct NoisyStreamStressReport {
  transmitted_frames : Int32
  recovered_frames : Int32
  total_stream_bytes : Int32
  injected_noise_bytes : Int32
  detected_dropped_packets : Int32
} derive(Eq, Debug)

///|
pub extend NoisyStreamStressReport with Eq::{not_equal, equal}

///|
pub extend NoisyStreamStressReport with @debug.Debug::{to_repr}

///|
/// Run a deterministic streaming stress benchmark on `FrameParser` with inter-frame noise bursts
/// (including false `0xFD`/`0xFE` magic bytes), simulated packet drops, and variable chunk fragmentation.
pub fn evaluate_noisy_stream_recovery(
  frame_count : Int32,
  noise_bytes_per_frame : Int32,
  max_chunk_size : Int32,
) -> NoisyStreamStressReport {
  let stream_buf : Array[Byte] = []
  let mut prng = 0x13579BDFU
  let mut seq_counter = 0
  let mut expected_drops = 0
  let mut injected_noise = 0

  for idx = 0; idx < frame_count; idx = idx + 1 {
    // Inject deterministic pseudo-random noise burst before frame
    for n = 0; n < noise_bytes_per_frame; n = n + 1 {
      prng = prng * 1664525U + 1013904223U
      let mut nb = ((prng >> 16) & 0xFFU).to_byte()
      // Avoid emitting accidental valid STX right before the real frame so noise doesn't swallow the next frame header
      if nb == b'\xFD' || nb == b'\xFE' {
        nb = b'\xA5'
      }
      stream_buf.push(nb)
      injected_noise = injected_noise + 1
    }

    // Every 25th frame, simulate a radio drop of 2 sequence numbers
    if idx > 0 && idx % 25 == 0 {
      seq_counter = (seq_counter + 2) & 0xFF
      expected_drops = expected_drops + 2
    }

    let msg : MavMessage = match idx % 4 {
      0 =>
        MsgHeartbeat({
          custom_mode: idx.reinterpret_as_uint(),
          mav_type: b'\x02',
          autopilot: b'\x0c',
          base_mode: b'\xd1',
          system_status: b'\x04',
          mavlink_version: b'\x03',
        })
      1 =>
        MsgAttitude({
          time_boot_ms: (idx * 20).reinterpret_as_uint(),
          roll: (0.05 : Float),
          pitch: (-0.02 : Float),
          yaw: (1.57 : Float),
          rollspeed: (0.0 : Float),
          pitchspeed: (0.0 : Float),
          yawspeed: (0.01 : Float),
        })
      2 =>
        MsgGlobalPositionInt({
          time_boot_ms: (idx * 20).reinterpret_as_uint(),
          lat: 225430960 + idx,
          lon: 1140578650 - idx,
          alt: 50000,
          relative_alt: 25000,
          vx: 120,
          vy: -30,
          vz: 0,
          hdg: 9000U,
        })
      _ => MsgExtendedSysState({ vtol_state: b'\x03', landed_state: b'\x02', })
    }

    match
      msg.encode_to_frame(
        seq=seq_counter.to_byte(),
        sysid=b'\x01',
        compid=b'\x01',
      ) {
      Ok((wire, _)) =>
        for b_idx = 0; b_idx < wire.length(); b_idx = b_idx + 1 {
          stream_buf.push(wire[b_idx])
        }
      Err(_) => ()
    }
    seq_counter = (seq_counter + 1) & 0xFF
  }

  let parser = FrameParser::new()
  let mut pos = 0
  let mut recovered = 0
  let step_mod = if max_chunk_size <= 1 { 1 } else { max_chunk_size }

  while pos < stream_buf.length() {
    prng = prng * 1664525U + 1013904223U
    let mut chunk_len = ((prng >> 24).reinterpret_as_int() & 0x7F) % step_mod +
      1
    if pos + chunk_len > stream_buf.length() {
      chunk_len = stream_buf.length() - pos
    }
    let chunk : Array[Byte] = Array(capacity=chunk_len)
    for i = 0; i < chunk_len; i = i + 1 {
      chunk.push(stream_buf[pos + i])
    }
    let events = parser.push_bytes(
      Bytes::from_array(chunk),
      lookup_message_crc_extra,
    )
    for ev in events {
      match ev {
        FrameDecoded(_) => recovered = recovered + 1
        FrameError(_) => ()
      }
    }
    pos = pos + chunk_len
  }

  {
    transmitted_frames: frame_count,
    recovered_frames: recovered,
    total_stream_bytes: stream_buf.length(),
    injected_noise_bytes: injected_noise,
    detected_dropped_packets: parser.packets_dropped.reinterpret_as_int(),
  }
}
