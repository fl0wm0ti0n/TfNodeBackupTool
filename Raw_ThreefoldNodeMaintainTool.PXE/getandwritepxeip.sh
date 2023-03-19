#!/bin/bash
# Author:   Florian Gabriel (omniflow)
# Repo:     https://github.com/fl0wm0ti0n
# Date:     20230222
# Purpose:  Setup pxelinux menue

# Begin of the scripts:

# get host ip
ip=$(hostname -I | awk '{print $1}')

# write to pxelinux.cfg/default
cat pxelinux.cfg/default | sed "s/10.0.0.26/$ip/g" > default
mv default pxelinux.cfg/default
