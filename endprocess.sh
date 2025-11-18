#!/bin/sh
echo "⛔ Stopping all NVR services..."

# Stop snapshot loop first!
killall -9 snapshot_loop.sh 2>/dev/null
killall -9 timeout 2>/dev/null

# Stop ffmpeg wrapper
killall -9 ffmpeg_wrapper.sh 2>/dev/null

# Stop all ffmpeg versions
killall -9 ffmpeg 2>/dev/null
killall -9 ffmpeg-3.2 2>/dev/null
killall -9 ffmpeg-3.4 2>/dev/null
killall -9 ffmpeg-4.0.1 2>/dev/null
killall -9 ffmpeg-4.2.1 2>/dev/null

# Extra cleanup - find any remaining ffmpeg
FFPIDS="$(pgrep -f 'ffmpeg')"
if [ -n "$FFPIDS" ]; then
    for pid in $FFPIDS; do
        kill -9 $pid 2>/dev/null
    done
fi

# Stop mediamtx (if running)
MTPIDS="$(pgrep -f '[m]ediamtx')"
if [ -n "$MTPIDS" ]; then
    kill -9 $MTPIDS 2>/dev/null
    killall -9 mediamtx 2>/dev/null
fi

echo "✅ All services stopped."
