# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flatpak package for [GDLauncher](https://gdlauncher.com) (a proprietary Minecraft launcher). This repo contains **no application source code** — it repackages GDLauncher's upstream AppImage into a Flatpak. All work here is about the manifest, desktop integration metadata, and CI/release plumbing.

## Commands

```bash
# Build
flatpak-builder --force-clean build-dir gg.gdl.GDLauncher.yml

# Build + install for the current user (test locally)
flatpak-builder --user --install --force-clean build-dir gg.gdl.GDLauncher.yml

# Run
flatpak run gg.gdl.GDLauncher

# Validate metadata (recommended before committing changes to these files)
appstreamcli validate gg.gdl.GDLauncher.metainfo.xml
desktop-file-validate gg.gdl.GDLauncher.desktop
```

There is no test suite or linter; validity is verified by the Flatpak build succeeding (CI runs it).

## Architecture / how the package is assembled

The build (`gg.gdl.GDLauncher.yml`, `buildsystem: simple`) does the following:

1. Downloads the upstream `GDLauncher.AppImage` (a pinned `url` + `sha256` in the manifest sources).
2. Extracts it with `--appimage-extract` and copies `squashfs-root/*` into `/app/lib/gdlauncher/`.
3. Strips setuid bits (`chmod -R a-s`) — required for Flatpak.
4. Installs `gdlauncher.sh` as the `/app/bin/gdlauncher` launcher (the manifest `command`).
5. Installs the `.desktop`, `.metainfo.xml`, and pre-generated PNG icons (16–512px) from `icons/`.

Key cross-file relationships:
- `gdlauncher.sh` execs `/app/lib/gdlauncher/@gddesktop --no-sandbox --ozone-platform-hint=auto` (the `@gddesktop` binary name comes from the extracted AppImage) and sets `TMPDIR` into the per-app runtime dir. Electron under Flatpak needs `--no-sandbox`. The `--ozone-platform-hint=auto` is required alongside `--socket=fallback-x11`: launchers (GNOME, etc.) start the app without `DISPLAY`, so Electron must render natively on Wayland or the window never appears.
- The app-id `gg.gdl.GDLauncher` is the contract tying together the manifest, `.desktop` `Icon=`, metainfo `<id>`, and installed icon/desktop filenames — they must stay in sync.
- `.desktop` registers URL scheme handlers (`gdlauncher`, `curseforge`, `modrinth`) for deep links; `StartupWMClass=GDLauncher` must match the app's window class.
- The metainfo `<release>` list and the manifest's pinned AppImage version should be updated together when bumping GDLauncher.

### Updating GDLauncher's version

When GDLauncher ships a new release, run:

```bash
mise run update          # --force to re-apply the current version
```

This task (`.mise/tasks/update`) reads upstream's `latest-linux.yml`, and if there's a newer version it patches `url` + `sha256` in the manifest, downloads the AppImage to compute the checksum, and prepends a `<release>` entry to the metainfo. It then commits those two files (`feat: update GDLauncher to <version>`) and creates a local git tag named after the GDLauncher version (e.g. `2.0.31`). It is idempotent (skips the commit when nothing changed, never recreates an existing tag) and **never pushes** — review, then validate/build and `git push` yourself (it prints the exact commands).

Note: the version tag (`2.0.31`) is separate from semantic-release's package tags (`v1.0.0`), which CI creates on push.

The manifest source also carries an `x-checker-data` block pointing at the same `latest-linux.yml`, so [Flatpak External Data Checker](https://github.com/flathub/flatpak-external-data-checker) can bump `url`/`sha256` automatically as an alternative.

To update by hand: change `url` + `sha256` in `gg.gdl.GDLauncher.yml` **and** add a `<release>` entry to `gg.gdl.GDLauncher.metainfo.xml` (the two must move together).

### Icons

Icons are committed pre-generated in `icons/` (one PNG per size) rather than generated at build time — `appstreamcli compose` needs them present. Flatpak's max icon size is 512×512; do not add larger sizes.

## CI / Releases

Two workflows, no semantic-release (the version comes straight from the GDLauncher tag):

- **`.github/workflows/check-update.yml`** — runs on a schedule (06:00 UTC on the 1st & 15th, ≈ fortnightly) and via manual `workflow_dispatch`. It runs the `update` task (`bash .mise/tasks/update`); if a new version was applied, it pushes the commit + tag to the default branch and calls the release workflow. The manual trigger is the on-demand path when GDLauncher ships between scheduled checks.
- **`.github/workflows/release.yml`** — does everything build/publish in one workflow. Its single `build` job (in the freedesktop 24.08 container) builds a **GPG-signed OSTree repo** (`flatpak-builder --repo` + `build-update-repo --gpg-sign`), then derives the single-file bundle from that same repo (`flatpak build-bundle`) — so the repo and the bundle come from one build. Downloads + build state are cached via `actions/cache` on `.flatpak-builder`. Then:
  - **`release`** job — on a tag push or `workflow_call` with a `tag` (skipped on PR / manual dispatch), creates/updates the GitHub Release `GDLauncher <tag>` with the bundle attached.
  - **`deploy-pages`** job — on tag / `workflow_call` / `workflow_dispatch` (not PRs), deploys the signed OSTree repo (plus generated `.flatpakrepo`) to GitHub Pages, so it's installable as a Flatpak remote with in-place updates. The `.flatpakrepo` `Url` is derived from the live Pages URL (handles the custom domain).
  - `pull_request` builds only; `workflow_dispatch` rebuilds + redeploys the Pages repo without cutting a release (manual re-seed).

`check-update.yml` invokes `release.yml` via `workflow_call` (job-level `uses:`, with `secrets: inherit` so the GPG signing key reaches it) rather than letting the pushed tag trigger it — a tag pushed with `GITHUB_TOKEN` would not start another workflow, so calling it directly keeps everything in one run with no PAT needed. The signing key lives in the `FLATPAK_GPG_PRIVATE_KEY` secret. GDLauncher publishes through its own CDN with no public release schedule, which is why the cadence is relaxed and a manual trigger exists.
