# OpenIPC NVR System

A lightweight Network Video Recorder (NVR) system for OpenIPC embedded boards with limited resources (32MB RAM).

## 📋 Features

- 📹 **Continuous video recording** from IP cameras via RTSP
- 🎥 **Live snapshot preview** - Memory-efficient livestream (1 FPS snapshot mode)
- 🎬 **Web-based video player** with recordings list
- 🔄 **Auto-restart** recording on failures
- 💾 **Ultra memory-efficient** - Optimized for 32MB RAM boards
- 🎯 **Sequential file numbering** (000.mp4, 001.mp4, ...)
- 🌐 **Simple web interface** - Single-page control panel
- 🔴 **Recording indicator** - Visual feedback during recording

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

2. Place all binaries in `/mnt/mmcblk0p1/` and make them executable:
   ```bash
   chmod +x /mnt/mmcblk0p1/ffmpeg-3.2
   chmod +x /mnt/mmcblk0p1/ffprobe-3.2
   ```

**Note**: MediaMTX is NOT used in the current architecture. FFmpeg connects directly to the camera for better stability and lower RAM usage.

## 🚀 Installation

1. **Clone the repository:**
   ```bash
   cd /mnt/mmcblk0p1/
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .
   ```

2. **Download required binaries** (see above)

3. **Configure camera settings:**
   Edit `startup.sh` and `start_livestream.sh` - update camera RTSP URL:
   ```bash
   # Change this line in both files:
   rtsp://admin:admin12345@192.168.1.20:554/
   # To your camera's RTSP URL
   ```

4. **Make scripts executable:**
   ```bash
   chmod +x startup.sh
   chmod +x start_livestream.sh
   chmod +x endprocess.sh
   chmod +x webserver/run_server.sh
   ```

5. **Start the system:**
   ```bash
   # Start livestream
   /mnt/mmcblk0p1/start_livestream.sh &

   # Start web server
   cd /mnt/mmcblk0p1/webserver
   ./run_server.sh &
   ```

6. **Access the web interface:**
   Open browser: `http://192.168.1.10:8080`

## 📁 Project Structure

```
/mnt/mmcblk0p1/
├── startup.sh              # Start recording with auto-restart
├── start_livestream.sh     # Start snapshot-based livestream (NEW)
├── endprocess.sh           # Stop all NVR services
├── mediamtx.yml            # MediaMTX config (not used, kept for reference)
├── webserver/
│   └── run_server.sh       # Web server and UI with livestream support
├── recordings/             # Recorded videos (auto-created)
│   ├── 000.mp4
│   ├── 001.mp4
│   └── ...
└── tmp/                    # Logs and livestream snapshot (in RAM)
    ├── livestream.jpg      # Current snapshot for web UI
    ├── snapshot_loop.sh    # Generated snapshot capture loop
    ├── ffmpeg_wrapper.sh   # Generated recording wrapper
    ├── ffmpeg.log
    └── ffmpeg_wrapper.log
```

## 🎮 Usage

### Web Interface Controls:

- **📺 Livestream View**: Default view - Shows live snapshot (1 FPS) when not recording
- **▶️ Start Record**: Start recording from camera (stops livestream)
- **⏹️ Stop Record**: Stop recording (resumes livestream)
- **🛑 Shutdown System**: Stop all services and web server
- **🔄 Refresh List**: Reload recordings list
- **🎬 Click Recording**: Play recorded video

### CLI Commands:

```bash
# Start livestream
/mnt/mmcblk0p1/start_livestream.sh

# Start recording
/mnt/mmcblk0p1/startup.sh

# Stop all services
/mnt/mmcblk0p1/endprocess.sh

# View logs
tail -f /tmp/ffmpeg.log
tail -f /tmp/ffmpeg_wrapper.log
```

## ⚙️ Configuration

### Camera Settings:

Update RTSP URL in **both** `startup.sh` and `start_livestream.sh`:

```bash
# Find and replace this URL:
rtsp://admin:admin12345@192.168.1.20:554/
# With your camera's RTSP URL
```

### Recording Settings (`startup.sh`):

