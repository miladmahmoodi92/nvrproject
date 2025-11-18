#!/bin/sh
cd /mnt/mmcblk0p1

# Kill snapshot loop first
killall -9 snapshot_loop.sh 2>/dev/null
killall -9 timeout 2>/dev/null

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

    ./ffmpeg-3.2 -rtsp_transport tcp \
        -i rtsp://admin:admin12345@192.168.1.20:554/ \
        -c:v copy -an \
        -fflags +genpts -avoid_negative_ts make_zero \
        -f segment -segment_time 60 -segment_format mp4 \
        -segment_format_options movflags=+frag_keyframe+empty_moov+default_base_moof \
        -reset_timestamps 1 -segment_start_number $NUM \
        recordings/%03d.mp4 >> /tmp/ffmpeg.log 2>&1

    echo "$(date): Stopped (code $?), restart in 5s" >> /tmp/ffmpeg_wrapper.log
    sleep 5
done
WRAPPER

chmod +x /tmp/ffmpeg_wrapper.sh
nohup /tmp/ffmpeg_wrapper.sh >/dev/null 2>&1 &

echo "OK"
