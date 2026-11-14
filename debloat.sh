#!/usr/bin/env bash
# ==============================================================================
# hisense-gtv-debloat — ADB Debloater & Optimizer for Hisense Google TV (U7K/U8K/U6K)
# Tested on: Hisense 100" U7K (100E75LUA / ATV001100233U7K, board hengshan, MT9689)
# ==============================================================================

set -euo pipefail

# Tier 1: Hisense ACR (Screen Spying), Telemetry, VIDAA Adware, Store/Hotel Mode & Regional Bloat (30 packages)
CORE_BLOAT_PACKAGES=(
  # 1. Hisense ACR (Automatic Content Recognition), Telemetry & Log Uploaders
  "com.vt.tv.evservice"                     # Vtp_ACR: ACRService screen-fingerprinting & viewing habit tracker
  "com.vt.tv.smartsense"                    # Smartsense: LogReportManagerService & activity telemetry
  "com.vt.tv.smartservice"                  # SmartsenseService: Firebase log & eMMC telemetry uploader
  "com.vt.tv.smartsense.ui"                 # SmartsenseUI: Telemetry UI prompts
  "com.vt.tv.ai_sense"                      # Vtp_AiCamera: Background USB AI camera/gesture recognition daemon
  "com.google.android.feedback"             # Google crash/telemetry feedback agent

  # 2. VIDAA Promotional Tabs, Retail Demo Mode, Hotel Mode & OEM Bloat
  "com.vidaa.oemtabcontentprovider"         # Vtp_VtTab: Injects Hisense/VIDAA promotional rows into launcher
  "net.vidaatv.hisense.android.tv"          # Vtp_VtChannel: VIDAA Free ad-supported live channels
  "com.vt.storemode"                        # Vtp_StoreMode: Retail store demo loop & e-sticker overlay
  "com.vt.tv.b2b"                           # B2B: Commercial/hotel hospitality mode daemon
  "com.vt.hishow"                           # Vtp_FamilyMoment: Hisense Family Moment cloud photo bloat
  "com.vt.alexa"                            # HiAlexa: Hisense Amazon Alexa voice agent
  "com.vt.tv.aiot"                          # Vtp_AIOT: Hisense ConnectLife smart-appliance app
  "com.vt.tv.aiotprotocolapp"               # AIOT_ProtocolApp: ConnectLife background protocol daemon
  "com.vt.tv.aiotsystemservice"             # AIOT_SystemService: ConnectLife background system daemon
  "com.vt.tv.interactive"                   # Interactive: ATSC broadcast interactive popup/ad service
  "tv.mopa.ginga"                           # MopaGinga: Brazilian/South American DTV interactive middleware
  "com.hisense.odinbrowser"                 # Vtp_OdinBrowser: Built-in Hisense Odin web browser
  "com.vt.fte"                              # First-time setup wizard stub
  "com.vt.tv.protector"                     # DeviceAssistant: Hisense RAM/cache "cleaner" bloatware
  "com.vt.tv.customerlauncher"              # CustomerLauncher: Unused secondary OEM launcher stub
  "com.vt.udpserver"                        # Vtp_SyncPlayServer: Multi-TV commercial video-wall UDP sync server

  # 3. Unused Regional DTV Tuners & Phone/Tablet Sync Providers
  "com.mediatek.dtv.tvinput.dvbtuner"       # European DVB digital tuner service
  "com.mediatek.dtv.tvinput.isdbtuner"      # South American/Japanese ISDB digital tuner service
  "com.vt.tv.dlna"                          # Legacy UPnP/DLNA background discovery daemon
  "com.vt.tv.mobiledeviceconnectiontips"    # Miracast connection tips background daemon
  "com.android.printspooler"                # Android print spooler (unused on TVs)
  "com.android.providers.calendar"          # Android calendar storage provider
  "com.google.android.syncadapters.calendar"# Google calendar sync adapter
  "com.android.providers.contacts"          # Android contacts storage provider
)

