# 2026 MoonBit 开源生态编程大赛 — 初审与验收自检报告 (`docs/ACCEPTANCE.md`)

> **项目名称**：`mavlink` — 纯 MoonBit 实现的 MAVLink v2/v1 无人机通信协议栈与官方 XML 自动代码生成器  
> **GitHub 仓库**：[https://github.com/lycvvt/mavlink](https://github.com/lycvvt/mavlink)  
> **参赛者账号**：[`lycvvt`](https://github.com/lycvvt)  
> **自检日期**：2026 年 11 月 5 日  
> **工具链版本**：`moon 0.1.20261028 (e1e1f15 2026-10-28)` / `moonc v0.10.18+6c83a7f62`

---

## 1. 赛事初审硬性指标逐项核对

| 审查维度 | 官方章程要求 | 本项目实际完成指标 | 状态 |
| :--- | :--- | :--- | :---: |
| **选题查重** | 不与 Mooncakes.io 或已有开源项目重复 | `moon search mavlink` / `px4` / `ardupilot` 均为 `No modules found.`（详见 [`docs/dedup.md`](dedup.md)） | PASS |
| **主要实现语言** | MoonBit 为主要实现语言，构建真实可用功能 | 核心协议栈、SHA-256 签名、XML 解析与代码生成 100% 纯 MoonBit 实现（0 FFI） | PASS |
| **编译与静态检查** | 必须在当前最新工具链下编译通过 | `moon check` 与 `moon build --target wasm-gc` 均为 **`0 warnings, 0 errors`** | PASS |
| **单元测试与边界验证** | 具备充分的正确性与错误处理测试 | 共 **40 项自动化测试**（35 项白盒 + 5 项黑盒），覆盖 20 条消息、CRC 篡改、签名重放、XML 异常 | PASS |
| **可运行示例与 CLI** | 提供可直接运行的示例程序 | 提供 `cmd/main`、`cmd/codegen` 及 3 个独立场景示例（`examples/px4_telemetry`、`examples/gcs_mission_protocol`、`examples/xml_codegen_custom`） | PASS |
| **交互式演示工作台** | 直观展示核心功能与可视化结果 | 提供 [`web/index.html`](../web/index.html) 零依赖交互式 MAVLink v2 帧结构剖析器与 XML 代码生成工作台 | PASS |
| **开源许可与合规声明** | OSI 认可开源协议 + 第三方来源说明 | 根目录包含 [`LICENSE`](../LICENSE) (`Apache-2.0`) 与 [`NOTICE`](../NOTICE)（声明官方 MAVLink XML Schema CC0/MIT 来源） | PASS |
| **开发历史与 Issues** | 真实、可追踪的 Git 历史与项目管理 | 14+ 条语义化原子提交（`feat:` / `test:` / `docs:` / `ci:`）+ GitHub Issues 里程碑追踪 | PASS |

---

## 2. 核心功能与技术亮点清单

1. **完整的 MAVLink v2 (`0xFD`) 与 v1 (`0xFE`) 双协议帧编解码（[`frame.mbt`](../frame.mbt)）**
   - 支持 24-bit 扩展消息 ID（如 `LOGGING_ACK #268`）、`incompat_flags` / `compat_flags` 标志位解析；
   - 实现 `FrameParser` 流式状态机，支持串口/UDP 噪声字节跳过、分片重组（Chunked Reassembly）、滑动重同步以及基于 `seq` 的无线链路丢包统计（`dropped_packets`）。
2. **动态 `CRC_EXTRA` 计算与 ITU-T X.25 校验（[`crc.mbt`](../crc.mbt)）**
   - 精确实现 `CRC-16/MCRF4XX` 累加器；
   - 根据 XML 消息定义动态对基础字段按元素字节宽度降序重排，自动计算 `CRC_EXTRA` 并与官方 C/PX4 标准种子值（`HEARTBEAT=50`、`SYS_STATUS=124`、`GPS_RAW_INT=24`、`ATTITUDE=39`、`MISSION_ITEM_INT=38`、`COMMAND_LONG=152`、`STATUSTEXT=83`）100% 吻合。
3. **小端序载荷序列化与 MAVLink v2 尾部零字节截断/零扩展（[`payload.mbt`](../payload.mbt)）**
   - 支持 `uint8_t` ~ `uint64_t`、`int8_t` ~ `int64_t`、`float`、`double`、定长字符串 `char[N]` 及定长数值数组 `T[N]`；
   - 自动剥离 v2 载荷尾部连续 `0x00` 字节以节省无线数传带宽，并在解码时透明补零以兼容 `<extensions/>` 字段。
4. **纯 MoonBit FIPS 180-4 SHA-256 引擎与 13 字节帧安全签名（[`signing.mbt`](../signing.mbt)）**
   - 零外部依赖实现 SHA-256，支持 `link_id + 48-bit timestamp + 6-byte sha256_tag` 帧签名生成与校验；
   - 内置严格单调递增时间戳检查，防御无人机控制指令重放攻击（Replay Attack）。
5. **自举式官方 XML 消息定义解析与 MoonBit 代码生成器（[`xml.mbt`](../xml.mbt) & [`codegen.mbt`](../codegen.mbt)）**
   - 直接读取官方 `<mavlink>` XML，自动处理 `<extensions/>` 边界、保留字重命名（`type` $\rightarrow$ `mav_type`）与类型防冲突（`MAV_FRAME` $\rightarrow$ `MavCoordFrame`）；
   - 自举生成 [`standard_dialect.mbt`](../standard_dialect.mbt)，内置 **11 个标准枚举与 20 条核心飞控消息**。

---

## 3. 一键复现与验收命令汇总

评审专家可在仓库根目录下依次执行以下命令完成全量验证：

```bash
# 1. 格式与静态类型检查（0 warnings, 0 errors）
moon fmt --check
moon check

# 2. 运行全部 40 项白盒与黑盒自动化测试
moon test

# 3. 编译 Wasm-GC 目标产物
moon build --target wasm-gc

# 4. 运行主验证套件与自举代码生成器 CLI
moon run cmd/main
moon run cmd/codegen

# 5. 运行 3 个独立工程示例
moon run examples/px4_telemetry
moon run examples/gcs_mission_protocol
moon run examples/xml_codegen_custom
```
