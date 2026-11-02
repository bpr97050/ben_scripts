#!/bin/bash

# Removes the system-wide Teams Classic app and its preferences, caches, and logs
# for the account running this script.

# Quit Teams Classic if it's running.
if pgrep Microsoft\ Teams\ Classic.app; then
    killall "Microsoft Teams Classic.app"
fi

# Remove the app and per-user support files.
rm -rf "/Applications/Microsoft Teams Classic.app"
rm -rf "$HOME/Library/Preferences/com.microsoft.teamsclassic.plist"
rm -rf "$HOME/Library/Caches/com.microsoft.teamsclassic"
rm -rf "$HOME/Library/Logs/com.microsoft.teamsclassic"