# Tier 2: Preinstalled Streaming Apps & Unused Built-in Media Apps (12 packages)
STREAMING_AND_MEDIA_PACKAGES=(
  # Preinstalled Commercial Streaming Apps
  "com.netflix.ninja"                       # Netflix app
  "com.mstar.netflixobserver"               # Netflix background observer daemon (57 MB RAM)
  "com.netflix.tokenmanager"                # Netflix partner token daemon
  "com.google.android.youtube.tv"           # Official YouTube TV app (runs 113 MB background recommendations daemon)
  "com.google.android.youtube.tvmusic"      # YouTube Music
  "com.google.android.youtube.tvunplugged"  # YouTube TV
  "com.amazon.amazonvideo.livingroom"       # Amazon Prime Video
  "com.disney.disneyplus"                   # Disney+
  "com.roku.web.trc"                        # The Roku Channel
  "com.google.android.videos"               # Google Play Movies & TV
  "com.google.android.play.games"           # Google Play Games

  # Built-in USB Media Center & BT Speaker App
  "com.vt.tv.mediacenter"                   # MediaCenter: Built-in USB thumb-drive file browser
  "com.vt.tv.singlelisten"                  # MyMusic: "BT Music" phone-to-TV speaker app (does NOT affect BT remotes/headphones)
)

# Tier 3: Optional Heavy Background Daemons (Google Assistant Voice Search & Apple AirPlay)
EXTRA_RAM_PACKAGES=(
  "com.google.android.katniss"              # Google Assistant voice search daemon (~211 MB RAM across 2 processes)
  "com.mediatek.AirplayAPK"                 # MediaTek Apple AirPlay receiver app
  "com.mediatek.airplaydaemon"              # MediaTek AirPlay daemon
  "com.mediatek.partner.airplay_sys"        # MediaTek AirPlay system service (~64 MB RAM)
  "com.vt.tv.airplaykeycheck"               # Hisense AirPlay key verifier
)

ADB_BIN="${ADB_BIN:-adb}"
SERIAL=""
USER_ID="0"
MODE="remove"                 # remove | restore | audit
INCLUDE_STREAMING=1           # 1 = remove preinstalled streaming & coax/USB apps; 0 = keep them
REMOVE_ASSISTANT_AIRPLAY=1    # 1 = also remove katniss & AirPlay daemons; 0 = keep them
INSTALL_PROJECTIVY=0          # 1 = download & install Projectivy Launcher and disable stock Google TV launcherx
TRIM_CACHES=1                 # 1 = run pm trim-caches and 0.5x animation scale tweak
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  ./debloat.sh [options]

Options:
  -s, --serial <ip:port|serial>   Target TV ADB address (e.g., 192.168.1.104:5555)
  -u, --user <id>                 Android user ID (default: 0)
  --core-only                     Only remove Tier 1 Hisense ACR/telemetry/VIDAA bloat (keep Netflix/YouTube/Live TV/Assistant/AirPlay)
  --keep-streaming                Keep preinstalled streaming & Live TV apps (Tier 2)
  --keep-assistant-airplay        Keep Google Assistant voice search (katniss) & Apple AirPlay daemons (Tier 3)
  --projectivy                    Download & install Projectivy Launcher (spocky/miproja1), set as default Home, and disable stock Google TV ad launcher (launcherx)
  --no-trim                       Skip trimming /data caches and setting 0.5x UI animation scales
  --audit                         Audit which bloatware packages are currently active without modifying anything
  --restore                       Restore all removed packages and re-enable stock Google TV launcher
  --dry-run                       Print ADB commands without executing them
  -h, --help                      Show this help message

