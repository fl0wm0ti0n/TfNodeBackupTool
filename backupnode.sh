#!/bin/bash
# Author: Florian Gabriel (omniflow)
# Date: 20220705
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

# Set up dhcp
dhclient

# functions
copy_via_scp() {    
    local seedName=$1

    if ! sudo sshpass -p "$g_password" scp -o 'StrictHostKeyChecking no' "$g_tempSeedFolder/$seedName" "$g_user@$g_connectionString:$g_remotePath";
    then
        write_color "fail" "scp copy failed"
        termination
    else
        write_color "info" "successfully copied $seedName to $g_connectionString:$g_remotePath"
    fi

    if [ -n "$g_chmod" ]; then
        write_color "info" "trying to chmod to $g_chmod"
        sudo sshpass -p "$g_password" ssh -o 'StrictHostKeyChecking no' "$g_user@$g_connectionString" "'chown $g_chown $g_remotePath$seedName'"
    fi
    if [ -n "$g_chown" ]; then
        write_color "info" "trying to chown to $g_chown"
        sudo sshpass -p "$g_password" ssh -o 'StrictHostKeyChecking no' "$g_user@$g_connectionString" "'chown $g_chown $g_remotePath$seedName'"
    fi
}

copy_via_cifs() {
    local seedName=$1

    mkdir -p "$g_tempCifsMntFolder"

    if ! sudo mount -t cifs -o username="$g_user",password="$g_password",uid=33,gid=33,file_mode=0770,dir_mode=0770 "$g_connectionString$g_remotePath" "$g_tempCifsMntFolder";
    then
        write_color "fail" "cifs mount failed"
        termination
    else
        write_color "info" "successfully mounted $g_connectionString$g_remotePath to $g_tempCifsMntFolder"
    fi

    if ! sudo cp -f "$g_tempSeedFolder/$seedName" "$g_tempCifsMntFolder";
    then
        write_color "fail" "copy to mounted cifs folder $g_tempCifsMntFolder failed"
        termination
    else
        write_color "info" "successfully copied $seedName to $g_connectionString$g_remotePath"
    fi

    if [ -n "$g_chmod" ]; then
        write_color "info" "trying to chmod to $g_chmod"
        sudo chmod "$g_chmod" "$g_tempCifsMntFolder$g_remotePath$seedName"
    fi
    if [ -n "$g_chown" ]; then
        write_color "info" "trying to chown to $g_chown"
        sudo chown "$g_chmod" "$g_tempCifsMntFolder$g_remotePath$seedName"
    fi
}

copy_via_usb() {
    write_color "fail" "not implemented!"
    termination
}

search_usb_key() {
    write_color "fail" "not implemented!"
    termination
}

mount_disk() {
    local disk=$1
    sudo mount "$disk" "$g_tempMntFolder"
}

umount_disk() {
    local disk=$1
    sudo umount "$disk"
}

