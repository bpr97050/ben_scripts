# ben_scripts

A collection of administrative and deployment scripts for Windows and macOS.
The scripts are grouped by operating system and task; review each script before
running it, since several make system-wide changes.

## Repository layout

### PowerShell (`ps/`)

| Script | Purpose |
| --- | --- |
| [DCU BIOS/GPU detection](ps/DCU_UPDATE_BIOS_GPU_ONLY/DCU_UPDATE_BIOS_GPU_ONLY_DETECT.ps1) | Applies Dell Command \| Update BIOS, driver, and selected device-category updates with reboot enabled. |
| [DCU BIOS/GPU remediation](ps/DCU_UPDATE_BIOS_GPU_ONLY/DCU_UPDATE_BIOS_GPU_ONLY_REMEDIATION.ps1) | Applies the same Dell Command \| Update categories with reboot disabled. |
| [Dell SupportAssist removal](ps/dell_supportassist/remove_dell_supportassist.ps1) | Uninstalls Dell SupportAssist and its OS Recovery plugin when present. |
| [FileZilla detection](ps/filezilla/Detect_FileZilla_Version.ps1) | Compares the installed FileZilla version with the latest release. |
| [FileZilla installer](ps/filezilla/Install_FileZilla.ps1) | Downloads and silently installs the latest 64-bit FileZilla client. |
| [.NET cleanup](ps/net_cleanup/NET_Cleanup.ps1) | Removes selected .NET runtimes and Intel Graphics Command Center packages when detected. |
| [QuickBooks multi-user mode](ps/quickbooks/QuickBooks_Multiusermode.ps1) | Sets the current user's QuickBooks Enterprise 24.0 configuration to multi-user mode. |
| [Teams cleanup and install](ps/teams_removal/MicrosoftTeamsNEW.ps1) | Removes classic Teams components and installs new Teams using the bundled bootstrapper. |

### macOS shell scripts (`sh/macos/`)

| Script | Purpose |
| --- | --- |
| [Adobe Remote Update Manager](sh/macos/adobe_rum/rum_update.sh) | Runs Adobe Remote Update Manager to install available updates. |
| [Safari data cleanup](sh/macos/clear_safari_cookies/clear_safari_cookies.sh) | Removes Safari cookies, website data, caches, and preferences for the logged-in console user. |
| [Teams Classic removal](sh/macos/remove_teams_classic/remove_teams_classic.sh) | Removes the Teams Classic application and related files for the account running the script. |
| [Stale account cleanup](sh/macos/trim_stale_accounts/trim_stale_accounts.sh) | Deletes local accounts with no login in at least the configured number of days (30 by default). |

## Usage and safety

- These scripts are provided as standalone administrative examples; they are
  not packaged as a single application and may need environment-specific
  adjustments.
- Read the script and confirm its target paths, product versions, account
  exclusions, and reboot behavior before use.
- Run with the privileges required by the task. Elevated permissions may be
  required for software installation, uninstallation, registry or system
  changes, and account cleanup.
- Test changes on a suitable non-production machine before deploying them
  broadly. Destructive scripts can permanently remove files, application data,
  or user accounts.
- macOS scripts use macOS-specific utilities and paths and should be reviewed
  and run on macOS. PowerShell scripts target Windows and may depend on the
  listed product being installed.
- Check each script's comments and command-line options for its exact behavior;
  this README is a high-level index, not a substitute for reviewing the script.
