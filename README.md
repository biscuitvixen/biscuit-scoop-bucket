# biscuit-scoop-bucket
A personal Scoop bucket containing manifests for apps, tools, and software that aren't available in the official Scoop buckets.

## Available Apps

- **Apollo**: Self-hosted desktop stream host (Sunshine fork) for Moonlight/Artemis
- **Firestorm Beta**: Latest beta versions of the Firestorm Second Life viewer
- **Aurora**: Modern Second Life viewer written in Rust, with a Vulkan renderer
- **Firestorm**: Stable releases of the Firestorm Second Life viewer
- **SlimeVR**: Desktop app for SlimeVR full-body trackers, with its bundled Java runtime
- **vrc-get**: Open-source command-line client for the VRChat Package Manager

## Automatic Updates

A [scheduled GitHub Action](.github/workflows/update-manifests.yml) runs Scoop's `checkver` every 6 hours and commits new versions to `main`. It can also be started by hand from the Actions tab.

Apollo, SlimeVR and vrc-get only pick up a stable release once it has been out for 7 days, so broken or pulled releases have time to surface first. Aurora has no cooldown, because Aurora can make an update mandatory. Both Firestorm manifests are updated by hand.

## Helper Scripts

The [`helpers/`](helpers/) directory contains maintenance scripts for updating manifests:

- **Firestorm Beta Updater**: Automatically downloads and updates the Firestorm beta manifest with new versions and hashes
  ```powershell
  .\helpers\update-firestorm.bat 7.2.1.78900
  ```

See [`helpers/README.md`](helpers/README.md) for detailed usage instructions.biscuit-scoop-bucket
