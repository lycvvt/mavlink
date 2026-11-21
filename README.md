# mavlink

> **基于 MoonBit 实现的 MAVLink v2/v1 无人机通信协议栈、微服务状态机与官方 XML 自动代码生成器 (Zero FFI)**  
> A pure MoonBit implementation of the MAVLink v2/v1 wire protocol, SHA-256 packet signing, microservice state machines, and recursive XML dialect code generator.

[![CI](https://github.com/lycvvt/mavlink/actions/workflows/ci.yml/badge.svg)](https://github.com/lycvvt/mavlink/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Language](https://img.shields.io/badge/Language-MoonBit-purple.svg)](https://www.moonbitlang.com/)
[![Tests](https://img.shields.io/badge/Tests-100%2F100%20passed-success.svg)](mavlink_wbtest.mbt)

---

## 项目概述

`lycvvt/mavlink` 是参考官方 C 参考实现 [`c_library_v2`](https://github.com/mavlink/c_library_v2)、[`pymavlink`](https://github.com/ArduPilot/pymavlink) 与 Rust [`rust-mavlink`](https://github.com/mavlink/rust-mavlink) 的核心设计范式，用 100% 纯 MoonBit 实现的**无人机（PX4 / ArduPilot）与地面控制站（QGroundControl / MissionPlanner）通信协议栈、高阶微服务状态机及官方 XML 消息定义自动代码生成器**。涵盖 MAVLink v2 (`0xFD`) 与 v1 (`0xFE`) 双向帧编解码、字段按标量字节宽度降序重排（Wire Field Reordering）、ITU-T X.25 `CRC-16/MCRF4XX` 与动态 `CRC_EXTRA` 种子计算、v2 尾部零字节截断（Zero-Trimming）与透明零扩展（Zero-Extension）、基于 FIPS 180-4 SHA-256 的 13 字节帧安全签名与 48-bit 单调时间戳防重放校验、抗串口噪声流式状态机解析器（`FrameParser`）、五大标准微服务状态机（Heartbeat / Parameter / Mission / Command / Timesync），以及支持多文件 `<include>` 拓扑合并的官方 `<mavlink>` XML 自举代码生成工具链。

### 典型应用场景
1. **无人机机载伴侣计算机（Companion Computer）与边缘网关**：依托 MoonBit 极小的编译产物与确定性内存管理，在机载计算板或物联网边缘网关上解析串口/UDP 飞控遥测流、同步机载参数、管理双向航点任务并下发姿态/位置控制指令。
2. **WebAssembly 跨平台地面控制站（Wasm GCS）与在线协议调试**：利用零外部 FFI 依赖特性，直接编译为 `wasm-gc` 嵌入浏览器地面站前端，配合 `web/index.html` 实现零后端依赖的线上帧字节流剖析、CRC 验算与在线 XML 方言编译。
3. **自定义机载载荷与多文件方言（Custom Dialect）自动化开发**：针对农业植保喷洒系统、光学吊舱、激光雷达或水下机器人等扩展载荷，通过 `<include>minimal.xml</include>` 继承官方基础定义并一键生成零警告、强类型的 MoonBit 编解码代码。

### 与主流语言成熟实现的功能与边界对标
| 对比维度 | 官方 C `c_library_v2` + `pymavlink` | Rust `rust-mavlink` | `lycvvt/mavlink` (本项目) |
| :--- | :--- | :--- | :--- |
| **定位与依赖** | Python 生成器 (`mavgen.py`) + C 头文件宏 | Rust `build.rs` 构建期 XML 解析生成 | **纯 MoonBit 零 FFI 协议核心 + 微服务状态机 + 原生自举 XML 代码生成器** |
| **帧协议版本** | MAVLink v1 (`0xFE`) / v2 (`0xFD`) | MAVLink v1 / v2 | **MAVLink v1 (`0xFE`, 6B 头) / v2 (`0xFD`, 10B 头, 24-bit MSGID)** |
| **多文件 `<include>` 解析** | `mavgen.py` 构建期合并 | `build.rs` 构建期合并 | **支持运行期与构建期 DAG 拓扑 `<include>` 合并、菱形依赖去重与循环引用拦截** |
| **字段重排与定长数组** | 支持标量重排与 C 定长数组 | 支持标量重排与 Rust 定长数组 | **支持 8B→4B→2B→1B 稳定降序重排、`char[N]` 及 `FixedArray[T]` 越界防卫编码** |
| **v2 尾部零截断与扩展** | 支持 `_mav_trim_payload` 与零填充拷贝 | 支持 v2 零字节截断与反序列化零扩展 | **支持**：200 帧 PX4 遥测流实测压缩载荷 **22.56%**（节省整帧无线带宽 **17.13%**） |
| **SHA-256 13B 帧签名** | 支持（需注入回调或状态结构） | 部分分支支持 | **原生内置 FIPS 180-4 SHA-256 与 48-bit 单调时间戳防重放攻击** |
| **高阶微服务状态机** | 不含（仅提供底层帧序列化，状态机在 MAVSDK） | 不含（位于外部上层库） | **原生内置 7 大微服务与诊断组件**：Heartbeat、Parameter、Mission、Command、Timesync、FTP (#110)、TelemetryRateTracker |
| **外设硬件驱动 / 传输层** | 不含串口/套接字驱动（纯字节流编解码） | 可选 `tokio` / `serialport` 适配层 | **明确非目标**：仅负责纯字节流帧编解码与协议状态机，与底层 OS I/O 解耦 |

### 协议一致性与工程适用边界
- **字节流二进制兼容性边界**：严格遵循 MAVLink v2 官方线序规范。所有基础字段（`<extensions/>` 之前）按标量元素字节宽度（8B → 4B → 2B → 1B）执行稳定降序排列，扩展字段保持 XML 声明顺序追加在末尾；定长数组字段（如 `float[4]`、`uint16_t[10]`、`uint8_t[251]`）按单元素宽度参与重排，并在计算 `CRC_EXTRA` 时向 X.25 累加器注入单字节数组长度。经 [`cmd/benchmark`](cmd/benchmark/main.mbt) 实测，内置 **60 条标准消息** 的 `CRC_EXTRA`、`base_payload_len` 与 `max_payload_len` 与官方 C `c_library_v2` 100% 一致。
- **MAVLink v1 与 v2 消息 ID 边界**：MAVLink v1 帧头仅支持 8-bit 消息 ID（`0 .. 255`），不支持 `<extensions/>` 截断与 13 字节签名块；当尝试使用 v1 协议编码消息 ID $> 255$（如 `LOGGING_ACK #268`）时，编码器确定性返回 `Err(MavError::V1MessageIdOverflow(msgid))`。
- **XML Schema 与定长数组边界**：单条消息最大载荷受限于协议规范的 `255` 字节上限（`255B` 通过校验，`256B` 返回 `Err(MavError::SchemaError(_))`）；自动生成的 `FixedArray[T]` 编码器对长度不足 `N` 的输入数组自动补零，对超出 `N` 的输入数组安全截断至 `N` 个元素，保证线序偏移绝对恒定。

---

## 核心特性

- **基础类型与结构化错误模型 (`types.mbt`)**
  - 协议版本枚举 `ProtocolVersion`（`V1` `0xFE` / `V2` `0xFD`）、帧头结构 `MavHeader`、13 字节签名结构 `MavSignature` 及完整传输帧 `MavFrame`。
  - 结构化错误枚举 `MavError`：覆盖 `InvalidMagic`、`IncompleteFrame`、`PayloadTooLong`、`UnknownMessageId`、`CrcMismatch`、`SignatureInvalid`、`V1MessageIdOverflow`、`XmlParseError` 与 `SchemaError`。

- **ITU-T X.25 校验与动态 `CRC_EXTRA` 引擎 (`crc.mbt`)**
  - 标准多项式 `0x1021`、初始值 `0xFFFF` 的 `CRC-16/MCRF4XX` 累加器 `X25Crc`。
  - 动态 `compute_crc_extra` 算法：根据消息名与重排后的基础字段序列实时推导 `CRC_EXTRA` 种子字节。

- **小端序载荷序列化与零字节压缩 (`payload.mbt`)**
  - 小端序写入器 `PayloadWriter` 与读取器 `PayloadReader`，支持全系标量类型、定长 ASCII 字符串 `char[N]` 及定长数值数组 `FixedArray[T]`。
  - MAVLink v2 尾部连续零字节自动截断（`truncate_trailing_zeros`）与接收端越界透明补零（Zero-Extension）。

- **FIPS 180-4 SHA-256 与 13 字节安全帧签名 (`signing.mbt`)**
  - 纯 MoonBit 实现的 `sha256_digest` 消息摘要算法（通过 NIST FIPS 180-4 单块与多块标准向量验证）。
  - 会话签名上下文 `SigningContext`：基于 32 字节共享密钥生成或验证 `link_id (1B) + timestamp (6B LE) + sha256_48 (6B)`，强制执行 48-bit 时间戳严格单调递增以拦截重放帧。

- **双向帧编解码与串口抗噪流式解析 (`frame.mbt`)**
  - 单帧无状态编解码函数 `encode_frame` 与 `decode_frame`。
  - 面向 UART / SiK 数传电台 / UDP 分片环境的流式状态机 `FrameParser`：支持前导乱码跳过、任意分片半包重组、CRC 失败单字节滑动重同步及基于 `seq` 的链路丢包计数 `packets_dropped`。

- **高阶 MAVLink v2 微服务状态机与遥测诊断 (`microservices.mbt`)**
  - **多节点心跳与链路质量监控 (`HeartbeatMonitor`)**：追踪多飞控/组件节点的在线状态（`is_node_alive`）、解锁状态（`armed`）、飞行模式与丢包率（`node_packet_loss_ratio`）。
  - **机载参数同步服务 (`ParameterClient` / `ParameterServer`)**：支持全量参数列表拉取（`PARAM_REQUEST_LIST`）、丢包缺失索引自动定位与定向补齐（`PARAM_REQUEST_READ`）、带验证回执的 `PARAM_SET` 参数修改与超时重试熔断。
  - **双向航点任务服务 (`MissionUploadClient` / `MissionDownloadClient` / `MissionServer`)**：支持航点列表上传、下载、清空（`MISSION_CLEAR_ALL`）、当前航点切换（`MISSION_SET_CURRENT`）、乱序航点拒绝（`MavMissionInvalidSequence`）与超时重传。
  - **控制指令状态机 (`CommandClient`)**：支持 `COMMAND_LONG` 超时重传时自动递增 `confirmation` 计数器（`0 → 1 → 2...`）、`MAV_RESULT_IN_PROGRESS` 进度百分比追踪与 `COMMAND_CANCEL` (#80) 取消指令。
  - **双向时钟同步与时延估计 (`TimesyncEstimator`)**：基于 `TIMESYNC` (#111) 计算往返时延（RTT）与机载时钟偏移，内置 EMA 指数滑动平均抖动滤波。
  - **机载文件传输子协议与虚拟文件服务 (`FtpOpcode` / `FtpPacket` / `FtpServer`)**：在 `FILE_TRANSFER_PROTOCOL` (#110) 的 251 字节载荷中封装 12 字节小端序 FTP 帧头与最多 239 字节数据，支持 18 种标准 FTP 操作码及内存态虚拟文件系统读写（`OpenFileRO`、`ReadFile`、`ListDirectory`、`TerminateSession`）。
  - **扩展参数服务 (`ExtendedParameterClient` / `ExtendedParameterServer`)**：支持 128 字节 `PARAM_EXT_*` (#320..#324) 云台/相机/载荷参数列表同步与带类型校验的 `PARAM_EXT_SET` -> `PARAM_EXT_ACK` 事务。
  - **遥测流频率与带宽统计 (`TelemetryRateTracker`)**：按消息 ID 实时统计接收帧率（Hz）与链路总吞吐率（Bytes/s）。

- **多链路路由桥接与 QGroundControl `.tlog` 遥测录制回放 (`router.mbt` / `tlog.mbt`)**
  - **多链路路由器 (`MavRouter`)**：参考 `mavlink-router` 设计，自动从入站帧学习 `(sysid, compid) -> link_port` 路由表，精准识别单播与广播消息并执行水平分割防环转发（Split-Horizon Loop Prevention）。
  - **QGroundControl `.tlog` 二进制录制与回放 (`TlogRecorder` / `decode_tlog_stream`)**：支持标准 64-bit 大端序微秒时间戳（`uint64_t BE`）+ 原始 MAVLink 帧的 `.tlog` 格式编码、流式解码、时间窗口切片（`filter_tlog_by_time_range`）与按消息 ID 过滤（`filter_tlog_by_msgid`）。

- **多文件 `<include>` XML 解析与自举代码生成器 (`xml.mbt` / `codegen.mbt` / `standard_dialect.mbt`)**
  - 支持单文件 `parse_dialect_xml` 与多文件递归 `parse_dialect_xml_with_includes`（含菱形依赖去重与循环 `<include>` 检测）。
  - 自动生成枚举、消息结构体、`encode_payload` / `decode_payload` 及顶层 `MavMessage` 联合分发器，内置保留字转义（`type` → `mav_type`）、核心类型防冲突映射（`MAV_FRAME` → `MavCoordFrame`、`DEBUG` → `MavDebug`）与单字母字段反遮蔽保护。

---

## 快速开始

### 环境要求
- MoonBit CLI 工具链（当前验证版本：`moon 0.1.20261028` / `moonc v0.10.18`）

### 安装依赖
```bash
moon add lycvvt/mavlink
```

### 运行测试
执行全量 100 项白盒、黑盒、黄金向量、微服务状态机、多链路路由、`.tlog` 回放与随机流 Fuzz 测试：
```bash
moon test
```

### 运行命令行工具与基准测试套件
```bash
# 1. 运行协议栈闭环验证与综合演示 CLI
moon run cmd/main

# 2. 运行官方 XML -> MoonBit 自举代码生成器 CLI
moon run cmd/codegen

# 3. 运行 60 条官方消息黄金向量核验、v1/v2 带宽基准、SHA-256 安全审计与强噪声恢复压测 CLI
moon run cmd/benchmark
```

### 运行独立工程示例
```bash
# 示例 1: PX4 四旋翼无人机多帧 SHA-256 签名遥测流与串口抗噪解析仿真
moon run examples/px4_telemetry

# 示例 2: QGroundControl 地面站与无人机双向航点上传任务协议 (Mission Protocol) 状态机
moon run examples/gcs_mission_protocol

# 示例 3: 自定义农业植保机载荷 XML 方言实时解析、重排与 MoonBit 代码生成
moon run examples/xml_codegen_custom

# 示例 4: 五大 MAVLink v2 微服务（Heartbeat / Parameter / Command / Timesync）闭环联调仿真
moon run examples/microservices_closed_loop

# 示例 5: 多链路路由器 (MavRouter)、虚拟 FTP 文件服务 (#110) 与 QGroundControl .tlog 录制回放
moon run examples/tlog_router_bridge
```

### 代码使用示例

#### 1. MAVLink v2 签名帧编码与串口流式抗噪解析 (`FrameParser`)
```moonbit
// 构造 32 字节共享密钥 SHA-256 签名上下文
let signer = @mavlink.SigningContext::new(
  b"0123456789abcdef0123456789abcdef",
  link_id=b'\x01',
  initial_timestamp=100_000UL,
).unwrap()

let hb : @mavlink.Heartbeat = {
  custom_mode: 0x00040000U,
  mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
  autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
  base_mode: b'\xd1',
  system_status: @mavlink.MavState::Active.to_uint().to_byte(),
  mavlink_version: b'\x03',
}

let (wire_bytes, _) = @mavlink.MavMessage::MsgHeartbeat(hb)
  .encode_to_frame(seq=b'\x01', sysid=b'\x01', compid=b'\x01', signing=Some(signer))
  .unwrap()

// 接收端流式解析并还原强类型消息
let parser = @mavlink.FrameParser::new()
for ev in parser.push_bytes(wire_bytes, @mavlink.lookup_message_crc_extra) {
  match ev {
    @mavlink.ParseStreamEvent::FrameDecoded(frame) => {
      let msg = @mavlink.MavMessage::decode_from_frame(frame).unwrap()
      println("Decoded message: \{msg.msg_name()} (#\{msg.msg_id()})")
    }
    @mavlink.ParseStreamEvent::FrameError(err) => println("Error: \{err.to_repr()}")
  }
}
```

#### 2. 高阶微服务状态机调用 (`ParameterClient` / `CommandClient` / `TimesyncEstimator`)
```moonbit
// (a) 参数同步客户端：发起全量参数列表同步并在超时时自动请求缺失索引
let param_cli = @mavlink.ParameterClient::new(b'\x01', b'\x01', timeout_ms=500UL)
let req_list_msg = param_cli.start_list_sync(1000UL)

// (b) 控制指令客户端：超时重传自动递增 confirmation 计数器 (0 -> 1 -> 2...)
let cmd_cli = @mavlink.CommandClient::new(b'\x01', b'\x01', timeout_ms=500UL)
let arm_msg = cmd_cli.send_command_long(
  @mavlink.MavCmd::ComponentArmDisarm.to_uint(),
  2000UL,
  param1=(1.0 : Float),
)

// (c) 双向 TIMESYNC 时钟偏移与 RTT 估计器
let ts_est = @mavlink.TimesyncEstimator::new()
let probe_msg = @mavlink.TimesyncEstimator::create_probe(1_000_000_000L)
```

#### 3. 多文件 `<include>` 官方 XML 解析与 MoonBit 代码自动生成
```moonbit
let (merged_schema, moonbit_code) = @mavlink.generate_moonbit_from_xml_with_includes(
  "custom_dialect.xml",
  fn(file_name) {
    if file_name == "custom_dialect.xml" {
      Some(my_custom_xml_string) // 内部可通过 <include>minimal.xml</include> 继承基础方言
    } else {
      @mavlink.builtin_xml_resolver(file_name)
    }
  },
).unwrap()
```

---

## 内置标准方言消息表 (60 Messages & 22 Enums)

[`standard_dialect.mbt`](standard_dialect.mbt) 由 [`cmd/codegen`](cmd/codegen/main.mbt) 从 [`xml_catalog.mbt`](xml_catalog.mbt) 自举生成，完整覆盖以下 **60 条 PX4 / ArduPilot 官方飞控消息** 与 **22 个标准枚举**：

| 消息分类 | 内置官方消息列表 (ID 与名称) |
| :--- | :--- |
| **系统心跳与链路管理 (8 条)** | `#0 HEARTBEAT` (`CRC=50`), `#1 SYS_STATUS` (`124`), `#2 SYSTEM_TIME` (`137`), `#4 PING` (`237`), `#11 SET_MODE` (`89`), `#148 AUTOPILOT_VERSION` (`178`), `#242 HOME_POSITION` (`104`), `#245 EXTENDED_SYS_STATE` (`130`) |
| **标准与扩展参数协议 (9 条)** | `#20 PARAM_REQUEST_READ` (`214`), `#21 PARAM_REQUEST_LIST` (`159`), `#22 PARAM_VALUE` (`220`), `#23 PARAM_SET` (`168`), `#320 PARAM_EXT_REQUEST_READ` (`243`), `#321 PARAM_EXT_REQUEST_LIST` (`88`), `#322 PARAM_EXT_VALUE` (`243`), `#323 PARAM_EXT_SET` (`78`), `#324 PARAM_EXT_ACK` (`132`) |
| **IMU/光流/气压/测距/电池 (8 条)** | `#24 GPS_RAW_INT` (`24`), `#26 SCALED_IMU` (`170`), `#27 RAW_IMU` (`144`), `#29 SCALED_PRESSURE` (`115`), `#100 OPTICAL_FLOW` (`175`), `#105 HIGHRES_IMU` (`93`), `#132 DISTANCE_SENSOR` (`85`), `#147 BATTERY_STATUS` (`154`) |
| **姿态四元数、导航与 HUD (8 条)** | `#30 ATTITUDE` (`39`), `#31 ATTITUDE_QUATERNION` (`246`), `#32 LOCAL_POSITION_NED` (`185`), `#33 GLOBAL_POSITION_INT` (`104`), `#74 VFR_HUD` (`20`), `#83 ATTITUDE_TARGET` (`22`), `#84 SET_POSITION_TARGET_LOCAL_NED` (`143`), `#85 POSITION_TARGET_LOCAL_NED` (`140`) |
| **遥控通道、舵机与姿态控制 (5 条)** | `#35 RC_CHANNELS_RAW` (`244`), `#36 SERVO_OUTPUT_RAW` (`222`), `#65 RC_CHANNELS` (`118`), `#69 MANUAL_CONTROL` (`243`), `#82 SET_ATTITUDE_TARGET` (`49`) |
| **双向航点任务协议 (12 条)** | `#38 MISSION_WRITE_PARTIAL_LIST` (`9`), `#39 MISSION_ITEM` (`254`), `#40 MISSION_REQUEST` (`230`), `#41 MISSION_SET_CURRENT` (`28`), `#42 MISSION_CURRENT` (`28`), `#43 MISSION_REQUEST_LIST` (`132`), `#44 MISSION_COUNT` (`221`), `#45 MISSION_CLEAR_ALL` (`232`), `#46 MISSION_ITEM_REACHED` (`11`), `#47 MISSION_ACK` (`153`), `#51 MISSION_REQUEST_INT` (`196`), `#73 MISSION_ITEM_INT` (`38`) |
| **控制指令、FTP、时钟同步与日志 (10 条)** | `#75 COMMAND_INT` (`158`), `#76 COMMAND_LONG` (`152`), `#77 COMMAND_ACK` (`143`), `#80 COMMAND_CANCEL` (`14`), `#110 FILE_TRANSFER_PROTOCOL` (`84`), `#111 TIMESYNC` (`34`), `#253 STATUSTEXT` (`83`), `#254 DEBUG` (`46`), `#266 LOGGING_DATA` (`193`), `#268 LOGGING_ACK` (`14`) |

> 全部 60 条消息的逐项 `CRC_EXTRA` 黄金向量核验表、200 帧 PX4 遥测流带宽压缩实测数据与强噪声分片压测数据详见 [docs/BENCHMARK_AND_BOUNDARIES.md](docs/BENCHMARK_AND_BOUNDARIES.md)。

---

## 协议验证与实测基准汇总

本项目建立 100 项对齐官方 MAVLink v2 规范与 NIST 密码学标准的自动化测试套件（[`mavlink_wbtest.mbt`](mavlink_wbtest.mbt) 83 项白盒测试与 [`mavlink_test.mbt`](mavlink_test.mbt) 17 项黑盒测试）：

| 编号 | 测试与基准模块 | 验证基准与技术点 | 实测验证结果 | 判定 |
| :---: | :--- | :--- | :---: | :---: |
| **1** | **ITU-T X.25 CRC 累加器** | 标准 ASCII 向量 `"123456789"` 校验值与分片累积等价性 | 精确等于 `0x906E` | PASS |
| **2** | **60 条消息 `CRC_EXTRA` 黄金向量** | 对照官方 C `c_library_v2` 核验全部 60 条消息的 `CRC_EXTRA` 与 `base/max_len` | **60 / 60 (100% 吻合)** | PASS |
| **3** | **小端序极值与定长数组边界** | 有符号/无符号整数极值、IEEE-754 `-0.0`、`char[N]` 嵌零截断、`FixedArray` 补零/截断 | 双向无损闭环 | PASS |
| **4** | **v2 尾部零截断带宽收益基准** | 200 帧典型 PX4 混合遥测流（未压缩载荷 `7,580 B` vs 零截断后 `5,870 B`） | **载荷压缩 22.56%，整帧节省 17.13%** | PASS |
| **5** | **v1 vs v2 线上帧带宽交叉对标** | 100 帧飞控控制与状态批次（v1 固定长 `4,125 B` vs v2 零截断 `3,580 B`） | **v2 比 v1 净省 545 B (-13.21%)** | PASS |
| **6** | **SHA-256 签名与 50 次攻击审计** | 100 帧合法签名 + 50 帧对抗攻击（15 重放、15 回退、10 伪造密钥、10 标签篡改） | **100/100 放行，50/50 攻击拦截** | PASS |
| **7** | **`FrameParser` 强噪声与极端分片** | 200 帧遥测注入 `32B/帧` 随机噪声（共 `6,400B` 噪声）并以 `1B` 单字节逐粒推入 | **200 / 200 帧恢复，14/14 丢包捕获** | PASS |
| **8** | **1,024B 伪随机含假同步字 Fuzz** | 含伪造 `0xFD`/`0xFE` 的 1,024B 随机损坏字节流 + 签名帧恢复 | 零崩溃，100% 还原签名帧 | PASS |
| **9** | **高阶微服务、多链路路由与 `.tlog`** | Heartbeat、Param/ParamExt、Mission、Command、Timesync、FTP、MavRouter 与 `.tlog` 回放 | 状态转移与防环转发 100% 准确 | PASS |
| **10** | **多文件 `<include>` XML 代码生成** | DAG 拓扑合并、菱形依赖去重、循环包含拦截、`255B/256B` 载荷上限边界 | 自举编译 `0 warnings` | PASS |

---

## 架构与目录结构

```text
mavlink/
├── moon.mod                            # MoonBit 模块配置清单 (lycvvt/mavlink v0.4.0)
├── moon.pkg                            # 根包导入配置
├── LICENSE                             # Apache-2.0 许可证
├── NOTICE                              # 第三方知识来源与官方 MAVLink XML Schema 声明
├── README.md                           # 项目工程文档
├── .github/workflows/ci.yml            # GitHub Actions 自动化 CI 工作流
├── types.mbt                           # 协议版本、帧头、签名块与错误类型 MavError
├── crc.mbt                             # ITU-T X.25 CRC-16/MCRF4XX 与动态 CRC_EXTRA 计算
├── payload.mbt                         # 小端序读写器、定长字符串与 v2 零字节截断/扩展
├── signing.mbt                         # FIPS 180-4 SHA-256 与 13 字节帧安全签名上下文
├── frame.mbt                           # v1/v2 帧编解码与串口流式状态机 FrameParser
├── xml.mbt                             # 官方 <mavlink> XML 解析器、多文件 <include> 合并与重排引擎
├── codegen.mbt                         # 自举式 MoonBit 强类型编解码代码生成器
├── xml_catalog.mbt                     # 官方 minimal.xml + common.xml (22 枚举 / 60 消息) 定义
├── standard_dialect.mbt                # 由代码生成器自举产出的 22 个枚举与 60 条消息实现
├── microservices.mbt                   # 高阶微服务状态机 (Heartbeat/Param/ParamExt/Mission/Cmd/Timesync/FTP/Rate)
├── router.mbt                          # 多链路 MAVLink 路由器 MavRouter (源地址学习 / 单播转发 / 防环广播)
├── tlog.mbt                            # QGroundControl .tlog 64-bit 微秒时间戳遥测录制与回放引擎
├── benchmark.mbt                       # 60 条消息黄金向量核验、v1/v2 带宽基准与安全/抗噪压测引擎
├── mavlink_wbtest.mbt                  # 83 项白盒单元、边界、微服务、路由器、.tlog 与 Fuzz 测试
├── mavlink_test.mbt                    # 17 项黑盒集成测试
├── cmd/
│   ├── main/                           # 协议栈闭环验证与综合演示 CLI
│   ├── codegen/                        # 官方 XML -> MoonBit 命令行代码生成器
│   └── benchmark/                      # 黄金向量审计与带宽/抗噪基准评测 CLI
├── examples/
│   ├── px4_telemetry/                  # 示例 1: PX4 四旋翼签名遥测流与串口抗噪解析
│   ├── gcs_mission_protocol/           # 示例 2: 地面站与飞控双向航点上传状态机
│   ├── xml_codegen_custom/             # 示例 3: 自定义植保机 XML 方言实时代码生成
│   ├── microservices_closed_loop/      # 示例 4: 高阶 MAVLink v2 微服务闭环联调仿真
│   └── tlog_router_bridge/             # 示例 5: 多链路路由器、FTP 虚拟文件服务与 QGC .tlog 回放
├── web/
│   └── index.html                      # 纯前端 MAVLink v2 帧剖析与 XML 代码生成工作台
└── docs/
    ├── dedup.md                        # Mooncakes.io 与 GitHub 生态查重报告
    ├── plan.md                         # 架构设计与协议数学规范（X.25 / 字段重排 / SHA-256）
    ├── decisions.md                    # 关键工程设计决策记录 (ADR-001 ~ ADR-004)
    ├── BENCHMARK_AND_BOUNDARIES.md     # 45 条消息黄金向量对标、实测带宽基准与适用边界白皮书
    └── ACCEPTANCE.md                   # 工程验收与自检核验报告
```

---

## 协议规范与参考来源

1. [MAVLink Developer Guide — Serialization & Packet Framing](https://mavlink.io/en/guide/serialization.html)（字段重排、尾部零截断与 `CRC_EXTRA` 规范）。
2. [MAVLink Developer Guide — Message Signing](https://mavlink.io/en/guide/message_signing.html)（SHA-256 13 字节帧签名与 48-bit 时间戳防重放规范）。
3. [MAVLink Developer Guide — Microservices (Heartbeat / Parameter / Mission / Command / Timesync)](https://mavlink.io/en/services/)。
4. [mavlink/mavlink](https://github.com/mavlink/mavlink) — 官方 XML 消息定义仓库（`minimal.xml`、`common.xml`）。

---

## 许可证

本项目基于 [Apache-2.0 License](LICENSE) 开源，第三方协议规范说明参见 [NOTICE](NOTICE)。
