# lycvvt/mavlink — MoonBit MAVLink v2 Protocol & XML Code Generator

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![Language](https://img.shields.io/badge/Language-MoonBit-purple.svg)](https://www.moonbitlang.com)

`lycvvt/mavlink` 是面向无人机（PX4、ArduPilot）、机器人与地面站（QGroundControl、MAVSDK）通信的纯 **MoonBit** 原生 **MAVLink v2 / v1 协议栈与官方 XML 消息定义自动代码生成器**。

本项目读取官方 MAVLink XML 消息定义文件（`<mavlink>` Schema），自动完成字段按类型宽度降序重排（Wire Field Reordering）、`CRC_EXTRA` 种子计算、`<extensions/>` 扩展字段布局分析，并自动生成零警告、强类型的 MoonBit 编解码代码。

---

## 核心特性

1. **完整的 MAVLink v2 / v1 帧协议层 (`frame.mbt`, `types.mbt`)**
   - 支持 MAVLink v2 (`STX = 0xFD`, 24-bit 消息 ID, `incompat_flags` / `compat_flags`) 与 MAVLink v1 (`STX = 0xFE`, 8-bit 消息 ID) 双向编解码。
   - 内置面向真实串口（UART）/ UDP 数据流的增量式状态机解析器 `FrameParser`，支持前导噪声字节跳过、分片半包组装、多帧粘包提取，以及基于序列号 (`seq`) 的丢包统计与 CRC 错误计数。

2. **标准 X.25 CRC-16/MCRF4XX 与动态 `CRC_EXTRA` 计算 (`crc.mbt`)**
   - 严格实现 ITU-T X.25 (`CRC-16/MCRF4XX`, 初值 `0xFFFF`) 校验算法。
   - 完整实现官方 `compute_crc_extra` 规范：对非扩展基础字段按元素字节宽度（8 → 4 → 2 → 1 字节）稳定降序重排、归一化 `uint8_t_mavlink_version`、注入定长数组长度字节并折叠计算 1 字节种子。已通过 `HEARTBEAT` (`50`)、`SYS_STATUS` (`124`)、`GPS_RAW_INT` (`24`)、`ATTITUDE` (`39`)、`GLOBAL_POSITION_INT` (`104`)、`COMMAND_LONG` (`152`)、`COMMAND_ACK` (`143`)、`STATUSTEXT` (`83`) 等官方标准向量验证。

3. **MAVLink v2 尾部零字节截断与扩展字段兼容 (`payload.mbt`)**
   - **尾部零截断（Zero-Trimming）**：序列化 MAVLink v2 载荷时自动剥离尾部连续的 `0x00` 字节（全零载荷严格保留首字节，最小长度为 1）。
   - **零扩展（Zero-Extension）**：反序列化截断载荷或旧版 v1 帧时，自动将缺失的尾部字节与 `<extensions/>` 扩展字段零扩展还原，天然实现跨版本前后向兼容。

4. **MAVLink v2 数据包数字签名与防重放保护 (`signing.mbt`)**
   - 纯 MoonBit 原生实现 FIPS 180-4 **SHA-256** 摘要算法与 MAVLink v2 13 字节签名尾（`link_id[1] + timestamp[6] + signature[6]`）。
   - 支持 48-bit 单调递增时间戳（单位 $10\,\mu\text{s}$）防重放攻击校验 (`SigningContext`)。

5. **官方 XML 消息定义解析与 MoonBit 代码生成 (`xml.mbt`, `codegen.mbt`, `standard_dialect.mbt`)**
   - 解析官方 `<mavlink>` XML 中的 `<enums>`（含 `bitmask="true"` 与十六进制/十进制枚举值）和 `<messages>`（含 `<field>`、定长字符数组 `char[N]`、定长数值数组 `T[N]` 与 `<extensions/>` 标记）。
   - 自动处理 MoonBit 保留字转义（如 `type` → `mav_type`），生成强类型结构体、枚举、`encode_payload` / `decode_payload` 与顶层 `MavMessage` 路由器。
   - 库内置的 `standard_dialect.mbt` 即由本项目的代码生成器从 `official_standard_xml` 直接自举生成。

---

## 项目结构

| 文件 / 目录 | 职责说明 |
| :--- | :--- |
| [`moon.mod`](./moon.mod) | MoonBit 模块元数据配置 (`lycvvt/mavlink`) |
| [`types.mbt`](./types.mbt) | 协议常量、帧头 `MavHeader`、完整帧 `MavFrame`、签名 `MavSignature` 与错误类型 `MavError` |
| [`crc.mbt`](./crc.mbt) | X.25 CRC-16/MCRF4XX 累加器与官方 `CRC_EXTRA` 动态计算引擎 |
| [`payload.mbt`](./payload.mbt) | 小端序二进制读写器 (`PayloadWriter` / `PayloadReader`)、v2 尾部零截断与零扩展 |
| [`signing.mbt`](./signing.mbt) | FIPS 180-4 SHA-256 实现与 MAVLink v2 数据包签名/验签上下文 `SigningContext` |
| [`frame.mbt`](./frame.mbt) | MAVLink v1/v2 帧编解码与流式容错状态机解析器 `FrameParser` |
| [`xml.mbt`](./xml.mbt) | 官方 MAVLink XML 消息定义解析器、字段重排与内存布局计算器 |
| [`codegen.mbt`](./codegen.mbt) | 从 `DialectSchema` 或 XML 字符串自动生成 MoonBit 编解码源码 |
| [`xml_catalog.mbt`](./xml_catalog.mbt) | 内置官方标准消息集 XML 定义 (`minimal.xml` + `common.xml` 核心无人机消息) |
| [`standard_dialect.mbt`](./standard_dialect.mbt) | 由本库代码生成器自动生成的强类型无人机标准消息与枚举编解码实现 |
| [`cmd/main/main.mbt`](./cmd/main/main.mbt) | 可运行综合演示：官方 XML 代码生成报告 + PX4 无人机与地面站双向签名通信仿真 |
| [`mavlink_wbtest.mbt`](./mavlink_wbtest.mbt) | 协议内核白盒测试（CRC、重排、v2 零截断、扩展字段、签名防重放、流式分包、自定义 XML 生成） |
| [`mavlink_test.mbt`](./mavlink_test.mbt) | 公开 API 黑盒测试与 XML Schema 异常边界验证 |

---

## 快速开始与复现验证

### 1. 环境要求
- MoonBit 工具链：`moon 0.1.20261028` (`moonc v0.10.18` 或更高版本)

### 2. 编译检查与运行单元测试
```bash
moon check
moon test
```
预期输出：
```text
Total tests: 9, passed: 9, failed: 0.
```

### 3. 运行无人机 <-> 地面站闭环仿真与代码生成演示
```bash
moon run cmd/main
```
运行输出示例：
```text
======================================================================
  MoonBit MAVLink v2 Protocol & XML Codegen Demo (lycvvt/mavlink)
======================================================================

[1] Official MAVLink XML Schema Parsed & Code Generated Successfully:
    - Protocol Version : 3, Dialect: 0
    - Enums Parsed     : 8, Messages Parsed: 12
    - Generated Code   : 39366 characters of strongly-typed MoonBit

    ID   | Message Name         | BaseLen | MaxLen | CRC_EXTRA | First Wire Field
    -----+----------------------+---------+--------+-----------+--------------------
    #0 | HEARTBEAT | 9B | 9B | 50 | custom_mode (uint32_t)
    #1 | SYS_STATUS | 31B | 31B | 124 | onboard_control_sensors_present (uint32_t)
    #4 | PING | 14B | 14B | 237 | time_usec (uint64_t)
    #20 | PARAM_REQUEST_READ | 20B | 20B | 214 | param_index (int16_t)
    #22 | PARAM_VALUE | 25B | 25B | 220 | param_value (float)
    #24 | GPS_RAW_INT | 30B | 52B | 24 | time_usec (uint64_t)
    #30 | ATTITUDE | 28B | 28B | 39 | time_boot_ms (uint32_t)
    #33 | GLOBAL_POSITION_INT | 28B | 28B | 104 | time_boot_ms (uint32_t)
    #76 | COMMAND_LONG | 33B | 33B | 152 | param1 (float)
    #77 | COMMAND_ACK | 3B | 10B | 143 | command (uint16_t)
    #253 | STATUSTEXT | 51B | 54B | 83 | severity (uint8_t)
    #268 | LOGGING_ACK | 4B | 4B | 14 | sequence (uint16_t)
```

---

## 代码使用示例

### 1. 编码与解码带签名的 MAVLink v2 消息
```moonbit
let secret_key = b"0123456789abcdef0123456789abcdef"
let Ok(signer) = @mavlink.SigningContext::new(secret_key, link_id=b'\x01', initial_timestamp=1000UL)
let Ok(verifier) = @mavlink.SigningContext::new(secret_key, link_id=b'\x01', initial_timestamp=1000UL)

let hb : @mavlink.Heartbeat = {
  mav_type: @mavlink.MavType::Quadrotor.to_uint().to_byte(),
  autopilot: @mavlink.MavAutopilot::Px4.to_uint().to_byte(),
  base_mode: @mavlink.MavModeFlag::SafetyArmed.to_uint().to_byte(),
  custom_mode: 0x04010000U,
  system_status: @mavlink.MavState::Active.to_uint().to_byte(),
  mavlink_version: b'\x03',
}

// 编码为带 13 字节 SHA-256 签名的 MAVLink v2 帧
let Ok((wire_bytes, _)) = @mavlink.MavMessage::MsgHeartbeat(hb).encode_to_frame(
  seq=b'\x01',
  sysid=b'\x01',
  compid=b'\x01',
  signing=Some(signer),
)

// 接收端验签并解码
let Ok((frame, _)) = @mavlink.decode_frame(
  wire_bytes,
  @mavlink.lookup_message_crc_extra,
  signing=Some(verifier),
)
let Ok(decoded_msg) = @mavlink.MavMessage::decode_from_frame(frame)
```

### 2. 从官方或自定义 XML 消息定义自动生成 MoonBit 编解码代码
```moonbit
let xml_def =
  #|<?xml version="1.0"?>
  #|<mavlink>
  #|  <version>3</version>
  #|  <messages>
  #|    <message id="1200" name="ESC_TELEMETRY_QUAD">
  #|      <field type="uint8_t" name="state"/>
  #|      <field type="uint16_t[4]" name="rpm"/>
  #|      <field type="uint32_t" name="timestamp_ms"/>
  #|    </message>
  #|  </messages>
  #|</mavlink>

let Ok((schema, moonbit_code)) = @mavlink.generate_moonbit_from_xml(xml_def)
```

---

## 开源许可证与来源说明

- **本项目许可证**：采用 OSI 认可的 **Apache License 2.0** 开源许可证，详见 [`LICENSE`](./LICENSE)。
- **协议规范与第三方说明**：本项目为 MoonBit 原生实现（Clean-room implementation），遵循官方 [MAVLink Serialization & Packet Signing Specification](https://mavlink.io/en/guide/serialization.html)；内置标准 XML 消息定义源自官方 [`mavlink/mavlink`](https://github.com/mavlink/mavlink) 仓库（MIT License）。完整来源与第三方许可说明详见 [`NOTICE`](./NOTICE)。
