#!/bin/bash

# Deletes local accounts with no login in at least the configured number of days.
# Run as root. This also permanently removes each deleted account's home directory.

# Number of inactive days required before an account is deleted.
THRESHOLD_DAYS=30
CURRENT_DATE=$(date +%s)
CURRENT_YEAR=$(date +%Y)

# List local accounts and skip system and service accounts below.
USERS=$(dscl . list /Users | grep -v '^_')

for USER in $USERS; do
    # Skip system accounts, root, AddigySSH, and our itadmin account
    if [[ "$USER" =~ ^_ ]] || [[ "$USER" == "itadmin" ]] || [[ "$USER" == "AddigySSH" ]] || [[ "$USER" == "nobody" ]] || [[ "$USER" == "daemon" ]] || [[ "$USER" == "root" ]]; then
        continue
    fi

    # Get last login record
    LAST_LINE=$(last "$USER" | head -n 1)

    if [[ -z "$LAST_LINE" ]]; then
        echo "User $USER has never logged in. Skipping."
        continue
    fi

    # Extract month, day, and time from the login record (typically columns 4-6).
    # Handles formats like:
    #   Dec  1 07:34
    #   Nov 29 09:55
    LOGIN_DATE=$(echo "$LAST_LINE" | awk '{print $4, $5, $6}')

    # If the date fields aren't valid, skip
    if ! [[ "$LOGIN_DATE" =~ ^[A-Za-z]{3}\ [0-9]{1,2}\ [0-9]{2}:[0-9]{2}$ ]]; then
        echo "Unrecognized date format for $USER: '$LOGIN_DATE'. Skipping."
        continue
    fi

    # Add current year
    LOGIN_DATE="$LOGIN_DATE $CURRENT_YEAR"

    # Convert the login date to Unix time (epoch).
    LOGIN_EPOCH=$(date -j -f "%b %d %H:%M %Y" "$LOGIN_DATE" +%s 2>/dev/null)

    if [[ -z "$LOGIN_EPOCH" ]]; then
        echo "Failed to convert login date for $USER: $LOGIN_DATE. Skipping."
        continue
    fi

    DIFF_DAYS=$(( (CURRENT_DATE - LOGIN_EPOCH) / 86400 ))

    if (( DIFF_DAYS >= THRESHOLD_DAYS )); then
        echo "User $USER inactive for $DIFF_DAYS days → will be deleted."
        sysadminctl -deleteUser "$USER"
        rm -rf "/Users/$USER"
    else
        echo "User $USER active. Last login $LOGIN_DATE ($DIFF_DAYS days ago)"
    fi
done
