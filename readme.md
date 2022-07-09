# TfNodeBackupTool
Tool to maintain your Threefold Nodes 

Features:
- [x] Nice Isolinux menue
- [x] Script startparameters 
- [x] boot as ISO
- [ ] boot as USB-Key
- [ ] boot via PXE
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
This is a collection of scripts which are made bootable together with Clonezilla, and  a nice Isolinux menue.
Mainly you can boot it with an USB-Key, a PXE-Server or as ISO for example as Virtual Disk over an server Webinterface like ILO from HPE 

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

## how to start

### ISO File

### USB Key

### PXE Server

## default options

## configure it as you wish

## preconfigure it for full automation

## HowTo create a custom CloneZilla whit your ownm scripts?