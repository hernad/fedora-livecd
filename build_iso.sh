#!/bin/bash

setenforce 0

#KS=flat-live-workstation.ks
KS=flat-vanila.ks

livecd-creator --verbose \
  --config=$KS \
  --fslabel=FWS-bringout \
  --cache=/var/cache/live
