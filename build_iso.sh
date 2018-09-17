#!/bin/bash

setenforce 0

KS=flat-live-workstation.ks
#KS=flat-rawhide.ks
#KS=flat-vanilla.ks
#KS=centos/centos-gnome.ks

ISO=FWS-bringout
#ISO=FWS-bringout-rawhide

livecd-creator --verbose \
  --config=$KS \
  --fslabel=$ISO \
  --cache=/var/cache/live
