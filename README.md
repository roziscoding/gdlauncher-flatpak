# GDLauncher Flatpak

Flatpak package for [GDLauncher](https://gdlauncher.com) - a custom Minecraft launcher with built-in mod management, modpack support, and a modern interface.

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
