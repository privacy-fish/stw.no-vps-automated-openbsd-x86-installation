# Fully Automatic OpenBSD installation for stw.no / servetheworld.net VPS

This repository automates installing OpenBSD on a servetheworld.net / stw.no x86 VPS.

The current flow uses one local macOS shell script:

- `setup-openbsd.sh` flashes the OpenBSD installer image from the temporary Debian system, reboots the VPS, drives the browser noVNC installer with desktop automation, and hands off to OpenBSD `autoinstall`.
- `templates/install.conf/*.conf` are OpenBSD autoinstall response files for the configured target hosts.
- `install.sh` installs the local macOS command-line dependencies used by the automation.

This is intentionally hoster-specific and destructive. It writes an OpenBSD installer image to `/dev/sda` on the selected VPS and then installs OpenBSD to that machine.

## Why not use a tool like Playwright

stw.no exposes the VPS console through a browser noVNC page, not a normal VNC endpoint. In this setup, noVNC automation only gives reliable browser-level control over an opaque `<canvas>`, not structured terminal text or a clean console API.

It is not pretty, but it keeps the moving parts small.

## Requirements

### VPS

- An x86 stw.no VPS.
- A fresh Debian 13 installation booted on the VPS.
- Root SSH access to that Debian system.

### Local machine

This currently assumes macOS.

You need:

- `bash`
- `ssh` and `ssh-keygen`
- GNU `timeout` from `coreutils`
- `cliclick`
- `pbcopy`
- `say`
- a browser with the stw.no noVNC console open

Install the Homebrew dependencies:

```sh
./install.sh
```

That installs:

```sh
brew install coreutils cliclick
```

## Configure a target

`setup-openbsd.sh` currently supports two target arguments:

- `test`
- `www`

Each target block sets:

- the VPS IPv4 address
- the URL of the hosted OpenBSD `install.conf` response file

The shared variables near the top of the script set:

- `vps_netmask`
- `vps_gateway`
- `openbsd_version`
- `openbsd_version_dot`

Before using this for another VPS, update those values in `setup-openbsd.sh`.

## Configure install.conf

The response files live in:

```text
templates/install.conf/
```

Each file answers the OpenBSD installer prompts for one host, including:

- hostname
- `vio0` IPv4 address, netmask, gateway, and DNS
- root password and root SSH public key
- SSH daemon startup and root login policy
- timezone
- disk layout choice
- install sets
- X Window System choice

Host the response file somewhere the OpenBSD installer can fetch over HTTP or HTTPS. The existing `test` and `www` targets use raw GitHub URLs for the files in this repository.

If you create your own target, copy one of the template files, edit it for the VPS, publish it, and update the matching `install_conf_url` in `setup-openbsd.sh`.

## Install OpenBSD

1. In the stw.no control panel, select the VPS.
2. If needed, use the reinstallation option to install Debian 13.
3. Wait for Debian 13 to boot and confirm root SSH works:

   ```sh
   ssh root@<vps-ip>
   ```

4. Open the stw.no noVNC console for the VPS in your browser and keep the console visible.
5. Run the script with the target name:

   ```sh
   ./setup-openbsd.sh test
   ```

   or:

   ```sh
   ./setup-openbsd.sh www
   ```

6. When macOS says it is waiting for the OpenBSD installer, switch focus back to the noVNC browser window.
7. Do not use the keyboard, mouse, or clipboard while the script is typing into noVNC.


## Troubleshooting

If the OpenBSD boot prompt stops at `boot>`, regular Enter/auto-boot usually works. If the disk is not found, the command that worked during testing was:

```text
boot hd0a:/bsd.rd
```

The noVNC input path is fragile. The script uses fixed clicks, sleeps, clipboard paste, and typed commands because some characters such as `>`, `|`, and `:` are unreliable when typed directly through the browser console.

If the automation misses the noVNC window, click/focus behavior or screen coordinates may need to be adjusted in `setup-openbsd.sh`.

## Adapting to Linux workstations

The scripts were written for macOS, but the approach can be adapted to Linux by replacing the local desktop automation tools:

- `cliclick` -> `xdotool` on X11, or `ydotool` / `wtype` on Wayland
- `pbcopy` / `pbpaste` -> `xclip` / `xsel` on X11, or `wl-copy` / `wl-paste` on Wayland
- `say` -> `spd-say` or `espeak-ng`

Whether the desktop session uses X11 or Wayland matters a lot for input automation.
