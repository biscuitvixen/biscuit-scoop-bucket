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

Apollo, SlimeVR and vrc-get only pick up a stable release once it has been out for 7 days, so broken or pulled releases have time to surface first. Aurora has no cooldown, because Aurora can make an update mandatory. Firestorm stable follows the same 7-day cooldown, read from the version tags on Firestorm's GitHub repository because the project website blocks automated requests. Firestorm Beta has no cooldown, since Firestorm removes each beta installer from its download host as soon as the next one is published.

