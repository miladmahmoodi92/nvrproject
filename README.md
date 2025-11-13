# OpenIPC NVR System

A lightweight Network Video Recorder (NVR) system for OpenIPC embedded boards with limited resources (32MB RAM).

## 📋 Features

- 📹 Continuous video recording from IP cameras via RTSP
- 🎬 Web-based video player with recordings list
- 🔄 Auto-restart recording on failures
- 💾 Memory-efficient streaming (optimized for 32MB RAM)
- 🎯 Sequential file numbering (000.mp4, 001.mp4, ...)
- 🌐 Simple web interface for controlling recording

## 🔧 Hardware Requirements

- **Board**: OpenIPC GK7205V200 (or similar)
- **RAM**: 32MB minimum
- **Storage**: SD card (recommended: 64GB+)
- **Camera**: IP camera with RTSP support

## 📦 Software Requirements

Before running this project, you need to download the following binaries:

### Required Binaries (not included in this repo):

1. **FFmpeg 3.2** (armhf):
   - Download: [FFmpeg 3.2 for ARM](https://johnvansickle.com/ffmpeg/old-releases/)
   - Files needed: `ffmpeg-3.2`, `ffprobe-3.2`

2. **MediaMTX v1.15.3** (armhf):
   - Download: [MediaMTX Releases](https://github.com/bluenviron/mediamtx/releases/tag/v1.15.3)
   - File needed: `mediamtx`

3. Place all binaries in `/mnt/mmcblk0p1/` and make them executable:
   ```bash
   chmod +x /mnt/mmcblk0p1/ffmpeg-3.2
   chmod +x /mnt/mmcblk0p1/ffprobe-3.2
   chmod +x /mnt/mmcblk0p1/mediamtx
   ```

## 🚀 Installation

1. **Clone the repository:**
   ```bash
   cd /mnt/mmcblk0p1/
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .
   ```

2. **Download required binaries** (see above)

3. **Configure camera settings:**
   Edit `mediamtx.yml` and update camera RTSP URL:
   ```yaml
   paths:
     camera:
       source: rtsp://admin:admin12345@192.168.1.20:554/
   ```

4. **Make scripts executable:**
   ```bash
   chmod +x startup.sh
   chmod +x endprocess.sh
   chmod +x webserver/run_server.sh
   ```

5. **Start the web server:**
   ```bash
   cd /mnt/mmcblk0p1/webserver
   ./run_server.sh &
   ```

6. **Access the web interface:**
   Open browser: `http://192.168.1.10:8080`

## 📁 Project Structure

```
/mnt/mmcblk0p1/
├── startup.sh              # Start recording with auto-restart
├── endprocess.sh           # Stop all recording services
├── mediamtx.yml            # MediaMTX RTSP proxy configuration
├── webserver/
│   └── run_server.sh       # Web server and UI
├── recordings/             # Recorded videos (auto-created)
│   ├── 000.mp4
│   ├── 001.mp4
│   └── ...
└── tmp/                    # Logs (in RAM, auto-created)
    ├── mediamtx.log
    ├── ffmpeg.log
    └── ffmpeg_wrapper.log
```

## 🎮 Usage

### Web Interface Controls:

- **▶️ Start Record**: Start recording from camera
- **⏹️ Stop Record**: Stop recording
- **🛑 Shutdown System**: Stop all services and web server
- **🔄 Refresh List**: Reload recordings list

### CLI Commands:

```bash
# Start recording
/mnt/mmcblk0p1/startup.sh

# Stop recording
/mnt/mmcblk0p1/endprocess.sh

# View logs
tail -f /tmp/ffmpeg.log
tail -f /tmp/mediamtx.log
```

## ⚙️ Configuration

### Camera Settings (`mediamtx.yml`):

```yaml
paths:
  camera:
    source: rtsp://USERNAME:PASSWORD@CAMERA_IP:554/
    sourceProtocol: tcp
    sourceOnDemand: yes
```

### Recording Settings (`startup.sh`):

- **Segment duration**: 60 seconds (line 43: `-segment_time 60`)
- **Video codec**: Copy (no transcoding)
- **Audio**: Disabled (`-an`)

## 🔍 Troubleshooting

### Recording not starting:
```bash
# Check MediaMTX connection
nc -zv 127.0.0.1 8554

# Check camera connection
./ffprobe-3.2 rtsp://admin:admin12345@192.168.1.20:554/

# View logs
cat /tmp/mediamtx.log
cat /tmp/ffmpeg.log
```

### Out of memory errors:
- MediaMTX may crash with 32MB RAM
- Use `sourceOnDemand: yes` to reduce memory usage
- Consider disabling live streaming features

### Web interface not accessible:
```bash
# Check if httpd is running
ps | grep httpd

# Restart web server
killall httpd
cd /mnt/mmcblk0p1/webserver
./run_server.sh &
```

## 📝 Technical Details

- **Auto-restart**: FFmpeg wrapper automatically restarts on crashes
- **Memory optimization**: Uses `dd bs=8192` for video streaming
- **Sequential numbering**: Continues from last number after restart
- **Log location**: `/tmp/` (in RAM, not SD card)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- [OpenIPC](https://openipc.org/) - Open IP Camera firmware
- [MediaMTX](https://github.com/bluenviron/mediamtx) - RTSP proxy server
- [FFmpeg](https://ffmpeg.org/) - Video recording and processing

## ⚠️ Important Notes

- This system is designed for **local network use only**
- Do not expose to the internet without proper security measures
- Regularly backup your recordings
- Monitor SD card health (recordings write continuously)

---

**Made with ❤️ for embedded systems**
