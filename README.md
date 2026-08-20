# MR60BHA2 Sensor Dashboard and Robot Probe

本仓库提供 Seeed MR60BHA2 60 GHz mmWave Kit 的完整可复现环境，包含：

- XIAO ESP32C6 雷达采集固件（JSON Lines 输出）
- 基于 Web Serial 的英文可视化网页
- 无硬件的一人 Demo 模式
- 官方 Seeed 雷达 GUI 的切换脚本
- 24 秒科研宣传视频及可复现渲染脚本
- 固定版本的 Arduino CLI、ESP32 Core 和依赖库安装流程

> 生命体征结果仅用于科研演示，不是医疗诊断结果。仓库中的 Demo 数值是模拟数据。

## 1. 最快观看网页（不需要传感器）

### 环境要求

- Windows 10/11
- [Git](https://git-scm.com/download/win)
- [Python 3](https://www.python.org/downloads/windows/)
- Microsoft Edge 或 Google Chrome

```powershell
git clone --recurse-submodules https://github.com/SoophieS/MR60BHA2-Sensor-Dashboard.git
cd MR60BHA2-Sensor-Dashboard
.\start-demo.cmd
```

浏览器将打开 <http://localhost:8765>。点击网页右上角 **Demo Mode**，即可看到一个模拟目标、心率、呼吸率、距离、照度和趋势曲线。

Demo Mode 不读取真实传感器。如果页面显示 `Waiting for target data`，说明尚未点击 **Demo Mode** 或尚未连接串口。

## 2. 在新电脑配置真实传感器

### 硬件

- Seeed MR60BHA2 mmWave Kit
- XIAO ESP32C6
- 支持数据传输的 USB-C 线

首次安装（需要网络）：

```powershell
git clone --recurse-submodules https://github.com/SoophieS/MR60BHA2-Sensor-Dashboard.git
cd MR60BHA2-Sensor-Dashboard
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

安装脚本会在项目内部配置以下固定版本，不修改系统 Arduino IDE：

| 组件 | 版本 |
|---|---:|
| Arduino CLI | 1.5.1 |
| ESP32 Arduino Core | 3.3.11 |
| Adafruit NeoPixel | 1.15.5 |
| hp_BH1750 | 1.0.2 |
| Seeed-mmWave-library | Git submodule，固定 commit `ade050c` |

查找 XIAO 对应的串口：

```powershell
.\arduino-env.cmd board list
```

不要直接假设另一台电脑也是 `COM4`。确认端口后，例如设备是 `COM7`：

```powershell
.\start-dashboard.cmd COM7
```

该命令会：

1. 编译并上传 `robot_probe` 到 XIAO ESP32C6；
2. 在 `127.0.0.1:8765` 启动静态网页服务器；
3. 用 Edge/Chrome 打开 Dashboard。

网页打开后点击 **Connect Sensor**，然后在浏览器弹窗中选择刚才确认的 XIAO 串口。Web Serial 的安全规则要求用户手动授权，网页不能自动选择 COM 端口。

## 3. 日常使用

如果 XIAO 已经刷入 `robot_probe`，无需每次重新上传固件，可直接运行：

```powershell
.\start-demo.cmd
```

然后点击 **Connect Sensor** 并选择端口。

串口一次只能被一个程序占用。连接网页前请关闭 Arduino Serial Monitor、Seeed 官方 GUI、Radar OTA 软件和其他串口终端。

## 4. 网页显示的数据

`robot_probe` 以 115200 baud 输出一行一个 JSON 对象：

```json
{"t_ms":12345,"kind":"presence","detected":true}
{"t_ms":12346,"kind":"targets","count":1,"items":[{"x_m":-0.08,"y_m":0.79,"speed_cm_s":0.0}]}
{"t_ms":12347,"kind":"distance","cm":74.62}
{"t_ms":12348,"kind":"phase","total":0.03509,"breath":-0.00062,"heart":-0.00883}
{"t_ms":12349,"kind":"heart_rate","bpm":76.0}
{"t_ms":12350,"kind":"breath_rate","bpm":15.0}
```

| 事件 | 含义 |
|---|---|
| `presence` | 是否检测到人体存在 |
| `targets` | 目标数量、二维坐标和速度 |
| `distance` | 生命体征目标距离，单位 cm |
| `phase` | total / breath / heart 微动相位特征 |
| `heart_rate` | 雷达算法给出的心率 bpm |
| `breath_rate` | 雷达算法给出的呼吸率 bpm |
| `illuminance` | 板载 BH1750 照度 lux |

MR60BHA2 的生命体征模式主要面向单人、相对静止场景。多人存在、身体大幅移动、距离或角度不合适时，心率和呼吸率容易变成 0 或出现较大误差。

## 5. 科研宣传视频

成片已经包含在仓库中：

```text
video_demo/output/MR60BHA2_research_promo.mp4
```

重新生成视频：

```powershell
powershell -ExecutionPolicy Bypass -File .\video_demo\setup-video.ps1
powershell -ExecutionPolicy Bypass -File .\video_demo\render_demo.ps1
```

第一条命令下载项目本地的 FFmpeg，不会修改系统 PATH。渲染结果为 24 秒、1920×1080、30 fps 的 H.264/AAC MP4。

## 6. Seeed 官方 Radar GUI（可选）

大型 GUI/OTA 二进制文件不存入 GitHub。按照 [`tools/README.md`](tools/README.md) 从 Seeed 官方页面下载并放到指定目录，然后执行：

```powershell
.\start-radar-gui.cmd COM7
```

官方 GUI 需要 `passthrough_mode` 固件。结束 GUI 测试后恢复本项目 JSON 固件：

```powershell
.\restore-robot-probe.cmd COM7
```

不要在没有固件备份和恢复方案时使用 OTA 工具的 **Request Update**。

## 7. 常见问题

### 页面一直显示 Waiting for target data

1. 无硬件展示：点击 **Demo Mode**。
2. 真实传感器：点击 **Connect Sensor** 并选择正确 COM 端口。
3. 确认 XIAO 已刷入 `robot_probe`，而不是 `passthrough_mode`。
4. 关闭占用该端口的 Serial Monitor、Seeed GUI 或 OTA 软件。
5. 必须通过 `http://localhost:8765` 打开，不能直接双击 `index.html`。

### 浏览器没有串口按钮或无法连接

使用最新版 Microsoft Edge 或 Google Chrome。Firefox/Safari 当前不支持本项目使用的 Web Serial 接口。

### 心率或呼吸率是 0

这不一定代表串口故障。如果 `phase`、`targets`、`presence` 或 `distance` 仍在更新，通信通常正常。让单人保持静止，雷达朝向胸腹部，并在实际部署环境中重新验证距离、角度和遮挡影响。

### PowerShell 禁止运行脚本

使用本 README 中的单次绕过方式：

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

无需永久更改系统执行策略。

## 8. 项目结构

```text
radar_dashboard/        Web Serial 可视化网页
robot_probe/            XIAO ESP32C6 JSON Lines 固件
Seeed-mmWave-library/   固定版本的上游 Git submodule
video_demo/             宣传视频、预览图和渲染脚本
tools/                  官方 GUI 放置说明（不提交大型二进制）
setup-windows.ps1       新电脑 Arduino 环境安装
start-demo.cmd          仅启动网页，不刷固件
start-dashboard.cmd     刷入 probe 并启动网页
start-radar-gui.cmd     刷入 passthrough 并启动官方 GUI
restore-robot-probe.cmd 恢复 JSON Lines 固件
```

## 9. 复现检查清单

- [ ] 使用 `--recurse-submodules` 克隆，或运行 `git submodule update --init --recursive`
- [ ] `setup-windows.ps1` 成功完成
- [ ] `arduino-env.cmd board list` 能识别 XIAO ESP32C6
- [ ] 使用实际 COM 端口运行 `start-dashboard.cmd`
- [ ] Edge/Chrome 手动授权同一 COM 端口
- [ ] Dashboard 中 frame counter 持续增加
- [ ] Demo 数据与真实传感器数据没有混淆
- [ ] 机器人部署前已在目标环境重新标定和验证
