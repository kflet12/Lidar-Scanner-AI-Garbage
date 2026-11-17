# LiDAR Scan

SwiftUI + ARKit LiDAR scanner. Scans a live mesh, exports OBJ / PLY via the share sheet
(AirDrop, Files, etc.). Needs a LiDAR iPhone (12 Pro or newer Pro) on iOS 16+.

## Build + install (no App Store, no Mac)
1. Create a GitHub repo, push this folder to `main`.
2. Actions tab → "Build IPA" runs automatically (or run it manually).
3. Download the `LiDARScan-ipa` artifact → unzip → `LiDARScan.ipa`.
   (Push a tag like `v1.0` to get it as a Release asset instead.)
4. Install the unsigned IPA with a sideloader that signs with your Apple ID:
   Sideloadly (Windows/Mac), AltStore, or SideStore.
   Free Apple ID = app expires every 7 days; re-sign to refresh.

## Use
Start → walk slowly around the object (0.5–3 m) → Stop → Export.
Files also land in Files app → On My iPhone → LiDAR Scan.
