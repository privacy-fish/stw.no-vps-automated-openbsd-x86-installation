#!/bin/bash
#
# This script automates:
# - Flashing the stw.no VPS with the OpenBSD install.img and rbeooting the system
# - Answering the installers questions in the noVNC window
#
# See README.md on why we didn't use a less hacky way.

set -x


## VARIABLES ##

# VPS netmask and gateway
vps_netmask=255.255.255.0
vps_gateway=85.137.228.1

# Specify OpenBSD version to install
openbsd_version=78
openbsd_version_dot=7.8



## PARSE ARGUMENTS ##

if [[ "$1" == "test" ]]; then
    # Network settings of your stw.no VPS - you can find these by scrolling to the bottom of your VPS overview page under "IP Addresses"
    vps_ip=85.137.228.93
    # Location of the install.conf file
    install_conf_url="https://raw.githubusercontent.com/privacy-fish/stw.no-vps-automated-openbsd-x86-installation/refs/heads/main/templates/install.conf/test.privacy.fish.conf"
elif [[ "$1" == "www" ]]; then
    vps_ip=85.137.228.85
    install_conf_url="https://raw.githubusercontent.com/privacy-fish/stw.no-vps-automated-openbsd-x86-installation/refs/heads/main/templates/install.conf/www.privacy.fish.conf"
else
    echo "Please give www or test as first argument to select target server, aborting!"
    exit 1
fi



## FLASHING OPENBSD INSTALLER PART ##
# RUNS ON THE DEBIAN 13 DEFAULT INSTALLATION

# Remove the IP from the ~/.ssh/known_hosts file
ssh-keygen -R $vps_ip

# Download OpenBSD install.img
ssh -o StrictHostKeyChecking=accept-new root@$vps_ip "wget --progress=bar:force:noscroll https://cdn.openbsd.org/pub/OpenBSD/$openbsd_version_dot/amd64/install$openbsd_version.img"

# Flash it to /dev/sda and hardcore-reboot. dd will automatically use the "sync" command, so we can just instant-reboot after
# Mind that as we wrote all this in one command line, the echo should be in RAM and /sys is in RAM anyways
# So "should" work (famous last words). So far it worked each time I tried.
timeout 15 ssh -o StrictHostKeyChecking=accept-new root@$vps_ip "dd if=/root/install$openbsd_version.img of=/dev/sda status=progress bs=1M conv=fsync; echo b > /proc/sysrq-trigger"



## AUTOMATICALLY TYPING IN THE OPENBSD VNC INSTALLER PART
# MAKE SURE TO VIEW THE NOVNC WINDOW IN YOUR BROWSER WHILE THIS IS RUNNING

# Wait for the installer to boot
say "Waiting for the OpenBSD installer to boot. Please switch to the noVNC window"
sleep 10

# Small function to load things into the copy paste buffer
# The VNC window doesn't like typing characters like > | : and alike, so we load those into the copy paste buffer so the user can paste them
copy_paste() {
    # Type it takes to type the content
    sleep_time="$1"
    # Input to load into copy paste buffer
    copy_buffer_input="$2"
    # So lets hack some more and use copy paste... >:(
    # Paste doesnt work reliably either in the VNC browser window (it just writes "v") so lets get what we want into the copy buffer and then notify the user to paste
    printf %s "$copy_buffer_input" | pbcopy
    # Two-finger-click and them move mouse a bit to bottom and right, then click
    cliclick rc:. w:150 m:+25,+10
    sleep 1
    cliclick c:.
    cliclick c:.
    # Wait till its typed out
    sleep "$sleep_time"
    # Press ENTER
    cliclick t:" " kp:enter
    sleep 0.5
}



# Click in the middle of the screen to focus the VNC window
cliclick c:700,400
sleep 0.2

# This might be required on some systems to boot the correct ssd
#
# The boot prompt we need contains a ":" so lets use copy paste
# Commented out bcs regular boot seems to just work now
#copy_paste 3 "boot hd0a:/bsd.rd"
#
# Wait for system to boot up to end up at
# (I)nstall, (U)pgrade, (A)utoinstall or (Shell)?
#sleep 10

# We select "S" to setup the network so we can download the install.conf file
cliclick t:S kp:enter

# Configure the network in the shell so it can later find the autoinstall file
# Configure static IPv4 on vio0
cliclick "t:ifconfig vio0 inet $vps_ip netmask $vps_netmask up" kp:enter
sleep 0.5

# Add default gateway
cliclick "t:route add default $vps_gateway" kp:enter
sleep 0.5

# Setup the nameserver - this is tricky because I cant type > or | in this annoying browser window x)
copy_paste 3 "echo nameserver 9.9.9.9 > /etc/resolv.conf"

# Test the network
cliclick "t:ping -c 3 quad9.net" kp:enter
sleep 5

# Exit the shell to get back to the Install Upgrade Autoinstall Shell prompt
cliclick t:exit kp:enter
sleep 10

# Now we are back at:
# (I)nstall, (U)pgrade, (A)utoinstall or (Shell)?
# We select "A"
cliclick t:A kp:enter
# Its waiting for DHCP for 30 seconds here
sleep 35

# Enter the Response file location
# This would all be fun and games... But the URL contains a ":" which is written as a ";" - so back to copy paste
copy_paste 10 "$install_conf_url"

# Now we are at
# (I)nstall or (U)pgrade?
# We select Install
cliclick t:I kp:enter

# From here on out, the installer is doing everything by itself, so the user has to wait
sleep 120

# Remove the IP from the ~/.ssh/known_hosts file
ssh-keygen -R $vps_ip

# The system should now be booted into OpenBSD. Reset to the new ssh key.
ssh -o StrictHostKeyChecking=accept-new root@$vps_ip "true"

# Finished
echo "You can now open a shell:"
echo "ssh root@$vps_ip"
