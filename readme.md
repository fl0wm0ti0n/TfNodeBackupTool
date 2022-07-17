# Threefold NodeMaintainTool
Tool to maintain your Threefold Nodes.\
This Tool uses sources from Clonezilla as base!\
clonezilla.org, clonezilla.nchc.org.tw\
THIS SOFTWARE COMES WITH ABSOLUTELY NO WARRANTY! USE AT YOUR OWN RISK!\
\
Some Features are only tested with virtual nodes! Feel free to test it or to help in any kind! Any ideas are welcome! Thanks!\
If you get stuck by using the docu please feel free too contact me!
\
\
**Features:**
- [x] backup nodeseed
- [x] wipe disks
- [x] shell
- [x] memorytest
- [x] Nice Isolinux menue
- [x] Script startparameters 
- [x] boot with an ISO
- [x] boot via PXE
- [x] Search nodeseed on disks
- [x] Save Nodeseed on...
  - [ ] USB-Key
  - [x] Remote SCP
  - [x] Remote CIFS Share
- [x] Backupnaming
  - [x] Get NodeId from GraphQl over NIC MAC
  - [x] Enter NodeId if needed
  - [x] Is automatically choosing DateTime as Backupname if no NodeID is present.
- [x] json configuration for automatically backupping the nodeseed


## intro
This is a collection of scripts which are made bootable together with Clonezilla, and a nice Isolinux menue. You can backup your nodeseed, this is a tiny file on one of your nodedisks. It is used to identify your node. You can use that file to recreate your node elswhere. Or if you want to wipe all your disks so you can rfestore your node again. Furthermore you can wipe all your disks full automated, make a memorytest or just go into the shell to make your own stuff.

The aim is to boot it with an USB-Key, a PXE-Server or as ISO for example as Virtual Disk over an server Webinterface like iLO from HPE 

There are some nice features like, it searches in the ThreeFold GraphQL API for your Nodename. Or you can preconfigure a config.json so you dont have to enter something and the backup will be full automated. Put that on to a PXE-Server and you can backup over a hundred nodes just with one click.

If you just want to quick backup or wipe some nodes just download the ISO file and use it with an USb-key or you use one of the nice virtual media functions of one of the server-managers out there (iLO, iDRAC, IMM).

