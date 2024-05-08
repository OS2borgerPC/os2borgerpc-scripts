# OS2borgerPC: Scripts

This repository contains scripts designed to be used with OS2borgerPC and/or OS2borgerPC Kiosk.

The top level categories are as follows:

| Category          | Description                                                                |
| ------------------| ---------------------------------------------------------------------------|
| common            | Scripts that work on both OS2borgerPC and OS2borgerPC Kiosk                |
| os2borgerpc       | Scripts that only work on OS2BorgerPC                                      |
| os2borgerpc_kiosk | Scripts that only work on OS2BorgerPC Kiosk                                |
| tools             | Assorted scripts used for debugging / development                          |

Below `common` we have the following categories


| Category          | Description                                                                               |
| ------------------| ------------------------------------------------------------------------------------------|
| hooks             | Scripts that add hooks to jobmanager                                                      |
| lyd               | Related to sound                                                                          |
| security          | Security scripts                                                                          |
| sikkerhed         | Scripts that enhance or weaken security (OS2borgerPC and OS2borgerPC Kiosk)               |
| system            | Uncategorized scripts that work on Ubuntu generally (OS2borgerPC and OS2borgerPC Kiosk)   |

Below `os2borgerpc` we have the following categories

| Category      | Description                                                                |
| ------------- | ---------------------------------------------------------------------------|
| bluetooth     | Related to bluetooth                                                       |
| browser       | Related to assorted web browsers                                           |
| custom        | Local scripts for customers                                                |
| desktop       | Desktop related scripts                                                    |
| libreoffice   | Related to LibreOffice                                                     |
| login         | Related to login                                                           |
| os2borgerpc   | Uncategorized scripts that are only designed to work on OS2BorgerPC        |
| printer       | Related to printing                                                        |
| skanner       | Related to scanning                                                        |
| sikkerhed     | Scripts that enhance or weaken security (OS2borgerPC only)                 |

Below `os2borgerpc_kiosk` we have the following categories

| Category          | Description                                                                |
| ------------------| ---------------------------------------------------------------------------|
| custom            | Local scripts for customers                                                |
| os2borgerpc_kiosk | Uncategorized scripts that are only designed to work on OS2borgerPC Kiosk  |

