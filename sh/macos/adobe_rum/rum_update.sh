#!/bin/zsh --no-rcs

# Updates Adobe apps that are installed without their base versions by running
# Adobe Remote Update Manager. Requires the manager to be installed and sudo access.
# Adobe documentation:
# https://helpx.adobe.com/enterprise/package/help/apps-deployed-without-their-base-versions.html

echo "Starting Adobe RemoteUpdateManger..."
sudo /usr/local/bin/RemoteUpdateManager --action=install
