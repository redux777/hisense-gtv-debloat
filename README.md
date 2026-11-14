# hisense-gtv-debloat

A dependency-free ADB debloater and performance optimizer for **Hisense Google TVs** (**U7K, U8K, U6K, U7N, U8N** / MediaTek Pentonic 700 `MT9689` / `hengshan` platform).

Out of the box, Hisense Google TVs run over **1.1 GB of background OEM telemetry, ACR screen-spying, VIDAA ad services, and preinstalled streaming daemons** on a system with only **2.43 GB of total physical RAM**—causing heavy lag, app reloads, and 6+ GB of cached ad bloat on `/data`.

`debloat.sh` removes up to **47 non-essential bloatware and spyware packages** (`pm uninstall -k --user 0`), optionally swaps the ad-heavy stock Google TV home screen (`launcherx`) for **[Projectivy Launcher](https://github.com/spocky/miproja1)**, sets `0.5x` UI animation scales, trims `/data` caches, and restarts `AtvRemoteService` so both the **Google Home app remote** and **Home Assistant** work without interruption.

---

## Measured Results (Hisense 100" U7K `100E75LUA`)

| Metric | Stock Before Debloat | After `debloat.sh --projectivy` | Improvement |
| :--- | :--- | :--- | :--- |
| **`/data` Storage Used** | `8.8 GB` (`50%` full) | `2.7 GB` (`16%` full) | **`-6.1 GB` reclaimed** (`15.0 GB` free) |
| **Background RAM Freed** | `~1.12 GB` pinned by bloat/ads | Freed for active media apps | **`~1.12 GB` (`46%` of total RAM) freed** |
| **Home Screen Launcher RAM** | `473 MB` (`launcherx` + `coreservices` + `setupwraith`) | `156 MB` (`Projectivy Launcher`) | **`-317 MB` net RAM saved** + zero home-screen ads |

---

## Quick Start

### 1. Enable ADB Debugging on Your Hisense Google TV
1. Open **Settings → System → About** and click **Android TV OS build** 7 times until *You are now a developer!* appears.
2. Go back to **Settings → System → Developer options** and enable **USB debugging** (also enables network ADB over TCP port `5555`).

### 2. Run `debloat.sh`

```bash
git clone https://github.com/redux777/hisense-gtv-debloat.git
cd hisense-gtv-debloat
chmod +x debloat.sh

# Full debloat (Tiers 1 + 2 + 3) + install Projectivy Launcher + 0.5x animations + cache trim:
./debloat.sh -s 192.168.1.104:5555 --projectivy
```

*(Accept the **"Allow USB debugging?"** prompt on the TV screen when connecting for the first time.)*

### Other Usage Modes

```bash
# Remove all 47 bloatware packages without replacing the stock Google TV launcher:
./debloat.sh -s 192.168.1.104:5555

# Only remove Tier 1 Hisense ACR spyware, telemetry & VIDAA bloat (keep Netflix, YouTube, Live TV, Google Assistant & AirPlay):
./debloat.sh -s 192.168.1.104:5555 --core-only

# Keep Google Assistant voice search (katniss) and Apple AirPlay while removing everything else:
./debloat.sh -s 192.168.1.104:5555 --keep-assistant-airplay

# Audit which bloatware packages are currently active (useful after a firmware update):
./debloat.sh -s 192.168.1.104:5555 --audit

# Restore all packages and re-enable the stock Google TV launcher:
./debloat.sh -s 192.168.1.104:5555 --restore
```

---

## Package Reference

### Tier 1: Hisense ACR (Screen Spying), Telemetry, VIDAA Adware & System Bloat (`30` Packages)
*(Always removed)*

| Package Name | APK Path | RAM / Impact | Description |
| :--- | :--- | :--- | :--- |
| `com.vt.tv.evservice` | `/system_ext/app/Vtp_ACR` | `81 MB` | **Hisense ACR (`ACRService`)**: Fingerprints on-screen video/HDMI content and reports viewing habits to Hisense/VIDAA ad servers. |
| `com.vt.tv.smartsense` | `/system_ext/app/Smartsense` | `108 MB` | **SmartSense (`LogReportManagerService`)**: Collects app usage/activity state and uploads telemetry logs. |
| `com.vt.tv.smartservice` | `/system_ext/app/SmartsenseService` | `102 MB` | **SmartSense Firebase Uploader**: Uploads device diagnostics and eMMC stats to Hisense Firebase storage. |
| `com.vt.tv.smartsense.ui` | `/system_ext/app/SmartsenseUI` | — | UI frontend for SmartSense telemetry prompts. |
| `com.vt.tv.ai_sense` | `/system_ext/app/Vtp_AiCamera` | `42 MB` | **AI Camera Daemon (`AiSenseService`)**: Runs continuously in the background even with no USB camera attached. |
| `com.google.android.feedback` | System | — | Google crash/telemetry feedback agent. |
| `com.vidaa.oemtabcontentprovider` | `/system_ext/app/Vtp_VtTab` | — | Injects Hisense/VIDAA promotional content rows into the launcher. |
| `net.vidaatv.hisense.android.tv` | `/system_ext/app/Vtp_VtChannel` | — | **VIDAA Free**: Ad-supported live streaming channels app. |
| `com.vt.storemode` | `/system_ext/app/Vtp_StoreMode` | — | Retail store demo loop and e-sticker overlay software. |
| `com.vt.tv.b2b` | `/system_ext/app/B2B` | — | Commercial/hotel hospitality mode management daemon. |
| `com.vt.hishow` | `/system_ext/app/Vtp_FamilyMoment` | — | Hisense "Family Moment" photo/cloud bloatware. |
| `com.vt.alexa` | `/system_ext/app/HiAlexa` | — | Hisense Amazon Alexa voice agent. |
| `com.vt.tv.aiot` | `/system_ext/app/Vtp_AIOT` | — | Hisense ConnectLife smart-appliance app (fridges/ACs). |
| `com.vt.tv.aiotprotocolapp` | `/system_ext/app/AIOT_ProtocolApp` | — | ConnectLife background protocol daemon. |
| `com.vt.tv.aiotsystemservice` | `/system_ext/app/AIOT_SystemService` | — | ConnectLife background system daemon. |
| `com.vt.tv.interactive` | `/system_ext/priv-app/Interactive` | `40 MB` | ATSC broadcast interactive popup/ad overlay service. |
| `tv.mopa.ginga` | `/product/app/MopaGinga` | — | Brazilian/South American DTV interactive broadcast middleware (`Ginga`). |
| `com.hisense.odinbrowser` | `/system_ext/app/Vtp_OdinBrowser` | — | Built-in Hisense Odin web browser. |
| `com.vt.fte` | `/system_ext/app/*` | — | First-time setup wizard stub. |
| `com.vt.tv.protector` | `/system_ext/app/DeviceAssistant` | — | Hisense "Device Assistant / RAM Cleaner" bloatware with usage-tracking permissions. |
| `com.vt.tv.customerlauncher` | `/system_ext/app/CustomerLauncher` | — | Unused secondary OEM launcher stub. |
| `com.vt.udpserver` | `/system_ext/app/Vtp_SyncPlayServer` | — | Multi-TV commercial video-wall UDP sync server. |
| `com.mediatek.dtv.tvinput.dvbtuner` | `/product/priv-app/DvbTvInputService` | — | Unused European DVB digital TV tuner driver. |
| `com.mediatek.dtv.tvinput.isdbtuner` | `/product/priv-app/IsdbTvInputService` | — | Unused South American/Japanese ISDB digital TV tuner driver. |
| `com.vt.tv.dlna` | `/system_ext/app/DLNA` | `48 MB` | Legacy UPnP/DLNA network discovery daemon. |
| `com.vt.tv.mobiledeviceconnectiontips` | `/system_ext/app/Miracast` | `33 MB` | Background Miracast connection tips daemon *(does not affect Chromecast)*. |
| `com.android.printspooler` | System | — | Android print spooler service. |
| `com.android.providers.calendar` | System | — | Android calendar storage provider. |
| `com.google.android.syncadapters.calendar` | System | — | Google calendar sync adapter. |
| `com.android.providers.contacts` | System | — | Android contacts storage provider. |

---

### Tier 2: Preinstalled Streaming Apps & Built-in USB/Media Apps (`12` Packages)
*(Removed by default; kept if you pass `--keep-streaming` or `--core-only`)*

| Package Name | RAM / Impact | Description |
| :--- | :--- | :--- |
| `com.netflix.ninja` | — | Preinstalled Netflix app. |
| `com.mstar.netflixobserver` | `57 MB` | Always-running background Netflix button/observer daemon. |
| `com.netflix.tokenmanager` | — | Netflix partner token service. |
| `com.google.android.youtube.tv` | `113 MB` | Official YouTube app *(runs `youtube.tv.recommendations` continuously in the background; safe to remove if using **SmartTube**)*. |
| `com.google.android.youtube.tvmusic` | — | YouTube Music. |
| `com.google.android.youtube.tvunplugged` | — | YouTube TV. |
| `com.amazon.amazonvideo.livingroom` | — | Amazon Prime Video. |
| `com.disney.disneyplus` | — | Disney+. |
| `com.roku.web.trc` | — | The Roku Channel. |
| `com.google.android.videos` | — | Google Play Movies & TV. |
| `com.google.android.play.games` | — | Google Play Games. |
| `com.vt.tv.mediacenter` | — | **USB Media Center**: Hisense USB thumb-drive file browser. |
| `com.vt.tv.singlelisten` | — | **BT Music**: Turns the TV into a Bluetooth speaker for a phone *(does **not** affect Bluetooth remotes or headphones)*. |

---

### Tier 3: Optional Heavy Background Daemons (`5` Packages)
*(Removed by default; kept if you pass `--keep-assistant-airplay` or `--core-only`)*

| Package Name | RAM / Impact | Description |
| :--- | :--- | :--- |
| `com.google.android.katniss` | `211 MB` | **Google Assistant Voice Daemon**: Runs two permanent background processes (`katniss:search` + `katniss:interactor`) listening for voice commands. |
| `com.mediatek.AirplayAPK` | — | MediaTek Apple AirPlay receiver app. |
| `com.mediatek.airplaydaemon` | — | MediaTek AirPlay background daemon. |
| `com.mediatek.partner.airplay_sys` | `64 MB` | MediaTek AirPlay system service *(does **not** affect Chromecast Built-in)*. |
| `com.vt.tv.airplaykeycheck` | — | Hisense AirPlay key verifier. |

---

### Core TV Packages Intentionally Preserved (Never Removed)

The following packages are essential to TV hardware, picture calibration, HDMI input routing, video surface renegotiation, audio, screensaver, and smart-home control and are **never** touched by `debloat.sh`:
- **Hardware & Picture Calibration**: `com.vt.tvservice`, `com.vt.avmiddleware`, `com.vt.tv.videocolor`, `com.vt.tv.aipq`, `com.vt.tv.calmanconnector`, `com.vt.roomcalibration` *(Preserves Local Dimming, SDR/HDR10/Dolby Vision picture modes, 20-point white balance, CMS, and motion controls)*
- **HDMI Inputs, TIF Video Pipeline & OSD**: `com.vt.tv.tvcenter`, `com.vt.tvplayer`, `com.vt.source.tuner`, `com.vt.source.external`, `com.vt.tv.input`, `com.vt.tv.commonui`, `com.vt.eula` *(Load-bearing for Android TV Input Framework (`TIF`). Preserves HDMI 1–4 video plane binding, remote input switcher menu, eARC, CEC, ALLM/VRR/144Hz Game Mode renegotiation, and prevents screen blackouts when opening console overlays like the Xbox Guide)*
- **Audio**: `com.dolby.android.audio.service` *(Dolby Atmos / Dolby Audio processing and eARC passthrough)*
- **Google Photos Screensaver (Ambient Mode)**: `com.google.android.apps.tv.dreamx` *(Backdrop / Google Photos slideshow screensaver)*
- **Chromecast & Remote Control**: `com.google.android.apps.mediashell` *(Chromecast Built-in)* and `com.google.android.tv.remote.service` *(Google Home app virtual remote + Home Assistant `androidtv_remote` integration)*
- **Firmware Updates**: `com.vt.tv.ota`, `com.vt.remoteupgrade`, `com.vt.tv.usbota`

---

## Troubleshooting & Tips

### Remote Input Switcher & Xbox Guide Black Screen
- **Symptom**: Pressing the physical Input button brings up the menu, but selecting inputs does nothing. In Xbox/consoles, pressing the Xbox button or opening the guide causes the screen to go black until reboot.
- **Cause**: Hisense MediaTek firmware routes all TV Input Framework (`TIF`) video surfaces through `com.vt.tv.tvcenter` and `com.vt.tvplayer`. If either is uninstalled, the remote input switcher cannot bind the hardware video plane, and dynamic refresh rate/ALLM mode switches (triggered by the Xbox Guide) cause the hardware video pipeline to drop the surface and hang (`EGL_BAD_SURFACE`).
- **Fix**: These packages are permanently preserved in `debloat.sh`. If you previously ran an older debloat script, restore them via:
  ```bash
  adb shell "cmd package install-existing com.vt.tv.tvcenter"
  adb shell "cmd package install-existing com.vt.tvplayer"
  adb shell "cmd package install-existing com.vt.source.tuner"
  adb shell "cmd package install-existing com.vt.eula"
  adb reboot
  ```

### Google Photos Screensaver (Ambient Mode) Album Selection
- **Symptom**: Ambient Mode works and displays art gallery / internet photos, but clicking "Google Photos" on the TV to pick specific albums does not work or fails to open.
- **Cause**: The on-device album picker dialog relies on Google TV launcher components (`launcherx` / `setupwraith`), which are disabled when using Projectivy Launcher (`--projectivy`).
- **Solution**: Configure your Google Photos albums using the **Google Home mobile app** on your phone (iOS or Android):
  1. Open the **Google Home app** on your phone.
  2. Tap your TV device → **Settings** (gear icon) → **Ambient mode**.
  3. Select **Google Photos** and choose the albums you want displayed.
  4. Ambient Mode (`dreamx`) syncs your album selection directly from your Google cloud profile without needing `launcherx` active on the TV.