The scripts were developed by Magenta Aps (https://www.magenta.dk) and is part of the
OS2borgerPC project.

## Recommended scripts to improve security on different OS2borgerPC image versions

NOTE: This section concerns the scripts that are relevant for improving the base
level of security on OS2borgerPC and should almost always be used. In some
cases, a user of OS2borgerPC may wish to deactivate some of these scripts
in order to access the related functions, but they should be aware that
doing so worsens the security. Security-related scripts not mentioned here,
such as the script to activate USB surveillance, may be more or less relevant
depending on the specific use case.

REMINDER: Always remember to change the superuser password after registration.

If a script is found to improve the security of OS2borgerPC,
it will be included in the next image release, provided that doing so is
reasonable.

For this reason, we strongly recommend always using the newest available image version
when installing OS2borgerPC on new computers.

If no image yet exists where the relevant scripts have been included or
if a computer was installed using an older image, we instead strongly
recommend running the scripts that are relevant for improving the security of
that image version after registration.

The following lists indicate the relevant scripts for each currently supported
image version. We strongly recommend running the scripts listed for the used
image version after registration to improve the security of the computer.

The lists indicate the name used on Magentas admin-site and the path to
the script in this repository.

### OS2borgerPC image 5.2.0, 5.1.0 and 5.0.0
We recommend running the following scripts after registration
(they will be included in the next image release):

"Sikkerhed - Juster adgang til terminalen": [os2borgerpc-scripts/os2borgerpc/sikkerhed/protect_terminal.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/protect_terminal.sh)

The script should be run with the parameter `False` (empty checkbox)

"Sikkerhed - Nulstil crontab ved logud": [os2borgerpc-scripts/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh)

The script takes no parameters

### OS2borgerPC image 4.0.0
We recommend running the following scripts after registration:

"Sikkerhed - Juster adgang til terminalen": [os2borgerpc-scripts/os2borgerpc/sikkerhed/protect_terminal.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/protect_terminal.sh)

The script should be run with the parameter `False` (empty checkbox)

"Sikkerhed - Nulstil crontab ved logud": [os2borgerpc-scripts/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh)

The script takes no parameters

"Sikkerhed - Slå skriverettigheder for skrivebord fra/til": [os2borgerpc-scripts/os2borgerpc/sikkerhed/desktop_toggle_writable.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/desktop_toggle_writable.sh)

The script should be run with the parameter `True` (checked checkbox)

"Sikkerhed - Juster adgang til kør prompt": [os2borgerpc-scripts/os2borgerpc/sikkerhed/dconf_run_prompt_toggle.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/dconf_run_prompt_toggle.sh)

The script should be run with the parameter `True` (checked checkbox)

"Sikkerhed - Fjern Luk Ned, Genstart og Hviletilstand fra menuen": [os2borgerpc-scripts/os2borgerpc/sikkerhed/polkit_policy_shutdown_suspend.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/polkit_policy_shutdown_suspend.sh)

The script should be run with the parameters `True` (checked checkbox) and `True` (checked checkbox)

"Sikkerhed - Lås menu": [os2borgerpc-scripts/os2borgerpc/sikkerhed/dconf_gnome_lock_menu_editing.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/dconf_gnome_lock_menu_editing.sh)

The script should be run with the parameter `True` (checked checkbox)

"Browser - Firefox: Kiosk og Sæt startside(r)": [os2borgerpc-scripts/os2borgerpc/browser/firefox_global_policies.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/browser/firefox_global_policies.sh)

The script should be run with an appropriate URL (string) as the first parameter.
The second parameter can be an empty string.

"Udfases - Desktop - Fjern brugerskifte fra menuen": [os2borgerpc-scripts/os2borgerpc/udfases/dconf_disable_user_switching.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/udfases/dconf_disable_user_switching.sh)

The script takes no parameters

"Udfases - Desktop - Fjern lås fra menuen": [os2borgerpc-scripts/os2borgerpc/udfases/dconf_disable_lock_menu.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/udfases/dconf_disable_lock_menu.sh)

The script takes no parameters

### OS2borgerPC image 3.1.1, 3.1.0 and 3.0.0
We recommend running the following scripts after registration:

"Sikkerhed - Juster adgang til terminalen": [os2borgerpc-scripts/os2borgerpc/sikkerhed/protect_terminal.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/protect_terminal.sh)

The script should be run with the parameter `False` (empty checkbox)

"Sikkerhed - Nulstil crontab ved logud": [os2borgerpc-scripts/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/prevent_crontab_persistence.sh)

The script takes no parameters

"Sikkerhed - Juster adgang til indstillinger for Borger": [os2borgerpc-scripts/os2borgerpc/sikkerhed/adjust_settings_access.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/adjust_settings_access.sh)

The script should be run with the parameter `False` (empty checkbox)

"Sikkerhed - Tillad Borgere at redigere netværksindstillinger": [os2borgerpc-scripts/os2borgerpc/sikkerhed/network_manager_allow_user_changes.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/network_manager_allow_user_changes.sh)

The script should be run with the parameter `False` (empty checkbox)

"Sikkerhed - Slå skriverettigheder for skrivebord fra/til": [os2borgerpc-scripts/os2borgerpc/sikkerhed/desktop_toggle_writable.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/desktop_toggle_writable.sh)

The script should be run with the parameter `True` (checked checkbox)

"Sikkerhed - Juster adgang til kør prompt": [os2borgerpc-scripts/os2borgerpc/sikkerhed/dconf_run_prompt_toggle.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/dconf_run_prompt_toggle.sh)

The script should be run with the parameter `True` (checked checkbox)

"Sikkerhed - Fjern Luk Ned, Genstart og Hviletilstand fra menuen": [os2borgerpc-scripts/os2borgerpc/sikkerhed/polkit_policy_shutdown_suspend.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/polkit_policy_shutdown_suspend.sh)

The script should be run with the parameters `True` (checked checkbox) and `True` (checked checkbox)

"Sikkerhed - Lås menu": [os2borgerpc-scripts/os2borgerpc/sikkerhed/dconf_gnome_lock_menu_editing.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/sikkerhed/dconf_gnome_lock_menu_editing.sh)

The script should be run with the parameter `True` (checked checkbox)

"Browser - Firefox: Kiosk og Sæt startside(r)": [os2borgerpc-scripts/os2borgerpc/browser/firefox_global_policies.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/browser/firefox_global_policies.sh)

The script should be run with an appropriate URL (string) as the first parameter.
The second parameter can be an empty string.

"Udfases - Opgrader klient og klientindstillinger til nyeste version nu": [os2borgerpc-scripts/common/udfases/upgrade_client_and_settings.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/common/udfases/upgrade_client_and_settings.sh)

The script takes no parameters

"Udfases - Desktop - Fjern brugerskifte fra menuen": [os2borgerpc-scripts/os2borgerpc/udfases/dconf_disable_user_switching.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/udfases/dconf_disable_user_switching.sh)

The script takes no parameters

"Udfases - Desktop - Fjern lås fra menuen": [os2borgerpc-scripts/os2borgerpc/udfases/dconf_disable_lock_menu.sh](https://github.com/OS2borgerPC/os2borgerpc-scripts/blob/master/os2borgerpc/udfases/dconf_disable_lock_menu.sh)

The script takes no parameters

## Final remarks

For more info about the OS2borgerPC project, please see the
official home page:

    https://os2.eu/produkt/os2borgerpc

and the offical Github project:

    https://github.com/OS2borgerPC/

All code is made available under Version 3 of the GNU General Public
License - see the LICENSE and COPYRIGHT files for details.
