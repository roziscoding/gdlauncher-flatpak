#!/bin/bash
export TMPDIR="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID:-gg.gdl.GDLauncher}"
# render natively on Wayland when available (else X11), so the window shows even
# when launched without DISPLAY — e.g. from GNOME/launchers under --socket=fallback-x11
exec /app/lib/gdlauncher/@gddesktop --no-sandbox --ozone-platform-hint=auto "$@"
