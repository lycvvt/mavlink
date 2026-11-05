# 关键工程设计决策记录 (`docs/decisions.md`)

本文档记录 `lycvvt/mavlink` 在研发过程中做出的核心工程权衡与架构决策。

---

## ADR-001：100% 纯 MoonBit 实现（零 FFI 依赖，跨平台全目标兼容）

- **背景**：MAVLink v2 帧签名依赖 SHA-256 哈希算法，而 XML 消息定义解析通常依赖宿主系统的 XML 库。
- **决策**：在项目内部以 100% 纯 MoonBit 实现符合 FIPS 180-4 标准的 `sha256_digest`（[`signing.mbt`](../signing.mbt)）以及专为官方 `<mavlink>` Schema 定制的递归下降 XML 解析器（[`xml.mbt`](../xml.mbt)），不引入任何 C/JS FFI。
- **收益**：
  1. 产物可无差别编译至 `wasm-gc`、`wasm`、`js` 与 `native` 后端；
  2. 可直接部署于无操作系统的嵌入式微控制器（MCU）伴侣环境或浏览器端 WebAssembly 地面站。

---

## ADR-002：自举式（Self-Hosted）XML 代码生成架构

- **背景**：如果用 Python 或外部脚本生成 MoonBit 代码，会导致工具链割裂且无法在 MoonBit 运行时动态验证第三方自定义方言（Custom Dialect）。
- **决策**：用 MoonBit 直接编写 XML 解析器（`parse_dialect_xml`）与代码生成器（`generate_moonbit_code`），并将项目自身的标准方言库 [`standard_dialect.mbt`](../standard_dialect.mbt) 交由 [`cmd/codegen/main.mbt`](../cmd/codegen/main.mbt) 从 [`xml_catalog.mbt`](../xml_catalog.mbt) 自动生成。
- **收益**：
  1. **自举验证**：单元测试 [`mavlink_test.mbt`](../mavlink_test.mbt) 在运行期实时重跑 `generate_moonbit_from_xml(official_standard_xml)` 并校验生成的 11 个枚举与 20 条核心消息 Schema；
  2. **保留字与命名冲突自动消解**：例如官方 `HEARTBEAT` 消息中的字段名 `type` 是 MoonBit 关键字，代码生成器在生成结构体字段时自动重命名为 `mav_type`，同时在计算 `CRC_EXTRA` 时严格保留原始 XML 字段名 `"type"`，确保与 C/PX4 字节流 100% 互通；同理将枚举 `MAV_FRAME` 自动映射为 `MavCoordFrame` 以避免与传输帧结构体 `MavFrame` 发生标识符冲突。

---

## ADR-003：适配 MoonBit `0.1.20261028` 零告警规范（`pub extend` 与 `@debug.Debug`）

- **背景**：最新 MoonBit 编译器 `moonc v0.10.18` 弃用了 `derive(Show)`，并针对 `pub(all)` 类型的隐式方法解析新增了 Warning `[0079]` (`implicit_impl_as_method`)。
- **决策**：
  1. 所有公开结构体与枚举统一使用 `derive(Eq, Debug)`；
  2. 手写模块与代码生成器输出的每个 `pub(all)` 类型均显式附带：
     ```moonbit
     pub extend TypeName with Eq::{not_equal, equal}
     pub extend TypeName with @debug.Debug::{to_repr}
     ```
- **收益**：整个工程（含自动生成的 1000+ 行方言代码、CLI 与 3 个独立示例包）在 `moon check`、`moon test`、`moon build --target wasm-gc` 下均实现 **0 warnings, 0 errors**。

---

## ADR-004：面向真实串口/UDP 噪声环境的流式状态机 (`FrameParser`)

- **背景**：真实无人机数传链路（SiK Radio / ELRS / UART / UDP）经常出现半包截断、前导乱码字节或丢包。
- **决策**：在单帧无状态 `decode_frame` 之上，设计带内部缓冲区与序列号追踪器的 [`FrameParser`](../frame.mbt)：
  - 自动跳过非 `0xFD`/`0xFE` 的串口噪声字节；
  - 当帧头或载荷遭受校验失败时，仅前移 1 字节重新搜索同步字（Sliding Resync），防止假同步字吞噬后续合法帧；
  - 自动比对相邻合法帧的 `seq` 字段（模 256），精确统计无线链路丢包数 `dropped_packets`。