search_disks() {
    name=$1[@]
    listOfDisks=("${!name}")

    for i in $(sudo lsblk | grep -E "sd[a-z]|hd[a-z]|nvm[a-z]|vd[a-z]" | cut -d' ' -f1); do listOfDisks+=("/dev/$i") ;done
    if [ ${#listOfDisks[@]} -eq 0 ]; then
        write_color "fail" "there is no qualified disk!"
        termination
    fi
}

search_seed() {
    seedPath=$1
    temp=$(sudo ls "$g_tempMntFolder$g_defaultSeedPath")
    if [ "$temp" = "seed.txt" ]; then
        seedPath="$g_tempMntFolder$g_defaultSeedPath/$temp"
    else
        seedPath=""
    fi
}

backup_seed_routine() {
    seedPath=$1
    disk=$2
    listOfDisks=()
    
    sudo mkdir -p "$g_tempMntFolder"

    search_disks listOfDisks
    for disk in "${listOfDisks[@]}"; do 
        write_color "info" "check disk $disk!"
        mount_disk "$disk"
        search_seed "$seedPath"
        if [ -n "$seedPath" ]; then
            return 0
        else
            umount_disk "$disk"
        fi
    done
    if [ -z "$seedPath" ]; then
        write_color "fail" "there is no seed on any disk!"
        termination
    else
        write_color "info" "Seed found!: $seedPath"
    fi
}

test_backup_seed_routine() {
    seedPath=$1
    
    sudo mkdir -p "$g_tempMntFolder"
    seedPath="/tmp/seed.txt"
}

rename_seed() {
    seedPath=$1
    seedName=$2

mkdir -p "$g_tempSeedFolder"

if [ "$g_nodeId" = "date" ] || [ -z "$g_nodeId" ] || [ "$g_useDateTimeNaming" = "true" ]; then
    date=$(date +"%m%d%Y%H%M%S")
    write_color "warn" "use datetime for naming, seed name will be node_$date.txt"
    seedName="node_$date.txt"
    sudo cp -f "$seedPath" "$g_tempSeedFolder/$seedName"
else
    write_color "info" "seed name will be 'node_$g_nodeId.txt'"
    seedName="node_$g_nodeId.txt"
    sudo cp -f "$seedPath" "$g_tempSeedFolder/$seedName"
fi
}

read_config() {
jsonfile=$(cat "$g_configPath")
useconfig=""
useconfig=$(jq '.useconfig' <<<"$jsonfile")

if [ "$useconfig" = "true" ]; then
    write_color "info" "read $g_configPath"
    g_farmId=$(jq '.farmId' <<<"$jsonfile")
    g_backupMode=$(jq -r '.backupMode' <<<"$jsonfile")
    g_gqlNaming=$(jq '.tryGetNodeNrFromGrid' <<<"$jsonfile")
    g_backupTarget=$(jq -r '.backupTarget' <<<"$jsonfile")
    g_chown=$(jq -r '.chown' <<<"$jsonfile")
    g_chmod=$(jq '.chmod' <<<"$jsonfile")
    g_timeout=$(jq '.timeout' <<<"$jsonfile")
    g_useDateTimeNaming=$(jq '.useDateTimeNaming' <<<"$jsonfile")

    readarray -t remotes < <(jq -c '.remotes[]' <<<"$jsonfile")
    for remote in "${remotes[@]}"
    do
        remoteType=$(jq -r '.remoteType' <<<"$remote")
        if [[ "$g_backupTarget" == "$remoteType" ]]; then
            g_user=$(jq -r '.user' <<<"$remote")
            g_password=$(jq -r '.password' <<<"$remote")
            g_connectionString=$(jq -r '.connectionString' <<<"$remote")
            g_remotePath=$(jq -r '.remotePath' <<<"$remote")
        fi
    done
elif [ "$useconfig" = "false" ]; then
    write_color "warn" "using $g_configPath is disabled within the file"
    return
else
    write_color "warn" "something went wrong reading $g_configPath, maybe it doesn't exist"
    return
fi
 
    write_color "info" "Parsed config parameters:"
    write_color "info" "FarmID:                 $g_farmId"
    write_color "info" "GQLNaming:              $g_gqlNaming"
    write_color "info" "UseDateTimeNaming:      $g_useDateTimeNaming"
    write_color "info" "Chown:                  $g_chown"
    write_color "info" "Chmod:                  $g_chmod"
    write_color "info" "Timeout:                $g_timeout"
    write_color "info" "BackupTarget:           $g_backupTarget"
    write_color "info" "User:                   $g_user"
    write_color "info" "Password:               $g_password"
    write_color "info" "ConnectionString:       $g_connectionString"
    write_color "info" "RemotePath:             $g_remotePath"
}

get_nodeid_from_grid() {
macs=($(cat /sys/class/net/*/address))

write_color "info" "trying to get the nodeid from $g_graphQlApi"
    if [ "$g_farmId" = "" ]; then
        write_color "fail" "no FarmId given, can't fetch TF GQL API for NodeId"
    fi

for mac in "${macs[@]}"
do
  curl -g \
  -X POST \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
    "$g_graphQlApi" \
  -d '{ "query": "query MyQuery { nodes(where: {farmID_eq: '${g_farmId}', interfaces_some: {mac_eq: \"'${mac}'\"}}) { nodeID interfaces { mac ips } } }" }' \
  -so /tmp/$$.gql.result.json

  readarray -t nodes < <(jq -c '.data.nodes[] | .nodeID' /tmp/$$.gql.result.json)

  max=${nodes[0]}
  for node in "${nodes[@]}"
  do
      if [[ "$node" -gt "$max" ]]; then
          g_nodeId="$node"
      fi
  done
      if [ -n "$g_nodeId" ]; then
        break
      fi
done
}

ask_for_credentials() {
    if [[ -z $g_connectionString || -z $g_password || -z $g_remotePath || -z $g_backupTarget || -z $g_user ]]; then
        [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
        echo "there is no remote target, password or remote path entered"
        read -t "$g_timeout" -r -p "Enter backup target type (scp,cifs,usb)', you have $g_timeout seconds!: " g_backupTarget;
        if [ "$g_backupTarget" != "usb" ]; then
                if [ "$g_backupTarget" = "cifs" ]; then
                    read -t "$g_timeout" -r -p "Enter remote e.g '//10.0.0.2', you have $g_timeout seconds!: " g_connectionString;
                elif [ "$g_backupTarget" = "scp" ]; then
                    read -t "$g_timeout" -r -p "Enter remote e.g '10.0.0.2', you have $g_timeout seconds!: " g_connectionString;
                fi
            read -t "$g_timeout" -r -p "Enter remote user, you have $g_timeout seconds!: " g_user;
            read -t "$g_timeout" -r -p "Enter remote password, you have $g_timeout seconds!: " g_password;
            read -t "$g_timeout" -r -p "Enter remotepath e.g '/home/user/seedbackup/', you have $g_timeout seconds!: " g_remotePath;
        elif [ "$g_backupTarget" = "usb" ];  then
         echo "Target is $g_backupTarget"
        fi
        [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    fi
    if [[ -z $g_connectionString || -z $g_password || -z $g_remotePath || -z $g_backupTarget || -z $g_user ]]; then
        if [ "$g_backupTarget" != "usb" ]; then
            write_color "fail" "there is no backup type/target, password or remote path entered"
            termination
        fi
    fi
}

ask_for_nodeid() {
if [ "$g_backupMode" != "quick" ]; then
    if [ -z "$g_nodeId" ]; then
        [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
        read -t "$g_timeout" -r -p "Enter nodeid, you have $g_timeout seconds!: " g_nodeId ;
        [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    fi
fi  
}

ask_for_farmid() {
    if [ -z "$g_farmId" ]; then
        [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
        read -t "$g_timeout" -r -p "Enter farmid, you have $g_timeout seconds!: " g_farmId ;
        [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    fi
}

termination() {
    write_color "fail" "Program terminated!"
    write_color "fail" "you can restart the script in the following window!"
    exit 1
}

write_help() {
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo "-------------------------------------------------------------------"
    echo "Helptext of the $0"
    echo "Syntax: $0 [options][targets][parameters]"
    echo "at least one of the options b,q,c,m must be specified"
    echo "at least one of the targets u,s,f must be specified"
    echo "OPTIONS:"
    echo "h -> This helptext"
    echo "q -> Just backup with all params we have without asking user (parameters have to be passed to script e.g. thru isolinux config)"
    echo "b -> Backup and try to get all necessary infos from all given sources and ask user if some infos are missing"
    echo "c -> Preconfigured backup, tries to get all necessary infos out of file located in /run/live/medium/live/backupnode.config.json"
    echo "m -> Backup on my own (shell)"
    echo "TARGETS:"
    echo "u -> Backuptarget = USB -> NOT IMPLEMENTED AT THE MOMENT <-"
    echo "s -> Backuptarget = SCP (you must also specify SCP parameters)"
    echo "f -> Backuptarget = CIFS (you must also specify CIFS parameters)"
    echo "PARAMETERS:"
    echo "n -> nodeId for the naming of the backupfile (write < -n 'date'> of you want to use actual datetime for naming)"
    echo "     [ -n <node id> ] | [ -n date ]"
    echo "d -> chmod the backupfile to your choosen mod like for example 777 (default disabled)"
    echo "     -d <integers>"
    echo "o -> chown the backupfile to a user (default disabled)"
    echo "     -o <user>"
    echo "t -> scp or cifs target string like //10.0.0.2 or 10.0.0.2"
    echo "     -t <address>"
    echo "a -> scp or cifs user"
    echo "     -p <password>"
    echo "p -> scp or cifs password"
    echo "     -p <password>"
    echo "r -> scp or cifs remotepath"
    echo "     -r </tmp/folder/>"
    echo "y -> Turn on config file for -q and -b options or Overwrite the location of the json configfile as described in option -c"
    echo "     [ -y /tmp/folder/file.json ]|[ -y ]"
    echo "x -> get nodeId from tf-graphQL-API based on NIC-MAC for backupfile naming"
    echo "     -x"
    echo "g -> get nodeId from tf-graphQL-API based on NIC-MAC for backupfile naming and set your farmID"
    echo "     -g <farm id>"
    echo "z -> timeout for user inputs in seconds (default 30)"
    echo "     -z <seconds>"
    echo "-------------------------------------------------------------------"
    echo "made by omniflow [https://github.com/fl0wm0ti0n]"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
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

# root_menue() {
#     TMP="$(mktemp /tmp/menu.XXXXXX)"
#     trap "[ -f ""$TMP"" ] && rm -f $TMP" HUP INT QUIT TERM EXIT
#     $DIA --backtitle "TESTOIDA" --title "$" --menu "$msg_choose_mode:" 0 0 0 \
#     "quick"  "fast as possible" \
#     "backup"  "Backup default mode" \
#     "config" "full automated via config" \
#     "shell" "manually" \
#     2> "$TMP"
#     mode="$(cat "$TMP")"
#     [ -f "$TMP" ] && rm -f "$TMP"

#     case "$mode" in
#     quick)
#         echo "quick";;
#     backup)
#         echo "backup";;
#     config)
#         echo "config";;
#     shell)
#         echo "shell";;
#     *)
#         termination
#     esac
# }

copy_to_target() {
    seedName=$1

    case "$g_backupTarget" in
    "scp")
        copy_via_scp "$seedName" 
        ;;
    "cifs")
        copy_via_cifs "$seedName"
        ;;
    "usb")
        copy_via_usb "$seedName"
        ;;
    *)
        write_color "fail" "there is no backup target given"
        termination
    esac
}

decide_how_done() {
    local seedName
    local seedPath
    local disk

    case "$g_backupMode" in
        "quick")
        # just backup with all params we have without asking user (parameters have to be passed to script e.g. thru isolinux config)
            # 1. if useconfig=true. overwrite all credentials            
            if [ "$g_config" = "true" ]; then
                read_config
            fi
            # 2. try getting nodeid from tf GQL api
            if [ "$g_gqlNaming" = "true" ] && [ "$g_farmId" != "" ]; then
                get_nodeid_from_grid
            fi
            # 3. steps as usual
            backup_seed_routine "$seedPath" "$disk"
            # 4. rename
            rename_seed "$seedPath" "$seedName"
            umount_disk "$disk"
            # 5. copy to
            copy_to_target "$seedName"
        ;;
        "backup")
        # backup and try to get every needed info from all sources and ask user if some infos are missing
            # 1. if useconfig=true. overwrite all credentials
            if [ "$g_config" = "true" ]; then
                read_config
            fi
            # 2. check if target and params are set and ask user
            ask_for_credentials
            # 3. try getting nodeid from tf GQL api
            if [ "$g_gqlNaming" = "true" ]; then
                ask_for_farmid
                get_nodeid_from_grid
            fi
            # 4. check if nodeid is set and ask user
            if [ "$g_nodeId" != "date" ]; then
                ask_for_nodeid
            fi
            # 5. steps as usual
            backup_seed_routine "$seedPath"
            # 6. rename
            rename_seed "$seedPath" "$seedName"
            umount_disk "$disk"
            # 7. copy to
            copy_to_target "$seedName"
        ;;
        "config")
        # just use config file and not more - the fastes option since you have preconfigured well
            # 1. if useconfig=true
            read_config
            # 2. try getting nodeid from tf GQL api
            if [ "$g_gqlNaming" = "true" ]; then
                ask_for_farmid
                get_nodeid_from_grid
            fi
            # 3. check if nodeid is set and ask user
            if [ "$g_nodeId" != "date" ]; then
                ask_for_nodeid
            fi
            # 4. steps as usual
            backup_seed_routine "$seedPath"
            # 5. rename
            rename_seed "$seedPath" "$seedName"
            umount_disk "$disk"
            # 6. copy to
            copy_to_target "$seedName"
        ;;
        "shell")
            # exit to shell
            exit 0
        ;;
        *)
            write_help
    esac
}

##################
###### MAIN ######
##################
    
    echo "Starting up $0"
    g_tempMntFolder="/mnt/nodedisk"
    g_tempUsbMntFolder="/mnt/usb"
    g_tempCifsMntFolder="/mnt/cifs"
    g_tempSeedFolder="/tmp/seed"
    g_defaultSeedPath="/zos-cache/modules/identityd"
    g_graphQlApi="https://graphql.grid.tf/graphql"
    g_configPath="/run/live/medium/live/backupconfig.json"
    g_timeout=30

    g_nodeId=""
    g_connectionString=""
    g_remotePath=""
    g_user=""
    g_password=""
    g_backupMode=""
    g_backupTarget=""
    g_chown=""
    g_chmod=""
    g_gqlNaming=false
    g_farmId=""
    g_config=false
    g_useDateTimeNaming=false

while getopts 'bqcmn:usfd:o:t:a:p:r:y:xg:z:h:' OPTION; do
case "${OPTION}" in
    b)
        echo "Default Backup Mode choosen"
        g_backupMode="backup"
    ;;
    q)
        echo "Quick Mode choosen"
        g_backupMode="quick"
    ;;
    c)
        echo "preconfigured Backup Mode choosen"
        g_backupMode="config"
    ;;
    m)
        echo "Manuall Backup Mode choosen (shell)"
        g_backupMode="shell"
    ;;
    n) 
        g_nodeId="$OPTARG"
        echo "The provided nodeid is $OPTARG"
    ;;
    u)
        echo "USB as Backuptarget choosen"
        g_backupTarget="usb"
        write_color "fail" "not implemented! be patient im working on it"
        termination
    ;;
    s)
        echo "SCP as Backuptarget choosen"
        g_backupTarget="scp"
    ;;
    f)
        echo "CIFS as Backuptarget choosen"
        g_backupTarget="cifs"
    ;;
    d)
        g_chmod="$OPTARG"
        echo "chmod to $OPTARG after copying to target path"
    ;;
    o)
        g_chown="$OPTARG"
        echo "chown to $OPTARG after copying to target path"
    ;;
    t)
        g_connectionString="$OPTARG"
        echo "connectionString = $OPTARG"
    ;;
    a)
        g_user="$OPTARG"
        echo "user = $OPTARG"
    ;;
    p)
        g_password="$OPTARG"
        echo "password = $OPTARG"
    ;;
    r)
        g_remotePath="$OPTARG"
        echo "remotepath = $OPTARG"
    ;;
    y)
        g_config=true
        confpath=$OPTARG
        if [ "$confpath" != "" ]; then
            g_configPath="$confpath"
        fi
        echo "Using different path for the configfile $OPTARG"
    ;;
    x)
        g_gqlNaming=true
        echo "trying to get nodeId from tf-graphQL-API based on NIC-MAC for backupfile naming"
    ;;
    g)
        g_farmId="$OPTARG"
        g_gqlNaming=true
        echo "trying to get nodeId from tf-graphQL-API based on NIC-MAC for backupfile naming"
    ;;
    z)
    g_timeout="$OPTARG"
    echo "set input timeout is $OPTARG seconds"
    ;;
    h)
        write_help
    ;;
    ?)
        write_help
    ;;
    *)
        write_help
    ;;
esac
done
shift "$((OPTIND -1))"

# 
# config set?
decide_how_done