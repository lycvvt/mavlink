# mavlink

> **基于 MoonBit 实现的 MAVLink v2/v1 无人机通信协议栈与官方 XML 自动代码生成器 (Zero FFI)**  
> A pure MoonBit implementation of the MAVLink v2/v1 wire protocol, cryptographic packet signing, and self-hosted XML dialect code generator.

[![CI](https://github.com/lycvvt/mavlink/actions/workflows/ci.yml/badge.svg)](https://github.com/lycvvt/mavlink/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Language](https://img.shields.io/badge/Language-MoonBit-purple.svg)](https://www.moonbitlang.com/)
[![Tests](https://img.shields.io/badge/Tests-40%2F40%20passed-success.svg)](mavlink_wbtest.mbt)

---

## 项目概述

`lycvvt/mavlink` 是参考官方 C 参考实现 [`c_library_v2`](https://github.com/mavlink/c_library_v2)、[`pymavlink`](https://github.com/ArduPilot/pymavlink) 与 Rust [`rust-mavlink`](https://github.com/mavlink/rust-mavlink) 的核心设计范式，用 100% 纯 MoonBit 实现的**无人机（PX4 / ArduPilot）与地面控制站（QGroundControl / MissionPlanner）通信协议栈及官方 XML 消息定义自动代码生成器**。涵盖 MAVLink v2 (`0xFD`) 与 v1 (`0xFE`) 双向帧编解码、字段按标量字节宽度降序重排（Wire Field Reordering）、ITU-T X.25 `CRC-16/MCRF4XX` 与动态 `CRC_EXTRA` 种子计算、v2 尾部零字节截断（Zero-Trimming）与透明零扩展（Zero-Extension）、基于 FIPS 180-4 SHA-256 的 13 字节帧安全签名与 48-bit 单调时间戳防重放校验、抗串口噪声流式状态机解析器（`FrameParser`），以及从官方 `<mavlink>` XML 自动生成强类型 MoonBit 编解码代码的自举工具链。

### 典型应用场景
1. **机载伴侣计算机（Companion Computer）与边缘网关**：依托 MoonBit 极小的编译产物与确定性内存管理，在无人机机载计算板或边缘物联网网关上解析串口/UDP 飞控遥测流、下发航点与控制指令。
2. **WebAssembly 跨平台地面控制站（Wasm GCS）与在线仿真**：利用零外部 FFI 依赖特性，直接编译为 `wasm-gc` 嵌入浏览器地面站前端，配合 `web/index.html` 实现零后端依赖的线上帧字节流剖析、CRC 验算与在线 XML 方言编译。
3. **自定义机载载荷与私有方言（Custom Dialect）快速开发**：针对农业植保喷洒系统、机载云台、激光雷达或水下机器人等扩展载荷，直接修改或导入官方格式 XML 定义文件，通过内置代码生成器一键产出无警告、强类型的 MoonBit 序列化代码。

### 与主流语言成熟实现的功能与边界对标
| 对比维度 | 官方 C `c_library_v2` + `pymavlink` | Rust `rust-mavlink` | `lycvvt/mavlink` (本项目) |
| :--- | :--- | :--- | :--- |
| **定位与依赖** | Python 生成器 (`mavgen.py`) + C 头文件宏 | Rust `build.rs` 构建期 XML 解析生成 | **纯 MoonBit 零 FFI 协议核心 + 原生自举 XML 代码生成器** |
| **帧协议版本** | MAVLink v1 (`0xFE`) / v2 (`0xFD`) | MAVLink v1 / v2 | **MAVLink v1 (`0xFE`, 6B 头) / v2 (`0xFD`, 10B 头, 24-bit MSGID)** |
| **字段重排与 `CRC_EXTRA`** | 构建期由 Python 计算静态数组 | 构建期计算静态 `EXTRA_CRC` | **支持运行期与构建期双模式动态重排及 `CRC_EXTRA` 精确推导** |
| **v2 尾部零截断与扩展** | 支持 `_mav_trim_payload` 与零填充拷贝 | 支持 v2 零字节截断与反序列化零扩展 | **支持**：`truncate_trailing_zeros` 与 `PayloadReader` 越界透明补零 |
| **SHA-256 13B 帧签名** | 支持（需注入回调或状态结构） | 部分分支支持 | **原生内置 FIPS 180-4 SHA-256 与 48-bit 单调时间戳防重放攻击** |
| **外设硬件驱动 / 传输层** | 不含串口/套接字驱动（纯字节流编解码） | 可选 `tokio` / `serialport` 适配层 | **明确非目标**：仅负责纯字节流帧编解码与协议状态机，与底层 I/O 解耦 |

### 协议一致性与工程适用边界
- **字节流二进制兼容性边界**：严格遵循 MAVLink v2 官方线序规范。所有基础字段（`<extensions/>` 之前）按标量元素字节宽度（8B → 4B → 2B → 1B）执行稳定降序排列，扩展字段保持 XML 声明顺序追加在末尾；定长数组字段（如 `uint16_t[4]`）按单元素宽度（2B）参与重排，并在计算 `CRC_EXTRA` 时向 X.25 累加器注入单字节数组长度。经验证，内置 20 条标准消息的 `CRC_EXTRA` 与官方 C/PX4 固件 100% 一致。
- **MAVLink v1 与 v2 消息 ID 边界**：MAVLink v1 帧头仅支持 8-bit 消息 ID（`0 .. 255`），并且不支持 `<extensions/>` 截断与 13 字节签名块；当尝试使用 v1 协议编码消息 ID $> 255$（如 `LOGGING_ACK #268`）时，编码器将确定性返回 `Err(MavError::V1MessageIdOverflow(msgid))`。
- **XML 解析器适用边界**：内置 `parse_dialect_xml` 专为官方 `<mavlink>` Schema 结构设计（支持 XML 注释剥离、`<?xml ...?>` 声明、`<include>`、`<enums>`、`<messages>`、`<extensions/>` 与标准实体转义），单条消息最大载荷严格受限于协议规范的 `255` 字节上限，超出时返回 `Err(MavError::SchemaError(_))`。

---

## 核心特性

- **基础类型与结构化错误模型 (`types.mbt`)**
  - 协议版本枚举 `ProtocolVersion`（`V1` `0xFE` / `V2` `0xFD`）、帧头结构 `MavHeader`、13 字节签名结构 `MavSignature` 及完整传输帧 `MavFrame`。
  - 结构化错误枚举 `MavError`：覆盖 `InvalidMagic`、`IncompleteFrame`、`PayloadTooLong`、`UnknownMessageId`、`CrcMismatch`、`SignatureInvalid`、`V1MessageIdOverflow`、`XmlParseError` 与 `SchemaError`。

- **ITU-T X.25 校验与动态 `CRC_EXTRA` 引擎 (`crc.mbt`)**
  - 标准多项式 `0x1021`、初始值 `0xFFFF` 的 `CRC-16/MCRF4XX` 累加器 `X25Crc`。
  - 动态 `compute_crc_extra` 算法：根据消息名与重排后的基础字段序列实时计算 `CRC_EXTRA` 种子字节。

- **小端序载荷序列化与零字节压缩 (`payload.mbt`)**
  - 小端序写入器 `PayloadWriter` 与读取器 `PayloadReader`，支持 `uint8_t` ~ `uint64_t`、`int8_t` ~ `int64_t`、`float`（IEEE-754 单精度）、`double`（双精度）及定长 ASCII 字符串 `char[N]`。
  - MAVLink v2 尾部连续零字节自动截断（`truncate_trailing_zeros`）与接收端越界透明补零（Zero-Extension）。

- **FIPS 180-4 SHA-256 与 13 字节安全帧签名 (`signing.mbt`)**
  - 纯 MoonBit 实现的 `sha256_digest` 消息摘要算法（通过 NIST FIPS 180-4 单块与多块标准向量验证）。
  - 会话签名上下文 `SigningContext`：基于 32 字节共享密钥生成或验证 `link_id (1B) + timestamp (6B LE) + sha256_48 (6B)`，强制执行 48-bit 时间戳严格单调递增以拦截重放帧。

- **双向帧编解码与串口抗噪流式解析 (`frame.mbt`)**
  - 单帧无状态编解码函数 `encode_frame` 与 `decode_frame`。
  - 面向 UART / SiK 数传电台 / UDP 分片环境的流式状态机 `FrameParser`：支持前导乱码跳过、任意分片半包重组、CRC 失败单字节滑动重同步及基于 `seq` 的链路丢包计数 `dropped_packets`。

- **官方 XML 解析与自举式代码生成器 (`xml.mbt` / `codegen.mbt` / `standard_dialect.mbt`)**
  - 解析 `<mavlink>` XML 定义并执行字段线序重排与字节偏移量（`wire_offset`）推导。
  - 自动生成枚举、消息结构体、`encode_payload` / `decode_payload` 及顶层 `MavMessage` 联合分发器，内置 MoonBit 保留字转义（`type` → `mav_type`）与核心类型防冲突映射（`MAV_FRAME` → `MavCoordFrame`）。

---

## 快速开始

### 环境要求
- MoonBit CLI 工具链（当前验证版本：`moon 0.1.20261028` / `moonc v0.10.18`）

### 运行测试
执行全量 40 项白盒与黑盒一致性测试：
```bash
moon test
```

### 运行命令行工具
```bash
# 运行协议栈闭环验证与综合演示 CLI
moon run cmd/main

# 运行官方 XML -> MoonBit 自举代码生成器 CLI
moon run cmd/codegen
```

### 运行独立工程示例
```bash
# 示例 1: PX4 四旋翼无人机多帧 SHA-256 签名遥测流与串口抗噪解析仿真
moon run examples/px4_telemetry

# 示例 2: QGroundControl 地面站与无人机双向航点上传任务协议 (Mission Protocol) 状态机
moon run examples/gcs_mission_protocol

# 示例 3: 自定义农业植保机载荷 XML 方言实时解析、重排与 MoonBit 代码生成
moon run examples/xml_codegen_custom
```

### 运行 Web 交互工作台
直接使用浏览器打开前端界面：
```text
web/index.html
```
支持对预设飞控标准帧进行逐字节染色剖析（STX / Header / Payload / CRC / SHA-256 Signature），并可在线编辑任意 `<mavlink>` XML 实时生成对应的 MoonBit 编解码代码。

### 代码调用示例
```moonbit
// 1. 构造 PX4 四旋翼 HEARTBEAT 消息并启用 SHA-256 帧签名
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

// 2. 接收端流式解析与还原强类型消息
let parser = @mavlink.FrameParser::new()
let frames = parser.push_bytes(wire_bytes, @mavlink.lookup_message_crc_extra)
let decoded_msg = @mavlink.MavMessage::decode_from_frame(frames[0]).unwrap()
```

---

## 内置标准方言消息表 (20 Messages & 11 Enums)

[`standard_dialect.mbt`](standard_dialect.mbt) 由 [`cmd/codegen`](cmd/codegen/main.mbt) 从 [`xml_catalog.mbt`](xml_catalog.mbt) 自动生成，内置以下 20 条 PX4 / ArduPilot 标准飞控消息：

| 消息 ID | 消息名称 | MoonBit 结构体 | `CRC_EXTRA` | 基础/最大载荷 | 工程语义说明 |
| :---: | :--- | :--- | :---: | :---: | :--- |
| `0` | `HEARTBEAT` | `Heartbeat` | `50` | `9B / 9B` | 飞控/地面站 1Hz 存活心跳与飞行模式广播 |
| `1` | `SYS_STATUS` | `SysStatus` | `124` | `31B / 31B` | 机载传感器健康度、CPU 负载、电池电压与电流遥测 |
| `2` | `SYSTEM_TIME` | `SystemTime` | `137` | `12B / 12B` | 机载主时钟 UNIX 微秒时间戳与启动毫秒同步 |
| `4` | `PING` | `Ping` | `237` | `14B / 14B` | 飞控与地面站往返时延（RTT）链路探测 |
| `20` | `PARAM_REQUEST_READ` | `ParamRequestRead` | `214` | `20B / 20B` | 按参数名 `char[16]` 或索引请求读取机载参数 |
| `22` | `PARAM_VALUE` | `ParamValue` | `220` | `25B / 25B` | 飞控参数当前浮点值与总参数数量回传 |
| `23` | `PARAM_SET` | `ParamSet` | `168` | `23B / 23B` | 在线修改飞控参数并持久化写入机载存储 |
| `24` | `GPS_RAW_INT` | `GpsRawInt` | `24` | `30B / 52B` | RTK/GPS 原始定位与 v2 `<extensions/>` 精度指标 |
| `30` | `ATTITUDE` | `Attitude` | `39` | `28B / 28B` | 欧拉角（Roll/Pitch/Yaw）与三轴角速度高频遥测 |
| `32` | `LOCAL_POSITION_NED` | `LocalPositionNed` | `185` | `28B / 28B` | 局部北东地（NED）坐标系位置与速度估计 |
| `33` | `GLOBAL_POSITION_INT` | `GlobalPositionInt` | `104` | `28B / 28B` | 融合后全球经纬度（`degE7`）、相对高度与地速 |
| `35` | `RC_CHANNELS_RAW` | `RcChannelsRaw` | `244` | `22B / 22B` | 遥控器 8 通道原始 PWM 脉宽与 RSSI 信号强度 |
| `44` | `MISSION_COUNT` | `MissionCount` | `221` | `4B / 9B` | 航点上传/下载事务发起（声明总航点数量） |
| `47` | `MISSION_ACK` | `MissionAck` | `153` | `3B / 8B` | 航点任务事务完成确认（`MAV_MISSION_RESULT`） |
| `51` | `MISSION_REQUEST_INT` | `MissionRequestInt` | `196` | `4B / 5B` | 飞控向地面站按序号请求指定航点数据 |
| `73` | `MISSION_ITEM_INT` | `MissionItemInt` | `38` | `37B / 38B` | 整型高精度航点指令（避免单精度浮点经纬度精度损失） |
| `76` | `COMMAND_LONG` | `CommandLong` | `152` | `33B / 33B` | 解锁/上锁、起飞、返航等 7 参数通用控制指令 |
| `77` | `COMMAND_ACK` | `CommandAck` | `143` | `3B / 10B` | 飞控指令执行结果回执（含进度与目标组件扩展） |
| `253` | `STATUSTEXT` | `Statustext` | `83` | `51B / 54B` | 飞控控制台文本日志通知（含分片 ID 扩展） |
| `268` | `LOGGING_ACK` | `LoggingAck` | `14` | `4B / 4B` | 24-bit 扩展消息 ID 机载日志确认帧 |

---

## 协议验证与测试基准

本项目建立 40 项对齐官方 MAVLink v2 规范与 NIST 密码学标准的自动化测试套件（[`mavlink_wbtest.mbt`](mavlink_wbtest.mbt) 与 [`mavlink_test.mbt`](mavlink_test.mbt)）：

| 编号 | 测试模块 | 验证基准与技术点 | 实测验证结果 | 判定 |
| :---: | :--- | :--- | :---: | :---: |
| **1** | **ITU-T X.25 CRC 累加器** | 标准 ASCII 向量 `"123456789"` 校验值与增量累积一致性 | 精确等于 `0x906E` | PASS |
| **2** | **`CRC_EXTRA` 动态推导** | 对照官方 C 库核验 `HEARTBEAT`、`SYS_STATUS`、`GPS_RAW_INT`、`ATTITUDE` 等种子值 | 20 条消息 100% 吻合 | PASS |
| **3** | **小端序载荷与零字节压缩** | 全标量类型极值、`char[16]`/`char[50]` 截断补零、v2 尾部连续 `0x00` 剥离与扩展 | 双向无损闭环 | PASS |
| **4** | **FIPS 180-4 SHA-256 引擎** | 空串、`abc` 与 56 字节跨块消息标准摘要向量 | 32 字节摘要 100% 吻合 | PASS |
| **5** | **13B 帧安全签名与防重放** | 32B 密钥签名验证、篡改密钥/载荷拦截、48-bit 时间戳回退/重放拒绝 | 异常拦截率 100% | PASS |
| **6** | **v1/v2 帧编解码与异常分支** | 24-bit 扩展 ID (`#268`)、v1 ID 溢出拒绝、非法 STX、半包截断、CRC 篡改检测 | 覆盖全部 `MavError` 分支 | PASS |
| **7** | **流式状态机 (`FrameParser`)** | 前导串口乱码跳过、单字节逐粒推入、损坏帧滑动重同步、`seq` 跳变丢包计数 | 帧恢复与丢包统计精确 | PASS |
| **8** | **XML 解析与自举代码生成** | 字段按宽度降序重排、`<extensions/>` 偏移计算、保留字转义、非法 Schema 拒绝 | 自举编译 `0 warnings` | PASS |

---

## 架构与目录结构

```text
mavlink/
├── moon.mod                            # MoonBit 模块配置清单 (lycvvt/mavlink v0.1.0)
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
├── xml.mbt                             # 官方 <mavlink> XML 解析器与字段按宽度重排引擎
├── codegen.mbt                         # 自举式 MoonBit 强类型编解码代码生成器
├── xml_catalog.mbt                     # 官方 minimal.xml + common.xml 核心 XML 定义
├── standard_dialect.mbt                # 由代码生成器自举产出的 11 个枚举与 20 条消息实现
├── mavlink_wbtest.mbt                  # 35 项白盒单元测试
├── mavlink_test.mbt                    # 5 项黑盒集成测试
├── cmd/
│   ├── main/                           # 协议栈闭环验证与综合演示 CLI
│   └── codegen/                        # 官方 XML -> MoonBit 命令行代码生成器
├── examples/
│   ├── px4_telemetry/                  # 示例 1: PX4 四旋翼签名遥测流与串口抗噪解析
│   ├── gcs_mission_protocol/           # 示例 2: 地面站与飞控双向航点上传状态机
│   └── xml_codegen_custom/             # 示例 3: 自定义植保机 XML 方言实时代码生成
├── web/
│   └── index.html                      # 纯前端 MAVLink v2 帧剖析与 XML 代码生成工作台
└── docs/
    ├── dedup.md                        # Mooncakes.io 与 GitHub 生态查重报告
    ├── plan.md                         # 架构设计与协议数学规范（X.25 / 字段重排 / SHA-256）
    ├── decisions.md                    # 关键工程设计决策记录 (ADR-001 ~ ADR-004)
    └── ACCEPTANCE.md                   # 工程验收与自检核验报告
```

---

## 适用范围与非目标

为保证核心协议栈的高可移植性与零外部依赖特性，本项目明确界定功能边界：
- **目标范围**：MAVLink v1/v2 二进制线序帧封装与解析、X.25 CRC 与 `CRC_EXTRA` 校验、FIPS 180-4 SHA-256 帧签名、流式分片抗噪状态机、官方 `<mavlink>` XML Schema 解析及 MoonBit 强类型编解码代码自动生成。
- **非目标（Non-Goals）**：不包含操作系统级硬件串口驱动（UART/USB）、UDP/TCP 网络套接字 I/O 绑定或真实飞控电机混控律（Mixer）。底层字节流传输由宿主环境通过 `Bytes` / `Array[Byte]` 与本库交互。

---

## 协议规范与参考来源

本项目协议算法与标准消息定义严格对照以下官方规范与参考实现验证：
1. [MAVLink Developer Guide — Serialization & Packet Framing](https://mavlink.io/en/guide/serialization.html)（字段重排、尾部零截断与 `CRC_EXTRA` 规范）。
2. [MAVLink Developer Guide — Message Signing](https://mavlink.io/en/guide/message_signing.html)（SHA-256 13 字节帧签名与 48-bit 时间戳防重放规范）。
3. [mavlink/mavlink](https://github.com/mavlink/mavlink) — 官方 XML 消息定义仓库（`minimal.xml`、`common.xml`）。
4. 详尽协议数学推导与架构设计参见 [docs/plan.md](docs/plan.md) 与 [docs/decisions.md](docs/decisions.md)。

---

## 许可证

本项目基于 [Apache-2.0 License](LICENSE) 开源，第三方协议规范说明参见 [NOTICE](NOTICE)。
