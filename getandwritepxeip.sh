#!/bin/bash
# Author:   Florian Gabriel (omniflow)
# Repo:     https://github.com/fl0wm0ti0n
# Date:     20230220
# Purpose:  Setup pxelinux menue

# Begin of the scripts:

# get host ip
ip=$(hostname -I | awk '{print $1}')

# write to pxelinux.cfg/default
cat /pxelinux.cfg/default | sed "s/<IP>/$ip/g" > output.txt
