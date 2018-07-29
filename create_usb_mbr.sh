#!/bin/bash

DISK=/dev/sdd

echo "${DISK} partition bios, bootable(a) partition"
echo "mkfs.vfat -n FWS /dev/${DISK)1"

sudo umount /dev/${DISK}1
sudo livecd-iso-to-disk --reset-mbr FWS-bringout.iso  /dev/${DISK}1