## Getting started
The easiest way is to simply use the already done files uploaded under [release](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/tree/master/release)
To create a bootable device out of an image or an iso i can recommend [balenaEtcher](https://www.balena.io/etcher/)

Attention! There are by now only two Keyboard layouts, german and english.

### Boot with ISO File
Is used to create an USB-Key, burn a CD or to boot it over the boot-virtualmedia function from one of the server-managers out there (iLO, iDRAC, IMM).

Just boot your server with it.

### Boot with Legacy PXE (TFTP) Server
NOT TESTED RIGHT NOW! ~~tested it with the TFTP Debian server~~

After you have installed the TFTP Server like in the next header described, you have to...

First copy the whole content of [syslinux](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/tree/master/Raw_ThreefoldNodeMaintainTool/syslinux) except the *cfg files to `/srv/tftp/`

Download the files...
1. [vmlinuz](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/blob/master/Raw_ThreefoldNodeMaintainTool/live/vmlinuz)
2. [initrd.img](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/blob/master/Raw_ThreefoldNodeMaintainTool/live/initrd.img)
3. [filesystem.squashfs](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/blob/master/Raw_ThreefoldNodeMaintainTool/live/filesystem.squashfs)

...and copy them to `/srv/tftp/` 

1. Next download the menue 
   1. DE Layout -> [pxelinux.cfg](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/blob/master/CustomMenue/de_layout/pxelinux.cfg)
   2. EN Layout -> [pxelinux.cfg](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/blob/master/CustomMenue/en_layout/pxelinux.cfg)
2. Rename it to `default` and copy it to `/srv/tftp/pxelinux.cfg/`, at end it should be like `/srv/tftp/pxelinux.cfg/default`
3. Change the addresses in the renamed pxelinux.cfg
   1. there `fetch=tftp://<IPAdress of the PXE Server>/filesystem.squashfs` 
   2. and there `ocs_prerun="busybox tftp -g -r backupnode.sh -l /tmp/backupnode.sh <IPAdress of the PXE Server>"`


#### Set up your PXE Server
[Original PXE HowTo for Debian](https://wiki.debian.org/PXEBootInstall)

**Simply you just have to run followed things:**\
```
apt-get update
apt-get install tftpd-hpa

cd /srv/tftp/
wget http://ftp.nl.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/netboot.tar.gz
wget http://ftp.nl.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/pxelinux.0
tar -xvzf netboot.tar.gz
rm version.info netboot.tar.gz 
service tftpd-hpa restart
```

On the DHCP server make sure you enable "network booting" for example in "opnSense" you just have to enter 
1. `Set next-server IP = <IPAdress of the PXE Server>`
2. `Set default bios filename = pxelinux.0`

### Boot with UEFI PXE (TFTP) Server
coming soon
## Backup targets
### SCP
Is simple to use if you want to backup the nodeseeds to a linux host. Mainly you need to allow ssh access

### CIFS (SMB)
Is simple to use if you want to backup the nodeseeds to a windows host. Mainly you need to share an folder over network
Many Unix NAS-distros allow that too, I for example use an [OMV Server](https://www.openmediavault.org/) for all my file things in my network. 

### USB
coming soon

## default menue options
The default isolinux menue is just a collection of different start parameters with which the script is started.

There are following preconfigured menuentries after booting the tool

1. Quick backup the seed, just get asked for saving target (VGA 800x600) 
   1. Startparameters: `/run/live/medium/live/backupnode.sh -b -n date`
   2. Description: Quick backup the seed, just get asked for saving target (scp, cifs or usb), hit tab to add options like chomd, chown, timeout. You have to Enter: Backuptarget parameters

2. Quick backup the seed, try to get nodeid over TF GraphQL API (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/backupnode.sh -b -x`
   2. Description: Quick backup the seed, try to get nodeid over TF GraphQL API. You have to specify the farmId. You have to Enter: Backuptarget parameters, your farmId

3. Quick backup the seed, get asked for saving target and filename (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/backupnode.sh -b`
   2. Description: Quick backup the seed, get asked for saving target (scp, cifs or usb) and nodeid for filename. You have to Enter: Backuptarget parameters, nodeId

1. Preconfigured Backup the seed with jsonfile (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/backupnode.sh -c`
   2. Description: If configured this is the fastes option since you have nothing to fill in. Configure it in root\live\backupnode.config.json where root is the root on USB, ISO or a PXE folder. For ISO you have to run mkisofs to build the ISO out of the raw folder. You have to Enter: Nothing since it is preconfigured

2. Just the Shell, to everything manually (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/backupnode.sh -m`
   2. Description: Just the Shell, to everything manually. DHCP is active! You can also access the scripts in /run/live/medium/live/

3. Wipe all disks (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/wipenode.sh`
   2. Description: Wipe all disks except USB. You have to Enter: Nothing since it wipes everything

4. Wipe disks manually (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/wipenode.sh -m`
   2. Description: Wipe disks manually. The disks will be listed, you can select to wipe it. You have to Enter: choose your disks

5. Wipe disks manually TESTRUN (VGA 800x600)
   1. Startparameters: `/run/live/medium/live/wipenode.sh -m -t`
   2. Description: Wipe disks manually. TESTRUN NOT WIPING FOR REAL. The disks will be listed, you can select to wipe it. You have to Enter: choose your disks

6.  Mount remote cifs filesystem (VGA 800x600)
    1. Startparameters: `/run/live/medium/live/mountcifs.sh`
    2. Description: Mount remote cifs filesystem for developing or testing the script parameters. So you can edit the file on your cifs share on the workstation. You have to Enter: cifs remote parameters

7.  Run memory test using Memtest86+
    1.  Startparameters: `kernel /live/memtest`

8.  Run FreeDOS
    1.  Startparameters: `initrd=/live/freedos.img`


## the "backupnode.sh" script's parameters'
You can start the script as you want... or change the parameters if you are in the isolinux menue hit "tab" and enter somethign new.

```
Syntax: backupnode.sh [options][targets][parameters]"
at least one of the option
s b,q,c,m must be specified"
at least one of the targets u,s,f must be specified"
OPTIONS:"
h -> This helptext"
q -> Just backup with all params we have without asking user (parameters have to be passed to script e.g. thru isolinux config)"
b -> Backup and try to get all necessary infos from all given sources and ask user if some infos are missing"
c -> Preconfigured backup, tries to get all necessary infos out of file located in /run/live/medium/live/backupnode.config.json"
m -> Backup on my own (shell)"
TARGETS:"
u -> Backuptarget = USB -> NOT IMPLEMENTED AT THE MOMENT <-"
s -> Backuptarget = SCP (you must also specify SCP parameters)"
f -> Backuptarget = CIFS (you must also specify CIFS parameters)"
PARAMETERS:"
n -> nodeId for the naming of the backupfile (write < -n 'date'> of you want to use actual datetime for naming)"
     [ -n <node id> ] | [ -n date ]"
d -> chmod the backupfile to 777 (default disabled)"
o -> chown the backupfile to a user (default disabled)"
     -o <user>"
t -> scp or cifs target string like //10.0.0.2 or 10.0.0.2"
     -t <address>"
a -> scp or cifs user"
     -p <password>"
p -> scp or cifs password"
     -p <password>"
r -> scp or cifs remotepath"
     -r </tmp/folder/>"
y -> Turn on config file for -q and -b options or Overwrite the location of the json configfile as described in option -c"
     [ -y /tmp/folder/file.json ]|[ -y ]"
x -> get nodeId from tf-graphQL-API based on NIC-MAC for backupfile naming, set your farmID"
     -x <farm id>"
z -> timeout for user inputs in seconds (default 30)"
     -z <seconds>"
```

## preconfigure it for full automation
If you want to full automate your backup. Just edit the backupnode.json which is in one of the release ISOs

So download a [release](https://github.com/fl0wm0ti0n/ThreefoldNodeMaintainTool/tree/master/release) un-archive it and edit the json file.
Next build it back to a ISO again. You can aproach that with `mkisofs -o <output.iso> -b syslinux/isolinux.bin -c syslinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table <inputfolder>`

Hint: The mkisofs you can also use with Windows WSL, but there are also some Windows-Tools which are similar but i haven't tested them. Feel free to try and help make this repo more completely


json content example:
```json
{
    "useconfig":true,
    "farmId":403,
    "_comment1": "tries to get NodeId connected with the mac from NIC over the graphQL API, you can enter it manually if it doesnt find it or it chooses to name after DateTime.",
    "tryGetNodeNrFromGrid":true,
    "_comment2": "Use DateTime as naming",
    "useDateTimeNaming":false,
    "_comment3": "empty is disabled, put chmod modus in here",
    "chmod":777,
    "_comment4": "empty is disabled, put username in here",
    "chown":"user",
    "_comment5": "timeout for inputs",
    "timeout":30,
    "_comment6": "possible is usb,scp,cifs,ftp",
    "backupTarget":"scp",
    "remotes":[
        {
            "remoteType":"scp",
            "user":"user",
            "password":"password",
            "connectionString":"10.0.0.2",
            "remotePath":"/tmp/"
        },
        {
            "remoteType":"ftp",
            "user":"user",
            "password":"password",
            "connectionString":"10.0.0.2",
            "remotePath":"/tmp/"
        },
        {
            "remoteType":"cifs",
            "user":"user",
            "password":"password",
            "connectionString":"//10.0.0.2/Daten",
            "remotePath":"/Backups/NodeBackups/"
        }
    ]
}
```

## HowTo create a custom CloneZilla whit your ownm scripts?
coming soon..