#!/bin/bash
#
# This script logs into the default Debian 13 installation of a stw.no VPS and flashes an OpenBSD install.img onto /dev/sda, then reboots via a sysrq.
# After this the other script can be used to "automate" answering the installers questions.

set -x



# VPS IP
vps_ip=85.137.228.93

# Specify OpenBSD version to install
openbsd_version=78
openbsd_version_dot=7.8


# Remove the IP from the ~/.ssh/known_hosts file
ssh-keygen -R $vps_ip

# Download OpenBSD install.img
ssh -o StrictHostKeyChecking=accept-new root@$vps_ip "wget --no-verbose https://cdn.openbsd.org/pub/OpenBSD/$openbsd_version_dot/amd64/install$openbsd_version.img"

# Flash it to /dev/sda and hardcore-reboot. dd will automatically use the "sync" command, so we can just instant-reboot after
# Mind that as we wrote all this in one command line, the echo should be in RAM and /sys is in RAM anyways
# So "should" work (famous last words). So far it worked each time I tried.
ssh -o StrictHostKeyChecking=accept-new root@$vps_ip "dd if=/root/install$openbsd_version.img of=/dev/sda status=progress bs=1M conv=fsync; echo b > /proc/sysrq-trigger"
