#!/bin/sh
cd /mnt/mmcblk0p1

# Start Mediamtx
if ! pidof mediamtx >/dev/null; then
    ./mediamtx mediamtx.yml > /tmp/mediamtx.log 2>&1 &
    sleep 1
fi

# Wait for RTSP (faster check)
for i in $(seq 1 10); do
    nc -zv 127.0.0.1 8554 >/dev/null 2>&1 && break
    sleep 0.5
done

mkdir -p recordings

# Find last number
LAST_NUM=$(ls recordings/*.mp4 2>/dev/null | sed 's/.*\///;s/\.mp4//' | sort -n | tail -n1)
if [ -z "$LAST_NUM" ]; then
    NEXT_NUM=0
else
    NEXT_NUM=$((10#$LAST_NUM + 1))
fi

# Kill old wrapper
killall -9 ffmpeg_wrapper.sh 2>/dev/null
killall -9 ffmpeg 2>/dev/null
killall -9 ffmpeg-3.2 2>/dev/null

# Create simple wrapper
cat > /tmp/ffmpeg_wrapper.sh << 'WRAPPER'
#!/bin/sh
cd /mnt/mmcblk0p1

while true; do
    LAST=$(ls recordings/*.mp4 2>/dev/null | sed 's/.*\///;s/\.mp4//' | sort -n | tail -n1)
    [ -z "$LAST" ] && NUM=0 || NUM=$((10#$LAST + 1))

    echo "$(date): Starting segment $NUM" >> /tmp/ffmpeg_wrapper.log

    ./ffmpeg-3.2 -rtsp_transport tcp -i rtsp://127.0.0.1:8554/camera \
        -c:v copy -an -f segment -segment_time 60 \
        -reset_timestamps 1 -segment_start_number $NUM \
        recordings/%03d.mp4 >> /tmp/ffmpeg.log 2>&1

    echo "$(date): Stopped (code $?), restart in 5s" >> /tmp/ffmpeg_wrapper.log
    sleep 5
done
WRAPPER

chmod +x /tmp/ffmpeg_wrapper.sh
nohup /tmp/ffmpeg_wrapper.sh >/dev/null 2>&1 &

echo "OK"
