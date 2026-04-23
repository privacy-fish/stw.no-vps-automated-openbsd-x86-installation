# Hacky automated way to install OpenBSD on servetheworld.net / stw.no VPS

The scripts in this repository automate installing OpenBSD on a hosttheworld.net / stw.no VPS.


## Note about OpenBSD on Proxmox, which stw.no uses to host VPS

Installing OpenBSD on an UEFI system is possible but requires more steps, which I skipped in this case. You can write an email to `support@servetheworld.net` and ask them to "enable seaBIOS" for your VPS.

## What this repo does

To (mostly) automatically install OpenBSD on a servetheworld.net / stw.no x86 VPS, follow these steps:

1. Go to https://my.servetheworld.net/clientarea.php?action=services and select your server
2. (Optional, if you bricked it already) Scroll to the middle and click the "Reinstallation" button to install Debian 13
3. Wait for the reinstallation to finish and the new Debian 13 system to boot
4. Edit the `flash-install-img.sh` and edit the variables according to the IP of your VPS and the latest stable OpenBSD release version
5. Rename and edit the install.conf/test.privacy.fish.conf file - you need to host this file somewhere (you can push it to your own github account in a public repo so the installer can download it)
6. Edit the `type-in-vnc.sh` and edit the variables according to the network information at the bottom of your VPS overview page
7. Go to the stw.no overview page of your server and click on "noVNC Console"
8. Watch the system to boot the OpenBSD installer until you get to `(I)nstall, (U)pgrade, (A)utoinstall or (Shell)?`
   Sidenote: when the OpenBSD installer is at `boot>`, just pressing ENTER or waiting for it to auto-boot worked for me 99% of the time. Sometimes it does not find the disk to boot from, typing `boot hd0a:/bsd.rd` and pressing ENTER fixed this for me.
9. With the VNC window still open in the browser, execute this script: `type-in-vnc.sh`, then immediately switch back to the VNC window. The script will then start typing the required things to automatically install OpenBSD.

After that, OpenBSD finishes the install by itself and reboots, and you should be able to login via `ssh root@<your-ip>`

## Why automate the installation in this hacky way

We did not use Playwright for this noVNC installer flow because, in this specific hoster setup, it only gave us browser-level control over an opaque `<canvas>` rather than reliable access to the VM console itself: the noVNC page exposed no usable public API object, the terminal text inside the canvas was not readable as normal DOM text, whole-screen matching turned out too brittle, and even simple keyboard input had quirks like modifier-state leakage; in practice, that meant the Playwright solution still depended on hacky visual heuristics while adding a lot more code and moving parts, whereas a small shell script with fixed clicks, paste/keystrokes, and sleeps is simpler, easier to debug, and good enough until a more direct console automation method is available.

The hoster exposes console access through a browser noVNC page, not a normal VNC endpoint. That makes clean automation annoying. The solution in this repo is intentionally simple and ugly:

- flash the installer image remotely over SSH
- reboot into the installer
- use local desktop automation to interact with the noVNC browser window
- hand off to OpenBSD `autoinstall` as early as possible

It is not pretty, but it works.

## Requirements

### Local machine

This currently assumes macOS.

You need:

- `bash`
- `cliclick`
- `pbcopy`
- `say`

Install `cliclick` with Homebrew: `brew install cliclick`

## Adapting these scripts for Linux workstations

The scripts in this repository were written for Mac OSX, but should be easily adapted to your Linux based workstations. If you want to adapt the local automation scripts for Ubuntu later, replace the macOS-specific tools with these rough equivalents:

- `cliclick` -> `xdotool` (X11) or `ydotool` / `wtype` (Wayland)
- `pbcopy` / `pbpaste` -> `xclip` / `xsel` (X11) or `wl-copy` / `wl-paste` (Wayland)
- `say` -> `spd-say` or `espeak-ng`
- `afplay` -> `paplay`, `aplay`, or `canberra-gtk-play`

On Ubuntu, whether you are on X11 or Wayland matters a lot for input automation.
