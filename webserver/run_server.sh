#!/bin/sh
WWWROOT="/mnt/mmcblk0p1/webserver/www"
CGIROOT="$WWWROOT/cgi-bin"

killall httpd 2>/dev/null
sleep 2
rm -rf "$WWWROOT"
mkdir -p "$CGIROOT"

# --- HTML ---
cat > "$WWWROOT/index.html" << 'HTML'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OpenIPC NVR</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d0d0d;color:#eee;font-family:Arial,sans-serif;padding:20px}
h1{text-align:center;font-size:28px;margin-bottom:25px;color:#3498db}
.container{display:flex;gap:20px;max-width:1400px;margin:0 auto}
.left-panel{flex:1;min-width:300px;max-width:400px}
.right-panel{flex:2;min-width:500px}
#player-container{background:#000;border-radius:10px;padding:15px;margin-bottom:20px;min-height:450px;display:flex;align-items:center;justify-content:center}
#player-container video{width:100%;max-height:500px;border-radius:8px;background:#000}
#player-container .placeholder{color:#777;font-size:18px;text-align:center}
.controls{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px}
.controls button{padding:10px 16px;font-size:14px;border:none;border-radius:8px;cursor:pointer;font-weight:600;transition:all 0.3s;position:relative}
.controls button:hover:not(:disabled){transform:translateY(-2px);box-shadow:0 4px 12px rgba(0,0,0,0.3)}
.controls button:disabled{opacity:0.7;cursor:not-allowed}
#start{background:#27ae60;color:#fff}
#stop{background:#e74c3c;color:#fff}
#shutdown{background:#8e44ad;color:#fff}
.spinner{display:inline-block;width:14px;height:14px;border:2px solid rgba(255,255,255,0.3);border-top:2px solid #fff;border-radius:50%;animation:spin 0.8s linear infinite;margin-left:8px;vertical-align:middle}
@keyframes spin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}
#status{margin-top:15px;padding:12px;border-radius:8px;display:none;text-align:center;font-size:14px}
#status.show{display:block}
#status.info{background:#3498db;color:#fff}
#status.success{background:#27ae60;color:#fff}
#status.error{background:#e74c3c;color:#fff}
#recordings{background:#1a1a1a;border-radius:10px;padding:20px}
#recordings h2{color:#3498db;border-bottom:2px solid #3498db;padding-bottom:12px;margin-bottom:15px;font-size:20px}
#recordings-list{list-style:none;max-height:500px;overflow-y:auto;overflow-x:hidden;margin-bottom:15px}
#recordings-list::-webkit-scrollbar{width:8px}
#recordings-list::-webkit-scrollbar-track{background:#0d0d0d;border-radius:4px}
#recordings-list::-webkit-scrollbar-thumb{background:#3498db;border-radius:4px}
#recordings-list li{background:#222;margin:8px 0;padding:12px 14px;border-radius:8px;cursor:pointer;transition:all 0.2s;overflow:hidden}
#recordings-list li:hover{background:#2c2c2c;transform:translateX(3px)}
#recordings-list li.active{background:#27ae60;color:#fff}
.rec-name{display:block;font-size:15px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.rec-date{display:block;font-size:12px;color:#999;margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#recordings-list li.active .rec-date{color:#e0e0e0}
#refresh{width:100%;padding:12px;font-size:14px;background:#3498db;color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:600;transition:all 0.3s}
#refresh:hover{background:#2980b9;transform:translateY(-2px)}
.loading{text-align:center;color:#777;padding:30px;font-size:14px}
</style>
</head>
<body>
<h1>📹 OpenIPC NVR Control Panel</h1>
<div class="container">
<div class="left-panel">
<div id="recordings">
<h2>📼 Recorded Videos</h2>
<div class="loading">Loading recordings...</div>
<ul id="recordings-list"></ul>
<button id="refresh" onclick="loadRecordings()">🔄 Refresh List</button>
</div>
</div>
<div class="right-panel">
<div id="player-container">
<div class="placeholder">Select a recording to play</div>
<video id="player" controls style="display:none;" preload="metadata"></video>
</div>
<div class="controls">
<button id="start" onclick="doStart()">▶️ Start Record</button>
<button id="stop" onclick="doStop()">⏹️ Stop Record</button>
<button id="shutdown" onclick="doShutdown()">🛑 Shutdown System</button>
</div>
<div id="status"></div>
</div>
</div>
<script>
function showStatus(m,t){
var s=document.getElementById('status');
s.textContent=m;
s.className='show '+t;
setTimeout(function(){s.className=''},5000);
}
function playVideo(f){
var p=document.getElementById('player');
var ph=document.querySelector('.placeholder');
p.src='/cgi-bin/video.sh?f='+f;
p.style.display='block';
ph.style.display='none';
p.load();
p.play();
var items=document.querySelectorAll('#recordings-list li');
items.forEach(function(i){i.classList.remove('active')});
event.target.closest('li').classList.add('active');
}
function loadRecordings(){
var list=document.getElementById('recordings-list');
var loading=document.querySelector('.loading');
loading.style.display='block';
list.innerHTML='';
fetch('/cgi-bin/list.sh')
.then(function(r){return r.json()})
.then(function(d){
loading.style.display='none';
if(d.files.length===0){
list.innerHTML='<li style="cursor:default;background:#333"><span class="rec-name">No recordings</span></li>';
return;
}
d.files.forEach(function(file){
var li=document.createElement('li');
li.onclick=function(){playVideo(file.name)};
var name=document.createElement('span');
name.className='rec-name';
name.textContent='🎬 '+file.name;
var date=document.createElement('span');
date.className='rec-date';
date.textContent='📅 '+file.date;
li.appendChild(name);
li.appendChild(date);
list.appendChild(li);
});
})
.catch(function(e){
loading.style.display='none';
showStatus('❌ Error: '+e,'error');
});
}
function doStart(){
var btn=document.getElementById('start');
btn.disabled=true;
btn.innerHTML='⏳ Starting...<span class="spinner"></span>';
showStatus('Starting recording system...','info');
fetch('/cgi-bin/start.sh').then(function(r){return r.text()})
.then(function(t){
showStatus('✅ '+t,'success');
btn.innerHTML='▶️ Start Record';
btn.disabled=false;
}).catch(function(e){
showStatus('❌ '+e,'error');
btn.innerHTML='▶️ Start Record';
btn.disabled=false;
});
}
function doStop(){
var btn=document.getElementById('stop');
btn.disabled=true;
btn.innerHTML='⏳ Stopping...<span class="spinner"></span>';
fetch('/cgi-bin/stop.sh').then(function(r){return r.text()})
.then(function(t){
btn.innerHTML='⏹️ Stop Record';
btn.disabled=false;
}).catch(function(e){
showStatus('❌ '+e,'error');
btn.innerHTML='⏹️ Stop Record';
btn.disabled=false;
});
}
function doShutdown(){
if(confirm('Shutdown entire NVR system?')){
var btn=document.getElementById('shutdown');
btn.disabled=true;
btn.innerHTML='🛑 Shutting Down...<span class="spinner"></span>';
showStatus('Shutting down system...','info');
fetch('/cgi-bin/shutdown.sh').then(function(){
showStatus('✅ System Shutdown','success');
setTimeout(function(){
document.body.innerHTML='<h1 style="color:#e74c3c;text-align:center">🛑 NVR System Shutdown</h1><p style="text-align:center;color:#999">All services stopped</p>';
},1000);
}).catch(function(){
document.body.innerHTML='<h1 style="color:#e74c3c;text-align:center">🛑 NVR System Shutdown</h1><p style="text-align:center;color:#999">All services stopped</p>';
});
}
}
window.onload=function(){loadRecordings()};
</script>
</body>
</html>
HTML

# --- CGI: List recordings with video metadata date ---
cat > "$CGIROOT/list.sh" << 'CGI_LIST'
#!/bin/sh
echo "Content-type: application/json"
echo ""
echo '{"files":['
FIRST=1
cd /mnt/mmcblk0p1/recordings
for f in *.mp4; do
  [ -f "$f" ] || continue

  # Get creation time from video metadata using ffprobe
  DATETIME=$(/mnt/mmcblk0p1/ffprobe-3.2 -v quiet -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null | head -1)

  # If no metadata, fallback to file modification time
  if [ -z "$DATETIME" ]; then
    DATETIME=$(stat -c %y "$f" 2>/dev/null | cut -d. -f1)
  else
    # Format: 2025-11-08T12:34:56.000000Z -> 2025-11-08 12:34:56
    DATETIME=$(echo "$DATETIME" | sed 's/T/ /;s/\..*//')
  fi

  [ $FIRST -eq 0 ] && echo ","
  echo -n "{\"name\":\"$f\",\"date\":\"$DATETIME\"}"
  FIRST=0
done
echo ']}'
CGI_LIST

# --- CGI: Stream video ---
cat > "$CGIROOT/video.sh" << 'CGI_VIDEO'
#!/bin/sh
F=$(echo "$QUERY_STRING" | sed 's/f=//')
VIDEO="/mnt/mmcblk0p1/recordings/$F"
[ -f "$VIDEO" ] || exit 1
echo "Content-type: video/mp4"
echo ""
dd if="$VIDEO" bs=8192 2>/dev/null
CGI_VIDEO

# --- CGI: Start recording ---
cat > "$CGIROOT/start.sh" << 'CGI_START'
#!/bin/sh
echo "Content-type: text/plain"
echo ""
/mnt/mmcblk0p1/startup.sh >/dev/null 2>&1 &
echo "Recording Started"
CGI_START

# --- CGI: Stop recording ---
cat > "$CGIROOT/stop.sh" << 'CGI_STOP'
#!/bin/sh
echo "Content-type: text/plain"
echo ""
/mnt/mmcblk0p1/endprocess.sh
echo "Recording Stopped"
CGI_STOP

# --- CGI: Shutdown system ---
cat > "$CGIROOT/shutdown.sh" << 'CGI_SHUTDOWN'
#!/bin/sh
echo "Content-type: text/plain"
echo ""
echo "Shutting down NVR system..."

cat > /tmp/shutdown_nvr.sh << 'SHUTDOWN'
#!/bin/sh
sleep 1
/mnt/mmcblk0p1/endprocess.sh >/dev/null 2>&1
HTTPDPIDS=$(ps | grep 'busybox httpd' | grep -v grep | awk '{print $1}')
for pid in $HTTPDPIDS; do
  kill -9 $pid 2>/dev/null
done
SHUTDOWN

chmod +x /tmp/shutdown_nvr.sh
nohup /tmp/shutdown_nvr.sh >/dev/null 2>&1 &
CGI_SHUTDOWN

chmod +x "$CGIROOT"/*.sh

echo "✅ Starting NVR server on port 8080..."
busybox httpd -p 8080 -h "$WWWROOT"
echo "✅ Server started! Access at http://192.168.1.10:8080"
