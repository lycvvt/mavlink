# 2026 MoonBit 黑客松（11月赛）一页项目说明

## 1. 基本信息
- **项目名称**：`lycvvt/mavlink` — MoonBit MAVLink v2 协议库与官方 XML 消息代码生成器
- **参赛方向**：工具库（通用工具库、协议库与可复用的基础组件）
- **参赛者 GitHub ID**：[`lycvvt`](https://github.com/lycvvt)
- **公开代码仓库**：`https://github.com/lycvvt/mavlink`
- **开源许可证**：Apache-2.0（含 `LICENSE` 与 `NOTICE` 第三方来源说明）
- **工具链版本**：`moon 0.1.20261028` / `moonc v0.10.18+6c83a7f62`

## 2. 项目背景与解决的真实问题
MAVLink（Micro Air Vehicle Link）是无人机飞控（PX4、ArduPilot）、具身智能机器人与地面控制站（QGroundControl、MAVSDK）之间事实标准的二进制通信协议。此前 MoonBit 生态中 `mavlink`、`px4`、`ardupilot` 相关实现均为 0。

由于 MAVLink 官方消息定义（XML）会持续演进，且底层协议涉及复杂的**字段按类型字节宽度降序重排（Wire Field Reordering）**、**X.25 CRC-16/MCRF4XX 与 `CRC_EXTRA` 种子计算**、**MAVLink v2 尾部零字节截断（Zero-Trimming）**、**`<extensions/>` 扩展字段兼容**以及 **SHA-256 帧签名**，手写编解码极易出错且难以维护。本项目在 MoonBit 中一次性解决“底层二进制帧协议 + 官方 XML 自动生成强类型 MoonBit 编解码代码”的完整闭环。

## 3. 核心工程边界与已完成功能
1. **X.25 CRC-16/MCRF4XX 与 `CRC_EXTRA` 计算器 (`crc.mbt`)**：严格按官方规范对非扩展字段按 8/4/2/1 字节宽度稳定重排并注入定长数组长度，动态算出 `CRC_EXTRA` 字节。
2. **小端序二进制载荷与 v2 尾部零截断/扩展 (`payload.mbt`)**：支持 `u8/i8/u16/i16/u32/i32/u64/i64/f32/f64`、`char[N]` 及数值数组 `T[N]`；编码时自动执行 v2 尾部零截断（全零至少保留 1 字节），解码时自动零扩展还原截断字段与 `<extensions/>` 扩展字段。
3. **FIPS 180-4 SHA-256 与 MAVLink v2 数据包签名 (`signing.mbt`)**：支持 13 字节签名尾生成、验签与 48-bit 单调递增时间戳防重放保护。
4. **MAVLink v1/v2 帧编解码与流式解析状态机 (`frame.mbt`)**：支持 24-bit 消息 ID、粘包/分片半包重组、串口前导噪声跳过与序列号丢包统计。
5. **官方 XML 解析器与 MoonBit 代码自动生成器 (`xml.mbt`, `codegen.mbt`, `standard_dialect.mbt`)**：读取官方 `<mavlink>` XML 自动生成枚举、消息结构体与编解码代码，并自举生成内置的标准无人机消息集。

## 4. 验收与一键复现指南
```bash
git clone https://github.com/lycvvt/mavlink.git
cd mavlink
moon check
moon test
moon run cmd/main
```