Examples:
  # Full debloat (Tiers 1 + 2 + 3), 0.5x animations, cache trim, and Projectivy Launcher install:
  ./debloat.sh -s 192.168.1.104:5555 --projectivy

  # Remove only Hisense ACR spyware, telemetry, and VIDAA bloat (keep streaming apps, Assistant & AirPlay):
  ./debloat.sh -s 192.168.1.104:5555 --core-only

  # Audit current bloatware status:
  ./debloat.sh -s 192.168.1.104:5555 --audit

  # Restore everything back to factory stock:
  ./debloat.sh -s 192.168.1.104:5555 --restore
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      SERIAL="$2"
      shift 2
      ;;
    -u|--user)
      USER_ID="$2"
      shift 2
      ;;
    --core-only)
      INCLUDE_STREAMING=0
      REMOVE_ASSISTANT_AIRPLAY=0
      shift
      ;;
    --keep-streaming)
      INCLUDE_STREAMING=0
      shift
      ;;
    --keep-assistant-airplay)
      REMOVE_ASSISTANT_AIRPLAY=0
      shift
      ;;
    --projectivy)
      INSTALL_PROJECTIVY=1
      shift
      ;;
    --no-trim)
      TRIM_CACHES=0
      shift
      ;;
    --audit)
      MODE="audit"
      shift
      ;;
    --restore)
      MODE="restore"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
  echo "Error: '$ADB_BIN' not found in PATH. Install Android platform-tools or set ADB_BIN=/path/to/adb." >&2
  exit 1
fi

ADB_ARGS=()
if [[ -n "$SERIAL" ]]; then
  if [[ "$SERIAL" == *:* ]]; then
    "$ADB_BIN" connect "$SERIAL" >/dev/null
  fi
  ADB_ARGS=(-s "$SERIAL")
fi

MODEL="$("$ADB_BIN" "${ADB_ARGS[@]}" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
BOARD="$("$ADB_BIN" "${ADB_ARGS[@]}" shell getprop ro.product.board 2>/dev/null | tr -d '\r')"
ANDROID_VER="$("$ADB_BIN" "${ADB_ARGS[@]}" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
echo "==> Connected to TV: ${MODEL:-Unknown} (board: ${BOARD:-unknown}, Android ${ANDROID_VER:-Unknown}, user $USER_ID)"

PACKAGES=("${CORE_BLOAT_PACKAGES[@]}")
if [[ "$INCLUDE_STREAMING" -eq 1 ]]; then
  PACKAGES+=("${STREAMING_AND_MEDIA_PACKAGES[@]}")
fi
if [[ "$REMOVE_ASSISTANT_AIRPLAY" -eq 1 ]]; then
  PACKAGES+=("${EXTRA_RAM_PACKAGES[@]}")
fi

INSTALLED_LIST="$("$ADB_BIN" "${ADB_ARGS[@]}" shell pm list packages --user "$USER_ID" | tr -d '\r')"

if [[ "$MODE" == "audit" ]]; then
  echo "==> Auditing ${#PACKAGES[@]} bloatware packages for user $USER_ID:"
  ACTIVE_COUNT=0
  for pkg in "${PACKAGES[@]}"; do
    if grep -qx "package:${pkg}" <<<"$INSTALLED_LIST"; then
      printf "  [INSTALLED] %s\n" "$pkg"
      ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
    else
      printf "  [CLEAN]     %s\n" "$pkg"
    fi
  done
  echo "==> Audit complete: $ACTIVE_COUNT / ${#PACKAGES[@]} bloatware packages currently active."
  exit 0
fi

if [[ "$MODE" == "restore" ]]; then
  echo "==> Restoring ${#PACKAGES[@]} packages and stock Google TV launcher for user $USER_ID..."
  for pkg in "${PACKAGES[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] $ADB_BIN ${ADB_ARGS[*]} shell cmd package install-existing --user $USER_ID $pkg"
    else
      OUT="$("$ADB_BIN" "${ADB_ARGS[@]}" shell cmd package install-existing --user "$USER_ID" "$pkg" 2>&1 | tr -d '\r')"
      printf "  %-42s %s\n" "$pkg" "$OUT"
    fi
  done
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$ADB_BIN" "${ADB_ARGS[@]}" shell pm enable --user "$USER_ID" com.google.android.apps.tv.launcherx || true
    "$ADB_BIN" "${ADB_ARGS[@]}" shell pm enable --user "$USER_ID" com.google.android.tungsten.setupwraith || true
    "$ADB_BIN" "${ADB_ARGS[@]}" shell settings put global window_animation_scale 1.0
    "$ADB_BIN" "${ADB_ARGS[@]}" shell settings put global transition_animation_scale 1.0
    "$ADB_BIN" "${ADB_ARGS[@]}" shell settings put global animator_duration_scale 1.0
  fi
  echo "==> Restore complete."
  exit 0
