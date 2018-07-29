
[ -f test.qcow2 ] || qemu-img create -f qcow2 test.qcow2 20G

qemu-kvm -cdrom FWS-bringout.iso -hda test.qcow2  -vga qxl -m 2048
