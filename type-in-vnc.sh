#!/bin/bash
#
# This script "automates" (in a hacky way) answering the questions of the OpenBSD installer within the noVNC window of stw.no VPS.
# See README.md on why we didn't use a less hacky way.

set -x


# Network settings of your stw.no VPS - you can find these by scrolling to the bottom of your VPS overview page under "IP Addresses"
vps_ip=85.137.228.93
vps_netmask=255.255.255.0
vps_gateway=85.137.228.1
# Location of the install.conf file
install_conf_url="https://raw.githubusercontent.com/fishprivacy/stw.no-vps-automated-openbsd-x86-installation/refs/heads/main/install.conf/test.privacy.fish.conf"



# Small function to load things into the copy paste buffer
# The VNC window doesn't like typing characters like > | : and alike, so we load those into the copy paste buffer so the user can paste them
copy_for_paste() {
    # Input to load into copy paste buffer
    copy_buffer_input="$1"
    # So lets hack some more and use copy paste... >:(
    # Paste doesnt work reliably either in the VNC browser window (it just writes "v") so lets get what we want into the copy buffer and then notify the user to paste
    printf %s "$copy_buffer_input" | pbcopy
    # Audio-notify the user to paste now
    say "paste into the VNC window and press enter"
    # Give the user some time to paste
    sleep 5
}



# Wait for user to switch from terminal window to browser window that shows the VNC console
sleep 5

# Click in the middle of the screen to focus the VNC window
cliclick c:700,400
sleep 0.2

# The boot prompt we need contains a ":" so lets use copy paste
# Commented out bcs regular boot seems to just work now
#copy_for_paste "boot hd0a:/bsd.rd"

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
copy_for_paste "echo nameserver 9.9.9.9 > /etc/resolv.conf"

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
copy_for_paste "$install_conf_url"
# Takes a while to "paste" (pasting "writes" character by character)
sleep 10

# Now we are at
# (I)nstall or (U)pgrade?
# We select Install
cliclick t:I kp:enter



# From here on out, the installer should do everything by itself, so the user has to wait while this hacky script is finished x)
# After the reboot the system should be reachable via ssh