fi

echo "==> Removing ${#PACKAGES[@]} bloatware packages for user $USER_ID..."
REMOVED=0
SKIPPED=0
for pkg in "${PACKAGES[@]}"; do
  if ! grep -qx "package:${pkg}" <<<"$INSTALLED_LIST"; then
    printf "  %-42s [already removed]\n" "$pkg"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $ADB_BIN ${ADB_ARGS[*]} shell pm uninstall -k --user $USER_ID $pkg"
    REMOVED=$((REMOVED + 1))
  else
    OUT="$("$ADB_BIN" "${ADB_ARGS[@]}" shell pm uninstall -k --user "$USER_ID" "$pkg" 2>&1 | tr -d '\r')"
    printf "  %-42s %s\n" "$pkg" "$OUT"
    if [[ "$OUT" == *"Success"* ]]; then
      REMOVED=$((REMOVED + 1))
      "$ADB_BIN" "${ADB_ARGS[@]}" shell am force-stop "$pkg" 2>/dev/null || true
    fi
  fi
done

if [[ "$INSTALL_PROJECTIVY" -eq 1 ]]; then
  echo "==> Installing Projectivy Launcher and disabling stock Google TV ad launcher (launcherx)..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Download latest spocky/miproja1 APK, adb install -r, set-home-activity, disable launcherx"
  else
    APK_URL="$(curl -sL "https://api.github.com/repos/spocky/miproja1/releases/latest" | grep -oE 'https://[^"]+release\.apk' | head -n 1)"
    if [[ -z "$APK_URL" ]]; then
      APK_URL="https://github.com/spocky/miproja1/releases/download/4.73/ProjectivyLauncher-4.73-c98-xda-release.apk"
    fi
    TMP_APK="$(mktemp /tmp/projectivy.XXXXXX.apk)"
    echo "    Downloading $APK_URL ..."
    curl -sL -o "$TMP_APK" "$APK_URL"
    "$ADB_BIN" "${ADB_ARGS[@]}" install -r "$TMP_APK"
    rm -f "$TMP_APK"

    # Preserve existing accessibility services while adding ProjectivyAccessibilityService
    EXISTING_ACC="$("$ADB_BIN" "${ADB_ARGS[@]}" shell settings get secure enabled_accessibility_services | tr -d '\r')"
    PROJ_ACC="com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService"
    if [[ -z "$EXISTING_ACC" || "$EXISTING_ACC" == "null" ]]; then
      NEW_ACC="$PROJ_ACC"
    elif [[ "$EXISTING_ACC" != *"$PROJ_ACC"* ]]; then
      NEW_ACC="${EXISTING_ACC}:${PROJ_ACC}"
    else
      NEW_ACC="$EXISTING_ACC"
    fi
    "$ADB_BIN" "${ADB_ARGS[@]}" shell "
      settings put secure enabled_accessibility_services \"$NEW_ACC\"
      settings put secure accessibility_enabled 1
      cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity
      pm disable-user --user $USER_ID com.google.android.apps.tv.launcherx
      pm disable-user --user $USER_ID com.google.android.tungsten.setupwraith
      am force-stop com.google.android.apps.tv.launcherx
      am force-stop com.google.android.tungsten.setupwraith
      am start -n com.spocky.projengmenu/.ui.home.MainActivity
    "
  fi
fi

if [[ "$TRIM_CACHES" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  echo "==> Applying 0.5x UI animation scales, trimming /data caches, and restarting Android TV Remote Service..."
  "$ADB_BIN" "${ADB_ARGS[@]}" shell "
    settings put global window_animation_scale 0.5
    settings put global transition_animation_scale 0.5
    settings put global animator_duration_scale 0.5
    pm trim-caches 999999999999999999
    am force-stop com.google.android.tv.remote.service
    am start-foreground-service -n com.google.android.tv.remote.service/.AtvRemoteService 2>/dev/null || am startservice -n com.google.android.tv.remote.service/.AtvRemoteService 2>/dev/null || true
  "
fi

echo "==> Done! Removed: $REMOVED | Already clean: $SKIPPED | Total checked: ${#PACKAGES[@]}"
