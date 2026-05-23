#!/bin/bash
export TMPDIR="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID:-gg.gdl.GDLauncher}"
exec /app/lib/gdlauncher/@gddesktop --no-sandbox "$@"
