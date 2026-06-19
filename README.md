# GDLauncher Flatpak

Flatpak package for [GDLauncher](https://gdlauncher.com) - a custom Minecraft launcher with built-in mod management, modpack support, and a modern interface.

## Install

Add the (unofficial) Flatpak repo once, then install — updates come through `flatpak update` or your software center:

```bash
flatpak remote-add --if-not-exists gdlauncher https://projects.rjmunhoz.me/gdlauncher-flatpak/gdlauncher.flatpakrepo
flatpak install gdlauncher gg.gdl.GDLauncher
```

> This is an unofficial repackaging of GDLauncher's upstream AppImage, not affiliated with Gorilla Devs. The repo is GPG-signed.

Alternatively, grab the `GDLauncher.flatpak` bundle from the [latest release](../../releases/latest) and `flatpak install ./GDLauncher.flatpak` (single install, no automatic updates).

## Building

```bash
flatpak-builder --force-clean build-dir gg.gdl.GDLauncher.yml
```

## Installing locally

```bash
flatpak-builder --user --install --force-clean build-dir gg.gdl.GDLauncher.yml
```

## Running

```bash
flatpak run gg.gdl.GDLauncher
```

## Updates

A scheduled job checks for new GDLauncher releases roughly every two weeks (the 1st and 15th of each month) and, when there's a new version, builds and publishes it automatically.

GDLauncher ships through its own CDN with no fixed release schedule, so this cadence is intentionally relaxed. **If a new GDLauncher version is out and this package hasn't picked it up yet, [open an issue](../../issues/new) and it'll be triggered manually** — the check can be run on demand at any time.
