# `lycvvt/mavlink` — Pure MoonBit MAVLink v2 Protocol & Official XML Code Generator

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261028-f59e0b.svg)](https://www.moonbitlang.com)
[![Tests](https://img.shields.io/badge/Tests-40%20passed-10b981.svg)](mavlink_wbtest.mbt)
[![Warnings](https://img.shields.io/badge/Warnings-0-10b981.svg)](moon.mod)

**`lycvvt/mavlink`** 是一个面向 **无人机（PX4 / ArduPilot）、机器人与地面控制站（QGroundControl / MissionPlanner）** 通信的 **100% 纯 MoonBit 实现（零 FFI 依赖）** 的 **MAVLink v2 / v1 协议栈与官方 XML 自动代码生成器**。

本项目能够直接读取官方 `<mavlink>` XML 消息定义文件（如 `minimal.xml`、`common.xml` 及自定义机载方言），自动完成**字段按类型字节宽度降序重排（Wire Field Reordering）**、**ITU-T X.25 `CRC_EXTRA` 动态种子计算**，并自动生成零警告、强类型的 MoonBit 编解码代码。

---

## ✨ 核心特性 (Key Features)

1. **官方 XML 消息定义解析与自动代码生成（[`xml.mbt`](xml.mbt) & [`codegen.mbt`](codegen.mbt)）**
   - 原生解析 `<mavlink>` XML Schema 中的 `<enums>`、`<messages>`、`<field>`、定长数组 `type[N]` 及 MAVLink v2 `<extensions/>` 扩展字段；
   - 严格实现 MAVLink 官方规范的**基础字段按标量字节宽度（8B → 4B → 2B → 1B）稳定降序重排**，扩展字段保持声明顺序追加在末尾；
   - **自举验证（Self-Hosted）**：仓库中的 [`standard_dialect.mbt`](standard_dialect.mbt) 完全由本项目的 [`cmd/codegen`](cmd/codegen/main.mbt) 从 [`xml_catalog.mbt`](xml_catalog.mbt) 自动生成，支持 **11 个标准枚举与 20 条核心飞控消息**。
2. **完整的 MAVLink v2 (`0xFD`) 与 v1 (`0xFE`) 双协议帧封装（[`frame.mbt`](frame.mbt)）**
   - 支持 MAVLink v2 10 字节帧头、24-bit 小端序扩展消息 ID（`0 .. 16,777,215`，如 `LOGGING_ACK #268`）及 `incompat_flags` / `compat_flags`；
   - 向后兼容 MAVLink v1 (`0xFE`) 6 字节帧头编解码；
   - 提供 **`FrameParser` 流式状态机**，支持串口/UDP 噪声字节跳过、半包分片重组（Chunked Reassembly）、校验失败滑动重同步与序列号丢包统计（`dropped_packets`）。
3. **动态 ITU-T X.25 `CRC-16/MCRF4XX` 与 `CRC_EXTRA` 引擎（[`crc.mbt`](crc.mbt)）**
   - 精确实现 `CRC-16/MCRF4XX`（多项式 `0x1021`，初始值 `0xFFFF`）；
   - 动态从 XML 消息结构计算 `CRC_EXTRA` 并与官方 C/PX4/ArduPilot 标准值 100% 一致（例如 `HEARTBEAT=50`、`SYS_STATUS=124`、`GPS_RAW_INT=24`、`ATTITUDE=39`、`MISSION_ITEM_INT=38`、`COMMAND_LONG=152`、`STATUSTEXT=83`）。
4. **MAVLink v2 尾部零字节截断与透明零扩展（[`payload.mbt`](payload.mbt)）**
   - 发送端自动剥离 MAVLink v2 载荷尾部连续的 `0x00` 字节（Zero-Trimming），显著节省数传电台带宽；
   - 接收端解码自动补零（Zero-Extension），透明兼容被截断字段与新旧固件间的 `<extensions/>` 演进。
5. **纯 MoonBit FIPS 180-4 SHA-256 与 13 字节帧安全签名（[`signing.mbt`](signing.mbt)）**
   - 内置零依赖 SHA-256 实现，支持 MAVLink v2 13 字节签名块（`link_id` 1B + 48-bit `timestamp` 6B + `sha256_48` 6B）；
   - 强制校验 48-bit 时间戳严格单调递增，防御空中无线链路重放攻击（Replay Attack）。

---

## 📦 内置自举标准方言消息表 (20 Messages & 11 Enums)

| 消息 ID | 消息名称 | MoonBit 结构体 | `CRC_EXTRA` | 基础/最大载荷 | 典型飞控应用场景 |
| :---: | :--- | :--- | :---: | :---: | :--- |
| `0` | `HEARTBEAT` | `Heartbeat` | `50` | `9B / 9B` | 飞控/地面站 1Hz 存活心跳与飞行模式广播 |
| `1` | `SYS_STATUS` | `SysStatus` | `124` | `31B / 31B` | 传感器健康度、CPU 负载、电池电压与电流遥测 |
| `2` | `SYSTEM_TIME` | `SystemTime` | `137` | `12B / 12B` | 机载主时钟 UNIX 微秒时间戳与启动毫秒同步 |
| `4` | `PING` | `Ping` | `237` | `14B / 14B` | 飞控与地面站往返时延（RTT）探测 |
| `20` | `PARAM_REQUEST_READ` | `ParamRequestRead` | `214` | `20B / 20B` | 按参数名 `char[16]` 或索引读取飞控参数 |
| `22` | `PARAM_VALUE` | `ParamValue` | `220` | `25B / 25B` | 飞控参数当前值与总参数数量广播 |
| `23` | `PARAM_SET` | `ParamSet` | `168` | `23B / 23B` | 在线修改飞控 PID / 混控参数并写入闪存 |
| `24` | `GPS_RAW_INT` | `GpsRawInt` | `24` | `30B / 52B` | RTK/GPS 原始定位与 v2 `<extensions/>` 精度指标 |
| `30` | `ATTITUDE` | `Attitude` | `39` | `28B / 28B` | 欧拉角（Roll/Pitch/Yaw）与三轴角速度遥测 |
| `32` | `LOCAL_POSITION_NED` | `LocalPositionNed` | `185` | `28B / 28B` | 局部北东地（NED）坐标系位置与速度估计 |
| `33` | `GLOBAL_POSITION_INT` | `GlobalPositionInt` | `104` | `28B / 28B` | 融合后全球经纬度（`degE7`）、相对高度与地速 |
| `35` | `RC_CHANNELS_RAW` | `RcChannelsRaw` | `244` | `22B / 22B` | 遥控器 8 通道原始 PWM 脉宽与 RSSI 信号强度 |
| `44` | `MISSION_COUNT` | `MissionCount` | `221` | `4B / 9B` | 航点上传/下载事务发起（总航点数声明） |
| `47` | `MISSION_ACK` | `MissionAck` | `153` | `3B / 8B` | 航点任务事务完成确认（`MAV_MISSION_RESULT`） |
| `51` | `MISSION_REQUEST_INT` | `MissionRequestInt` | `196` | `4B / 5B` | 飞控向地面站按序号请求指定航点数据 |
| `73` | `MISSION_ITEM_INT` | `MissionItemInt` | `38` | `37B / 38B` | 整型高精度航点指令（避免 `float` 经纬度精度损失） |
| `76` | `COMMAND_LONG` | `CommandLong` | `152` | `33B / 33B` | 解锁/上锁、起飞、返航等 7 参数通用控制指令 |
| `77` | `COMMAND_ACK` | `CommandAck` | `143` | `3B / 10B` | 飞控指令执行结果回执（含进度与目标组件扩展） |
| `253` | `STATUSTEXT` | `Statustext` | `83` | `51B / 54B` | 飞控控制台文本日志通知（含分片 ID 扩展） |
| `268` | `LOGGING_ACK` | `LoggingAck` | `14` | `4B / 4B` | 24-bit 扩展消息 ID 机载日志确认帧 |

---

## 🗂️ 仓库目录结构 (Project Structure)

```text
mavlink/
├── moon.mod                            # MoonBit 模块定义 (lycvvt/mavlink v0.1.0)
├── moon.pkg                            # 根包配置
├── types.mbt                           # 协议版本、帧头、签名块、结构化错误类型 MavError
├── crc.mbt                             # ITU-T X.25 CRC-16/MCRF4XX 与动态 CRC_EXTRA 计算器
├── payload.mbt                         # 小端序读写器、char[N]、MAVLink v2 零字节截断与扩展
├── signing.mbt                         # 纯 MoonBit FIPS 180-4 SHA-256 与 13 字节帧安全签名
├── frame.mbt                           # v1/v2 帧编解码与串口抗噪流式状态机 FrameParser
├── xml.mbt                             # 官方 <mavlink> XML 解析器与字段按宽度重排引擎
├── codegen.mbt                         # 自举式 MoonBit 强类型编解码代码生成器
├── xml_catalog.mbt                     # 官方 minimal.xml + common.xml 核心 XML 定义
├── standard_dialect.mbt                # 由代码生成器自举生成的 11 个枚举与 20 条消息实现
├── mavlink_wbtest.mbt                  # 35 项白盒单元测试（CRC、重排、签名、流式分片、错误分支）
├── mavlink_test.mbt                    # 5 项黑盒集成测试（20 条消息闭环、自定义方言、非法 XML 拦截）
├── cmd/
│   ├── main/main.mbt                   # 综合协议栈验证与演示 CLI
│   └── codegen/main.mbt                # 官方 XML → MoonBit 命令行代码生成器
├── examples/
│   ├── px4_telemetry/main.mbt          # 示例 1：PX4 四旋翼签名遥测流与串口噪声解析仿真
│   ├── gcs_mission_protocol/main.mbt   # 示例 2：地面站与飞控双向航点上传任务协议状态机
│   └── xml_codegen_custom/main.mbt     # 示例 3：自定义农业植保机 XML 方言实时生成 MoonBit 代码
├── web/
│   └── index.html                      # 零依赖交互式 MAVLink v2 帧结构剖析器与在线代码生成工作台
├── docs/
│   ├── dedup.md                        # Mooncakes.io 与 GitHub 全网查重报告
│   ├── plan.md                         # 架构设计与协议数学规范（X.25 / 字段重排 / SHA-256）
│   ├── decisions.md                    # 关键工程设计决策记录 (ADR-001 ~ ADR-004)
│   └── ACCEPTANCE.md                   # 赛事初审与验收自检报告
├── LICENSE                             # Apache-2.0 开源许可证
└── NOTICE                              # 第三方知识来源与官方 MAVLink XML Schema 许可说明
```

---

## 🚀 快速开始与验证命令 (Quick Start)

```bash
# 1. 静态类型检查与格式检查（0 warnings, 0 errors）
moon fmt --check
moon check

# 2. 运行全部 40 项自动化测试
moon test

# 3. 编译 Wasm-GC 产物
moon build --target wasm-gc

# 4. 运行综合演示程序与自举代码生成器 CLI
moon run cmd/main
moon run cmd/codegen

# 5. 运行 3 个独立工程场景示例
moon run examples/px4_telemetry
moon run examples/gcs_mission_protocol
moon run examples/xml_codegen_custom
```

此外，可直接用浏览器打开 [`web/index.html`](web/index.html) 体验交互式 **MAVLink v2 帧字节流剖析器与在线 XML-to-MoonBit 代码生成工作台**。

---

## 📜 开源许可与致谢 (License & Notice)

- 本项目源代码采用 **Apache License 2.0** 开源（详见 [`LICENSE`](LICENSE)）。
- 协议规范与标准消息 Schema 源自官方 [MAVLink 协议规范](https://mavlink.io/en/) 及 [`mavlink/mavlink`](https://github.com/mavlink/mavlink) 仓库（详见 [`NOTICE`](NOTICE)）。
