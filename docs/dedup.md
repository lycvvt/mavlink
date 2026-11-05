# MAVLink v2 协议库与自动代码生成器 — 查重与生态调研报告

> **调研时间**：2026-11-05  
> **申报人 GitHub**：[`lycvvt`](https://github.com/lycvvt)  
> **目标仓库**：[`https://github.com/lycvvt/mavlink`](https://github.com/lycvvt/mavlink)  
> **本机工具链**：`moon 0.1.20261028 (e1e1f15 2026-10-28)` / `moonc v0.10.18+6c83a7f62`

---

## 1. 赛事官方规则与时间节点核对

在立项前，我们逐项核对了 [2026 MoonBit 开源生态编程大赛官网](https://moonbitlang.github.io/Hackathon2026/) 与 [正式赛事章程（飞书 Wiki）](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)：

| 维度 | 赛事官方要求 | 本项目落实情况 |
| :--- | :--- | :--- |
| **页面最后更新时间** | 2026 年 11 月 2 日 | 已核对最新规则 |
| **报名与初审提交** | 2026 年 11 月 1 日 — 11 月 15 日 24:00（UTC+8） | 正在窗口期内完成初审交付 |
| **初审修改规则** | 初审未通过可获 **1 次修改重提机会**（须在 72 小时内且不晚于 11 月 15 日 24:00） | 按一次性高标准通过初审准备 |
| **开发与最终验收截止** | 2026 年 12 月 20 日 24:00（UTC+8） | 已建立完整里程碑与 GitHub Issues 追踪 |
| **立项查重要求** | 严禁与 Mooncakes.io 或 GitHub 已有 MoonBit 仓库同质化 | 全网 `0` 撞车（见第 2 节原始检索记录） |
| **语言与开源许可** | MoonBit 为主要实现语言，采用 OSI 认可开源协议，标注第三方来源 | 100% 纯 MoonBit（零 FFI），`Apache-2.0` + `NOTICE` |

---

## 2. Mooncakes.io 官方包管理中心检索记录

使用本机 MoonBit 工具链对官方包索引库 `mooncakes.io` 进行多关键词交叉检索：

```text
PS D:\黎荣灿初审5> moon search mavlink
No modules found.

PS D:\黎荣灿初审5> moon search px4
No modules found.

PS D:\黎荣灿初审5> moon search ardupilot
No modules found.

PS D:\黎荣灿初审5> moon search drone
No modules found.

PS D:\黎荣灿初审5> moon search uav
No modules found.
```

**结论**：Mooncakes.io 官方注册中心目前在无人机通信协议（`mavlink`）、主流开源飞控协议栈（`px4`、`ardupilot`）及航空遥测（`drone`、`uav`）方向上**完全空白（0 个模块）**。

---

## 3. GitHub 全网 MoonBit 仓库检索记录

通过 GitHub CLI (`gh search repos` / `gh search code`) 对全网公开仓库进行检索：

```text
PS D:\黎荣灿初审5> gh search repos "mavlink moonbit"
No repositories matched your search

PS D:\黎荣灿初审5> gh search repos "mavlink language:MoonBit"
No repositories matched your search

PS D:\黎荣灿初审5> gh search repos "px4 moonbit"
No repositories matched your search

PS D:\黎荣灿初审5> gh search repos "ardupilot moonbit"
No repositories matched your search
```

---

## 4. 选题价值、可维护性与风险应对评估

1. **生态稀缺性与方向契合度**：
   - MAVLink（Micro Air Vehicle Link）是全球无人机（PX4、ArduPilot）、无人船、水下机器人与地面控制站（QGroundControl、MissionPlanner）事实上的工业标准通信协议。
   - MoonBit 具备紧凑内存布局、确定性执行和极小的 Wasm/Native/C 产物，天然契合**嵌入式飞控伴侣计算机（Companion Computer）**、**物联网边缘网关**与**Web 端地面站（Wasm GCS）**开发。
2. **长期可维护性（Schema 驱动代码生成）**：
   - MAVLink v1/v2 的底层帧封装、字段按类型字节宽度重排、ITU-T X.25 CRC-16/MCRF4XX (`CRC_EXTRA`)、尾部零字节截断以及 SHA-256 帧签名规范极其稳定。
   - 官方 `mavlink/mavlink` 仓库持续演进的是 XML 消息定义（如 `minimal.xml`、`common.xml`）。本项目实现了**原生 XML Schema 解析器与 MoonBit 代码生成器**，当上游新增消息时，无需手写编解码逻辑即可一键生成强类型 MoonBit 代码。
3. **技术风险与消解方案**：
   - **真机联调硬件依赖风险**：真机飞控联调通常需要 Pixhawk 硬件或 SITL 仿真环境。为此，本项目一方面严格遵循 MAVLink 官方 C/Rust 参考实现的**标准字节流测试向量（Golden Wire Vectors）**（如 `HEARTBEAT` 帧固定 `CRC_EXTRA = 50`、载荷按 `[custom_mode(4B), type(1B), autopilot(1B), base_mode(1B), system_status(1B), mavlink_version(1B)]` 重排），另一方面内置了完整的 **PX4 飞控遥测流仿真与地面站双向航点上传任务协议（Mission Protocol）状态机示例**，在不依赖外部硬件的前提下实现 100% 字节级协议一致性验证。
