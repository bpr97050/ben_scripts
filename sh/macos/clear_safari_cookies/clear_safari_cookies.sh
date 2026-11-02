#!/bin/bash

# Clears Safari cookies, website storage, caches, and preferences for the
# currently logged-in console user. Requires sudo access.
current_user=$(stat -f%Su /dev/console)

sudo rm -rf "/Users/$current_user/Library/Cookies/"*
sudo rm -rf "/Users/$current_user/Library/Safari/LocalStorage/"*
sudo rm -rf "/Users/$current_user/Library/Safari/Databases/"*
sudo rm -rf "/Users/$current_user/Library/Caches/com.apple.Safari/"*
sudo rm -rf "/Users/$current_user/Library/Caches/com.apple.WebKit.PluginProcess/"*
sudo rm -rf "/Users/$current_user/Library/Preferences/com.apple.Safari.plist"
