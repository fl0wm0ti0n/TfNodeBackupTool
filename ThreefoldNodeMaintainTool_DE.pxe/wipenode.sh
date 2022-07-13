#!/bin/bash
# Author: Florian Gabriel (omniflow)
# https://github.com/fl0wm0ti0n

# Begin of the scripts:
# Load DRBL setting and functions
DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"

. $DRBL_SCRIPT_PATH/sbin/drbl-conf-functions
. /etc/drbl/drbl-ocs.conf
. $DRBL_SCRIPT_PATH/sbin/ocs-functions

# load the setting for clonezilla live.
[ -e /etc/ocs/ocs-live.conf ] && . /etc/ocs/ocs-live.conf
# Load language files. For English, use "en_US.UTF-8".
ask_and_load_lang_set en_US.UTF-8

# The above is almost necessary, it is recommended to include them in your own custom-ocs.
# From here, you can write your own scripts.

# functions
search_disks() {
    name=$1[@]
    listOfDisks=("${!name}")

    for i in $(sudo lsblk | grep -E "sd[a-z]|hd[a-z]|nvm[a-z]|vd[a-z]" | cut -d' ' -f1); do listOfDisks+=("/dev/$i") ;done
    if [ ${#listOfDisks[@]} -eq 0 ]; then
        write_color "fail" "there is no qualified disk!"
        termination
    fi
}

wipe_disks() {
    listOfDisks=()

    search_disks listOfDisks

        for disk in "${listOfDisks[@]}"; do 
            write_color "info" "trying to wipe disk $disk ..."
            if [ "$g_test" = "false" ] ;then
                if ! wipefs "$disk" -a ; then
                    write_color "fail" "something went wrong wiping the disk $disk!"
                    termination
                else
                    write_color "successfully wiped disk $disk!"
                fi
            else
                write_color "successfully wiped disk $disk!"
            fi
        done
}

wipe_disks_manually() {
    listOfDisks=()

    search_disks listOfDisks
    wipe_disks_menu listOfDisks
}

wipe_disks_menu() {
    name=$1[@]
    listOfDisks=("${!name}")

    for i in "${!listOfDisks[@]}"; do
        write_color "warn" "Option $i: ${listOfDisks[i]}"
        dfinfo=$(df -h "${listOfDisks[i]}")
        write_color "info" "$dfinfo"
    done

    read -r -p "Enter the digit of given options (enter -1 to exit): " option ;
    
    if [ "$option" -eq -1 ] ;then
        exit 0
    fi

    if [ "${listOfDisks[$option]}" = "" ] ;then
        write_color "warn" "entry doesnt exist, chose a different one"
        wipe_disks_menu listOfDisks
    fi

    disk=${listOfDisks[$option]}

    if [ "$g_test" = "false" ] ;then
        write_color "info" "wiped disk $disk"
            if ! wipefs "$disk" -a ; then
                write_color "fail" "something went wrong wiping the disk $disk!"
                termination
            else
                write_color "successfully wiped disk $disk!"
            fi
        remove_array_entry listOfDisks "$disk"
    else
        write_color "successfully wiped disk $disk!"
        remove_array_entry listOfDisks "$disk"
    fi

    if [ ${#listOfDisks[@]} -eq 0 ] ;then
        write_color "info" "all disks wiped!"
        exit 0
    fi

    wipe_disks_menu listOfDisks
}  

remove_array_entry() {
    name=$1[@]
    listOfDisks=("${!name}")
    disk=$2

    for i in "${!listOfDisks[@]}"; do
    if [[ ${listOfDisks[i]} = "$disk" ]]; then
        unset 'listOfDisks[i]'
    fi
    done

    for i in "${!listOfDisks[@]}"; do
        new_array+=( "${listOfDisks[i]}" )
    done
    listOfDisks=("${new_array[@]}")
    unset new_array
}

write_help() {
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo "-------------------------------------------------------------------"
    echo "Helptext of $0"
    echo "Default: wipe all disks"
    echo "Syntax: $0 [options]"
    echo "OPTIONS:"
    echo "h -> This helptext"
    echo "m -> manual run, existing disks will be listed"
    echo "t -> testrun, dont wipe disks for real"
    echo "-------------------------------------------------------------------"
    echo "made by omniflow [https://github.com/fl0wm0ti0n]"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
}

termination() {
    write_color "fail" "Program terminated!"
    write_color "fail" "you can restart the script in the following window!"
     exit 1
}

write_color() {
local level=$1
local text=$2

    case $level in
        "fail")
            [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
            echo "$text"
            [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
        ;;
        "warn")
            [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
            echo "$text"
            [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
        ;;
        "info")
            echo "$text"
        ;;
        ?)
            echo "$text"
        ;;
    esac   
}

##################
###### MAIN ######
##################

echo "Starting up $0"

g_task="default"
g_test=false

while getopts 'mht' OPTION; do
case "$OPTION" in
    m)
        g_task="manually"
    ;;
    t)
        g_test=true
        write_color "warn" "testrun, doesn't wipe disks for real"
    ;;
    h)
        write_help
    ;;
    ?)
        write_help
    ;;
esac
done
shift "$((OPTIND -1))"

case "$g_task" in
    "manually")
        write_color "info" "Wipe by selecting the disk"
        wipe_disks_manually     
    ;;
    "default")
        write_color "info" "Wiping all disks"
        wipe_disks
    ;;
esac