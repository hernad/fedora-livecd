#!/bin/bash

setenforce 0

livecd-creator --verbose \
  --config=flat-live-workstation.ks \
  --fslabel=Fedora-bringout \
  --cache=/var/cache/live
