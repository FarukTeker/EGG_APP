#!/bin/bash
# Launch the Vapor backend inside WSL Ubuntu.
# Swift 6.0.3 toolchain lives under /usr/local/usr (not on PATH by default).
export PATH=/usr/local/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /mnt/c/Codes/318yumurta/app/EGG_APP/Backend || exit 1
pkill -f "App serve" 2>/dev/null
exec swift run App serve --hostname 0.0.0.0 --port 8080
