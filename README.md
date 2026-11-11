# biscuit-scoop-bucket

<!-- HOOK: one line, yours -->

A personal Scoop bucket containing manifests for apps, tools, and
software that aren't available in the official Scoop buckets.

## Getting started

> [!IMPORTANT]
> This bucket needs Scoop itself. If `scoop` is not a command yet,
> install it first from a normal (non-administrator) PowerShell
> window, as [scoop.sh](https://scoop.sh) describes:
>
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
> ```

With Scoop installed, add this bucket under the name `biscuit`:

```powershell
scoop bucket add biscuit https://github.com/biscuitvixen/biscuit-scoop-bucket
```

The name is only a local alias, but every command below uses it.
Install an app with the bucket prefix, so Scoop cannot pick a
same-named manifest from another bucket:

```powershell
scoop install biscuit/slimevr
```

Updating takes two steps. `scoop update` refreshes the bucket
manifests; `scoop update <app>` (or `scoop update *`) then upgrades
the installed apps to the versions those manifests name.

```powershell
scoop update
scoop update slimevr
```

## Available apps

| App | Description | Licence |
| --- | --- | --- |
| [`apollo`](https://github.com/ClassicOldSong/Apollo) | Self-hosted desktop stream host (Sunshine fork) for Moonlight/Artemis | GPL-3.0 |
| [`aurora`](https://aurora-viewer.org/) | Modern Second Life viewer written in Rust, with a Vulkan renderer | GPL-3.0+ |
| [`firestorm`](https://www.firestormviewer.org/) | Stable releases of the Firestorm Second Life viewer | LGPL-2.1 |
| [`firestorm-beta`](https://www.firestormviewer.org/) | Latest beta versions of the Firestorm Second Life viewer | LGPL-2.1 |
| [`slimevr`](https://slimevr.dev/) | Desktop app for SlimeVR full-body trackers, with its bundled Java runtime | MIT or Apache-2.0 |
| [`vrc-get`](https://github.com/vrc-get/vrc-get) | Open-source command-line client for the VRChat Package Manager | MPL-2.0 |

Scoop prints each app's notes after it installs. Two are worth
knowing before installing: `slimevr` installs the server app only,
without the SteamVR driver or the USB serial drivers for trackers,
and both Firestorm manifests use the AVX2 build, which needs a CPU
from roughly 2013 or later.

## Automatic Updates

A [scheduled GitHub Action](.github/workflows/update-manifests.yml) runs Scoop's `checkver` every 6 hours and commits new versions to `main`. It can also be started by hand from the Actions tab.

Apollo, SlimeVR and vrc-get only pick up a stable release once it has been out for 7 days, so broken or pulled releases have time to surface first. Aurora has no cooldown, because Aurora can make an update mandatory. Firestorm stable follows the same 7-day cooldown, read from the version tags on Firestorm's GitHub repository because the project website blocks automated requests. Firestorm Beta has no cooldown, since Firestorm removes each beta installer from its download host as soon as the next one is published.
