# MR60BHA2 环境与首轮测试结果

测试时间：2026-08-08（Asia/Shanghai）

## 已完成

- 拉取 `Love4yzp/Seeed-mmWave-library`，固定 commit：`ade050c62f874c214fe83ebb586d723c46b03226`。
- 配置项目本地 Arduino CLI `1.5.1`，未修改系统级 Arduino 配置。
- 安装 Espressif Arduino Core `3.3.11`。
- 安装 `Adafruit NeoPixel 1.15.5` 与 `hp_BH1750 1.0.2`。
- 确认板卡为 XIAO ESP32C6 / ESP32-C6FH4，首轮测试串口为 `COM4`。
- 编译并上传 `robot_probe`：Flash 298226 bytes（22%），RAM globals 15788 bytes（4%）。
- 连续采集并解析 JSON Lines 数据。

## 12 秒采样摘要

收到 652 条有效事件；串口刚打开时有 2 条不完整行，解析器已忽略。

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

观察到的大致输出频率：phase 15.6 Hz，目标/距离/存在约 8 Hz，心率约 0.8 Hz，照度约 5 Hz。

当前心率和呼吸率为 0 不代表 UART 失败：phase、位置、存在和距离均有持续有效数据。生命体征算法更适合单人静止或睡眠场景，应让雷达朝向胸腹部、距离不超过约 1.5 m，并在实际环境重新测试。

## 可提供给机器人的数据

- `presence`：人体存在事件。
- `targets`：目标 `x_m`、`y_m`、`doppler_index`、`cluster_index`、`speed_cm_s`。
- `distance`：生命体征目标距离（cm）。
- `phase`：total / breath / heart 原始相位特征，可用于时序分析。
- `breath_rate`、`heart_rate`：雷达算法输出的 bpm。
- `illuminance`：板载 BH1750 照度。

推荐机器人侧映射为 ROS 2 topics：

- `/mmwave/presence` (`std_msgs/Bool`)
- `/mmwave/targets`（自定义 target array）
- `/mmwave/vitals`（distance / breath bpm / heart bpm）
- `/mmwave/phase`（带时间戳的三通道数组）
- `/mmwave/illuminance` (`sensor_msgs/Illuminance`)

## 已知限制与风险

- 心率/呼吸算法主要适合单人、静止场景；坐姿活动或运动时误差会明显增大。
- 当前库的 `isHumanDetected()` 无法可靠区分“没有新 presence 包”和“新包报告无人”，机器人侧应结合 target 超时实现 presence 状态机。
- 启动后的第一批数据建议丢弃并等待状态稳定。
- 照度 0 lux 需要通过改变光照或移除遮挡进一步确认。
- 尚未升级 MR60BHA2 雷达模块固件。OTA 升级有风险，应先确认版本和恢复方案。
- XIAO 原有预刷固件已被 Arduino 测试固件替换；MR60BHA2 雷达模块固件未修改。

