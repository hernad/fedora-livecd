#!/bin/bash
sudo umount /dev/sdb1
sudo livecd-iso-to-disk --efi --format FWS-bringout.iso  /dev/sdb
