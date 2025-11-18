#!/bin/sh
cd /mnt/mmcblk0p1

killall -9 snapshot_loop.sh 2>/dev/null
sleep 1

cat > /tmp/snapshot_loop.sh << 'SNAPSHOT'
#!/bin/sh
cd /mnt/mmcblk0p1
while true; do
    timeout 10 ./ffmpeg-3.2 -y \
        -stimeout 5000000 -rtsp_transport tcp \
        -i rtsp://admin:admin12345@192.168.1.20:554/ \
        -threads 1 -vframes 1 -vf "scale=640:360" \
        -q:v 7 /tmp/livestream.jpg >/dev/null 2>&1

    sleep 1
done
SNAPSHOT

chmod +x /tmp/snapshot_loop.sh
nohup /tmp/snapshot_loop.sh >/dev/null 2>&1 &

echo "Snapshot started (every 1 second)"
