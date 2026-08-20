# MR60BHA2 环境与首轮测试结果

测试时间：2026-08-08（Asia/Shanghai）

## 已完成

- 拉取 `Love4yzp/Seeed-mmWave-library` 的 `main` 分支。
  - commit: `ade050c62f874c214fe83ebb586d723c46b03226`
  - 库版本：`1.0.0`
- 在项目内安装 Arduino CLI `1.5.1`，不修改系统级 Arduino 配置。
- 安装 Espressif Arduino core `3.3.11`。
- 安装 `Adafruit NeoPixel 1.15.5` 和 `hp_BH1750 1.0.2`。
- 确认板卡：XIAO ESP32C6 / ESP32-C6FH4，USB 串口 `COM4`。
- 编译并上传 `robot_probe`，编译结果：
  - Flash: 298226 bytes / 1310720 bytes (22%)
  - RAM globals: 15788 bytes / 327680 bytes (4%)
- 连续串口采样并解析 JSON Lines。


## 12 秒采样摘要

有效事件 652 条，串口刚打开时有 2 条半截行。

| 信号 | 结果 |
|---|---|
| 目标数量 | 1 |
| 目标 X | -0.106 至 -0.062 m，均值 -0.081 m |
| 目标 Y | 0.786 至 0.794 m，均值 0.790 m |
| 目标速度 | 0 cm/s |
| 生命体征测距 | 74.62 cm |
| 呼吸率 | 0 bpm |
| 心率 | 0 bpm |
| total phase | -0.14641 至 0.13674 |
| breath phase | -0.00837 至 0.00952 |
| heart phase | -0.05210 至 0.03996 |
| 照度 | 0 lux |

观察到的大致输出频率：phase 15.6 Hz，目标/距离/存在约 8 Hz，心率约 0.8 Hz，
照度约 5 Hz。当前心率和呼吸率为 0，不代表 UART 失败；phase、位置、存在和距离均有
持续有效数据。按 Seeed 说明，心率/呼吸应在睡眠场景下测试：雷达位于床头上方约 1 m，
向胸腔方向下倾 45 度，雷达到胸腔距离不超过 1.5 m。

## 可给机器人使用的数据

- `presence`: 人体存在正事件。
- `targets`: 最多 3 个目标的 `x_m`、`y_m`、`doppler_index`、
  `cluster_index`、`speed_cm_s`。
- `distance`: 生命体征目标距离（cm）。
- `phase`: total / breath / heart 原始相位特征，可用于时序分析。
- `breath_rate`, `heart_rate`: 算法输出的 bpm。
- `illuminance`: 板载 BH1750 照度。

建议先把 JSON Lines 接入机器人上位机，再映射成 ROS 2 topic：

- `/mmwave/presence` (`std_msgs/Bool`)
- `/mmwave/targets`（自定义 target array）
- `/mmwave/vitals`（distance / breath bpm / heart bpm）
- `/mmwave/phase`（带时间戳的三通道数组）
- `/mmwave/illuminance` (`sensor_msgs/Illuminance`)

## 已知限制与风险

- 官方明确说明心率/呼吸算法适合睡眠场景，办公桌前坐姿或运动时误差会很大。
- 当前 `v1.0.0` 的 `isHumanDetected()` 把“没有新 presence 包”和“新包报告无人”都表示为
  `false`，无法可靠地产生离开事件。机器人侧应结合 targets 超时实现 presence 状态机。
- `SEEED_MR60BHA2` 中几个 validity 布尔量没有显式初始化，启动后的首批读数应丢弃；
  生产使用前建议修补库或验证 v2 release candidate。
- 当前照度为 0 lux；需要在改变光照/移除遮挡后复测，才能区分真实黑暗与安装遮挡。
- 未升级 MR60BHA2 雷达固件。固件升级有变砖风险，且 Seeed 明确要求谨慎操作；应先读取
  当前版本、保存恢复方案，再单独决定是否升级。
- XIAO 上原有的预刷固件已被 Arduino 测试固件替换；MR60BHA2 雷达模块固件未改动。
- Inturai 网站验证尚未执行，因为当前会话没有可连接的交互式浏览器。

