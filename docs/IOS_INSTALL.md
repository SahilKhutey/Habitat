# Habitat iOS Installation & TestFlight Guide

## Prerequisites
- iPhone running iOS 16.0 or higher
- Apple TestFlight app installed

## Distribution Methods
1. **Apple TestFlight (Recommended):**
   - Accept the external beta invitation link.
   - Install Habitat directly via TestFlight.
2. **Direct Xcode / Ad-Hoc (`.ipa`):**
   - Connect iPhone to macOS.
   - Open `apps/mobile/ios/Runner.xcworkspace` in Xcode.
   - Select destination device $\to$ Product $\to$ Run / Archive.

## Airplane-Mode Validation
1. Enable **Airplane Mode** (Wi-Fi and Cellular OFF).
2. Launch **Habitat** $\to$ Schedule reminder $\to$ Lock device.
3. Verify local notification delivery $\to$ Capture proof $\to$ Confirm completion.
