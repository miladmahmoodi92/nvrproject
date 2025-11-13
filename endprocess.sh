#!/bin/sh
echo "⛔ Stopping recording and RTSP services..."

# Stop ffmpeg wrapper
killall -9 ffmpeg_wrapper.sh 2>/dev/null

# Stop all ffmpeg versions
killall -9 ffmpeg 2>/dev/null
killall -9 ffmpeg-3.2 2>/dev/null
killall -9 ffmpeg-3.4 2>/dev/null
killall -9 ffmpeg-4.0.1 2>/dev/null
killall -9 ffmpeg-4.2.1 2>/dev/null

FFPIDS="$(pgrep -f 'ffmpeg')"
if [ -n "$FFPIDS" ]; then
    echo "Stopping remaining ffmpeg (PIDs: $FFPIDS)..."
    for pid in $FFPIDS; do
        kill -9 $pid 2>/dev/null
    done
fi

# Stop mediamtx
MTPIDS="$(pgrep -f '[m]ediamtx')"
if [ -n "$MTPIDS" ]; then
    echo "Stopping mediamtx..."
    kill -9 $MTPIDS
    killall -9 mediamtx 2>/dev/null
fi

echo "✅ All related processes stopped."