- **Segment duration**: 60 seconds (`-segment_time 60`)
- **Video codec**: Copy (no transcoding) - Uses camera's native HEVC/H.264
- **Audio**: Disabled (`-an`)
- **Format**: MP4 with fragmented format for browser compatibility
- **Optimizations**:
  - `-fflags +genpts` - Generate timestamps
  - `-avoid_negative_ts make_zero` - Fix timestamp issues
  - `movflags=+frag_keyframe+empty_moov+default_base_moof` - Prevent frame skipping

### Livestream Settings (`start_livestream.sh`):

- **Capture interval**: 1 second (1 FPS)
- **Resolution**: 640x360 (optimized for RAM)
- **Quality**: 7 (JPEG quality scale 2-31, lower is better)
- **Timeout**: 10 seconds per capture (prevents hanging)

## 🔍 Troubleshooting

### Livestream not showing:
```bash
# Check if snapshot loop is running
ps | grep snapshot_loop

# Check snapshot file
ls -lh /tmp/livestream.jpg

# Restart livestream
/mnt/mmcblk0p1/endprocess.sh
/mnt/mmcblk0p1/start_livestream.sh
```

### Recording not starting:
```bash
# Check camera connection directly
./ffprobe-3.2 -rtsp_transport tcp -i rtsp://admin:admin12345@192.168.1.20:554/

# View logs
cat /tmp/ffmpeg.log
cat /tmp/ffmpeg_wrapper.log

# Check if FFmpeg is running
ps | grep ffmpeg
```

### Out of memory errors (OOM Killer):
This system is designed to avoid OOM issues on 32MB RAM boards:
- ✅ **Livestream**: Uses snapshot mode (captures 1 frame every 1s, exits immediately)
- ✅ **Recording**: Direct stream copy (no transcoding, minimal RAM)
- ✅ **No MediaMTX**: Bypassed to save ~7-10MB RAM
- If still having issues, increase snapshot interval in `start_livestream.sh` (change `sleep 1` to `sleep 2` or `sleep 3`)

### Video playback issues (frame skipping):
- Already using optimized MP4 flags to prevent frame skipping
- If issues persist, check camera stream quality with:
```bash
./ffprobe-3.2 -rtsp_transport tcp -i rtsp://admin:admin12345@192.168.1.20:554/
```

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

### Architecture Overview:

```
Camera (RTSP) ──┬──> FFmpeg (snapshot) ──> /tmp/livestream.jpg ──> Web UI
                │
                └──> FFmpeg (recording) ──> /mnt/mmcblk0p1/recordings/*.mp4
```

### Key Design Decisions:

1. **Snapshot-based Livestream**:
   - Avoids continuous FFmpeg process for livestream
   - Captures 1 frame every 1 second, then exits
   - Eliminates OOM issues on 32MB RAM boards
   - Trade-off: 1 FPS instead of continuous stream

2. **Direct Camera Connection**:
   - FFmpeg connects directly to camera (no MediaMTX proxy)
   - Saves ~7-10MB RAM
   - More stable on resource-constrained boards
   - MediaMTX config kept for reference only

3. **One FFmpeg Instance Rule**:
   - Only ONE FFmpeg runs at a time for recording
   - When recording starts → snapshot loop stops
   - When recording stops → snapshot loop resumes
   - Prevents resource conflicts on 32MB RAM

4. **MP4 Fragmented Format**:
   - Uses `movflags=+frag_keyframe+empty_moov+default_base_moof`
   - Prevents frame skipping issues
   - Browser-compatible (no external players needed)
   - No internet required for playback

### Memory Optimizations:

- **Auto-restart**: FFmpeg wrapper automatically restarts on crashes
- **Stream copy**: No video transcoding (minimal CPU/RAM)
- **Sequential numbering**: Continues from last number after restart
- **Log location**: `/tmp/` (in RAM, not SD card to save write cycles)
- **Snapshot cleanup**: Old snapshots overwritten (no accumulation)

### Performance:

- **RAM Usage (Idle)**: ~5-8MB (snapshot loop)
- **RAM Usage (Recording)**: ~8-12MB (direct copy, no transcoding)
- **Storage**: ~30-50MB per minute (depends on camera bitrate)
- **Livestream Latency**: 1-2 seconds (snapshot refresh rate)

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
