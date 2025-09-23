# biscuit-scoop-bucket
A personal Scoop bucket containing manifests for apps, tools, and software that aren't available in the official Scoop buckets.

## Available Apps

- **Apollo**: Self-hosted desktop stream host (Sunshine fork) for Moonlight/Artemis
- **Firestorm Beta**: Latest beta versions of the Firestorm Second Life viewer

## Helper Scripts

The [`helpers/`](helpers/) directory contains maintenance scripts for updating manifests:

- **Firestorm Beta Updater**: Automatically downloads and updates the Firestorm beta manifest with new versions and hashes
  ```powershell
  .\helpers\update-firestorm.bat 7.2.1.78900
  ```

See [`helpers/README.md`](helpers/README.md) for detailed usage instructions.biscuit-scoop-bucket
