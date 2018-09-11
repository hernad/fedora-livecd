
# https://pagure.io/fedora-kickstarts/blob/f28/f/fedora-live-workstation.ks
# /usr/share/doc/lorax/fedora-livemedia.ks
# ksflatten (pykickstart rpm)

# https://gitlab.gnome.org/GNOME/gnome-initial-setup/blob/master/HACKING


#To enable the initial-setup functionality in gdm, set

#InitialSetupEnable=True

# in the [daemon] section of /etc/gdm/custom.conf. To actually trigger the initial-setup, 
# gdm additionally looks for the file /var/lib/gdm/run-initial-setup. gdm removes this file after
# the initial setup has been performed.

# Normally, it is not possible to return to Initial Setup after you close it and log in to the system. 
# You can make it display again (after the next reboot, before a login prompt is displayed), 
# by executing the following command as root:
# systemctl enable initial-setup-graphical.service


#version=DEVEL
# X Window System configuration information
xconfig  --startxonboot
# Keyboard layouts
keyboard 'us'






#Sets the system's root password to the password argument.
#rootpw [--iscrypted|--plaintext] [--lock] password
#--iscrypted - If this option is present, the password argument is assumed to already be encrypted. This option is mutually exclusive with --plaintext. 
# To create an encrypted password, you can use python:
# $ python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
# This generates a sha512 crypt-compatible hash of your password using a random salt.
#--plaintext - If this option is present, the password argument is assumed to be in plain text. This option is mutually exclusive with --iscrypted.
#--lock - If this option is present, the root account is locked by default. This means that the root user will not be able to log in from the console. 
# This option will also disable the Root Password screens in both the graphical and text-based manual installation.

# Root password
#rootpw --iscrypted --lock locked
rootpw --iscrypted $6$rCvQg9SOy6iA.dPp$9S6LKo6NU4Npr2iL.2mvdxAAeQFy3.1jJ9mURq8w6SZeAjCOMaEagiDDNrXtX23ZpNB9RUZltqSOkQFeLH3dN0



# System language
lang en_US.UTF-8
# Shutdown after installation
shutdown
# System timezone
timezone Europe/Sarajevo
# Network information
network  --bootproto=dhcp --device=link --activate
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

repo --name=rpmfusionfree --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch
repo --name=rpmfusionfreeupdates --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch
repo --name=rpmfusionnonfree --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name=rpmfusionnonfreeupdate --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch

repo --name="google" --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
repo --name="vscode" --baseurl=https://packages.microsoft.com/yumrepos/vscode
repo --name="nodejs" --baseurl=https://rpm.nodesource.com/pub_10.x/fc/$releasever/$basearch

# Use network installation
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"
# System authorization information
auth --useshadow --passalgo=sha512
# Firewall configuration
firewall --enabled --service=mdns,ssh
# SELinux configuration
selinux --enforcing

# System services
services --enabled="NetworkManager,ModemManager,sshd"
# System bootloader configuration

# hernad nouveau asuszenbook freeze
bootloader --location=none --append="nouveau.modeset=0"

# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="ext4" --size=8192
#part / --size=9656

%post
# FIXME: it'd be better to get this installed from a package
cat > /etc/rc.d/init.d/livesys << EOFLIVESYS
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.
### BEGIN INIT INFO
# X-Start-Before: display-manager chronyd
### END INIT INFO

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ]; then
    exit 0
fi

if [ -e /.liveimg-configured ] ; then
    configdone=1
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

livedir="LiveOS"
for arg in \`cat /proc/cmdline\` ; do
  if [ "\${arg##rd.live.dir=}" != "\${arg}" ]; then
    livedir=\${arg##rd.live.dir=}
    return
  fi
  if [ "\${arg##live_dir=}" != "\${arg}" ]; then
    livedir=\${arg##live_dir=}
    return
  fi
done

# enable swaps unless requested otherwise
swaps=\`blkid -t TYPE=swap -o device\`
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -n "\$swaps" ] ; then
  for s in \$swaps ; do
    action "Enabling swap partition \$s" swapon \$s
  done
fi
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -f /run/initramfs/live/\${livedir}/swap.img ] ; then
  action "Enabling swap file" swapon /run/initramfs/live/\${livedir}/swap.img
fi

mountPersistentHome() {
  # support label/uuid
  if [ "\${homedev##LABEL=}" != "\${homedev}" -o "\${homedev##UUID=}" != "\${homedev}" ]; then
    homedev=\`/sbin/blkid -o device -t "\$homedev"\`
  fi

  # if we're given a file rather than a blockdev, loopback it
  if [ "\${homedev##mtd}" != "\${homedev}" ]; then
    # mtd devs don't have a block device but get magic-mounted with -t jffs2
    mountopts="-t jffs2"
  elif [ ! -b "\$homedev" ]; then
    loopdev=\`losetup -f\`
    if [ "\${homedev##/run/initramfs/live}" != "\${homedev}" ]; then
      action "Remounting live store r/w" mount -o remount,rw /run/initramfs/live
    fi
    losetup \$loopdev \$homedev
    homedev=\$loopdev
  fi

  # if it's encrypted, we need to unlock it
  if [ "\$(/sbin/blkid -s TYPE -o value \$homedev 2>/dev/null)" = "crypto_LUKS" ]; then
    echo
    echo "Setting up encrypted /home device"
    plymouth ask-for-password --command="cryptsetup luksOpen \$homedev EncHome"
    homedev=/dev/mapper/EncHome
  fi

  # and finally do the mount
  mount \$mountopts \$homedev /home
  # if we have /home under what's passed for persistent home, then
  # we should make that the real /home.  useful for mtd device on olpc
  if [ -d /home/home ]; then mount --bind /home/home /home ; fi
  [ -x /sbin/restorecon ] && /sbin/restorecon /home
  if [ -d /home/liveuser ]; then USERADDARGS="-M" ; fi
}

findPersistentHome() {
  for arg in \`cat /proc/cmdline\` ; do
    if [ "\${arg##persistenthome=}" != "\${arg}" ]; then
      homedev=\${arg##persistenthome=}
      return
    fi
  done
}

if strstr "\`cat /proc/cmdline\`" persistenthome= ; then
  findPersistentHome
elif [ -e /run/initramfs/live/\${livedir}/home.img ]; then
  homedev=/run/initramfs/live/\${livedir}/home.img
fi

# if we have a persistent /home, then we want to go ahead and mount it
if ! strstr "\`cat /proc/cmdline\`" nopersistenthome && [ -n "\$homedev" ] ; then
  action "Mounting persistent /home" mountPersistentHome
fi

if [ -n "\$configdone" ]; then
  exit 0
fi

# add liveuser user with no passwd
action "Adding live user" useradd \$USERADDARGS -c "Live System User" liveuser
passwd -d liveuser > /dev/null
usermod -aG wheel liveuser > /dev/null

# Remove root password lock
passwd -d root > /dev/null

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service 2> /dev/null || :
systemctl --no-reload disable firstboot-graphical.service 2> /dev/null || :
systemctl stop firstboot-text.service 2> /dev/null || :
systemctl stop firstboot-graphical.service 2> /dev/null || :

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || :

# turn off mdmonitor by default
systemctl --no-reload disable mdmonitor.service 2> /dev/null || :
systemctl --no-reload disable mdmonitor-takeover.service 2> /dev/null || :
systemctl stop mdmonitor.service 2> /dev/null || :
systemctl stop mdmonitor-takeover.service 2> /dev/null || :

# don't enable the gnome-settings-daemon packagekit plugin
gsettings set org.gnome.software download-updates 'false' || :


# don't start cron/at as they tend to spawn things which are
# disk intensive that are painful on a live image
systemctl --no-reload disable crond.service 2> /dev/null || :
systemctl --no-reload disable atd.service 2> /dev/null || :
systemctl stop crond.service 2> /dev/null || :
systemctl stop atd.service 2> /dev/null || :

# Don't sync the system clock when running live (RHBZ #1018162)
sed -i 's/rtcsync//' /etc/chrony.conf

# Mark things as configured
touch /.liveimg-configured

# add static hostname to work around xauth bug
# https://bugzilla.redhat.com/show_bug.cgi?id=679486
# the hostname must be something else than 'localhost'
# https://bugzilla.redhat.com/show_bug.cgi?id=1370222
echo "localhost-live" > /etc/hostname


EOFLIVESYS

# bah, hal starts way too late
cat > /etc/rc.d/init.d/livesys-late << EOF
#!/bin/bash
#
# live: Late init script for live image
#
# chkconfig: 345 99 01
# description: Late init script for live image.

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ] || [ -e /.liveimg-late-configured ] ; then
    exit 0
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

touch /.liveimg-late-configured

# read some variables out of /proc/cmdline
for o in \`cat /proc/cmdline\` ; do
    case \$o in
    ks=*)
        ks="--kickstart=\${o#ks=}"
        ;;
    xdriver=*)
        xdriver="\${o#xdriver=}"
        ;;
    esac
done

# liveuser tap to click
sudo -u liveuser gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
sudo -u liveuser gsettings set org.gnome.desktop.interface clock-show-date true

# if liveinst or textinst is given, start anaconda live installer
if strstr "\`cat /proc/cmdline\`" liveinst ; then
   plymouth --quit
   /usr/sbin/liveinst --lang us --geoloc 0 \$ks
fi
if strstr "\`cat /proc/cmdline\`" textinst ; then
    plymouth --quit
   /usr/sbin/liveinst --text --lang us --geoloc 0 \$ks
fi


# configure X, allowing user to override xdriver
if [ -n "\$xdriver" ]; then
   cat > /etc/X11/xorg.conf.d/00-xdriver.conf <<FOEX
Section "Device"
	Identifier	"Videocard0"
	Driver	"\$xdriver"
EndSection
FOEX
fi

EOF

chmod 755 /etc/rc.d/init.d/livesys
/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

chmod 755 /etc/rc.d/init.d/livesys-late
/sbin/restorecon /etc/rc.d/init.d/livesys-late
/sbin/chkconfig --add livesys-late

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
echo "Packages within this LiveCD"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb


# hernad post ==

#https://fedoramagazine.org/add-power-terminal-powerline/

# home templates
mkdir -p /etc/home_tmpl
cat >> /etc/home_tmpl/.tmux.conf << EOFTMUX
source "/usr/share/tmux/powerline.conf"
EOFTMUX

cat >> /etc/home_tmpl/.bashrc << EOFBASHRC
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
if [ -f \`which powerline-daemon\` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
EOFBASHRC

cat >> /etc/home_tmpl/.vimrc << EOFVIMRC
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup
set laststatus=2 " Always display the statusline in all windows
set showtabline=2 " Always display the tabline, even if there is only one tab
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)
set t_Co=256
EOFVIMRC

mkdir -p /etc/home_tmpl/.config/gtk-3.0
cat >> /etc/home_tmpl/.config/gtk-3.0/gtk.css << EOFCSS
scrollbar slider {
    /* Size of the slider */
    min-width: 20px;
    min-height: 20px;
    border-radius: 22px;

    /* Padding around the slider */
    border: 5px solid transparent;
}
EOFCSS

cat >> /usr/local/bin/setup_user_after_install.sh << EOFSETUPUSER
#!/bin/bash

gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.interface clock-show-date true

#for f in /etc/home_tmpl ; do
#   cp -v $f ~/
#done
rsync -avz /etc/home_tmpl/ ~/

if [ -n "\$USERNAME" ] ; then
  chown -R \$USERNAME:\$USERNAME ~
  echo set \$USERNAME as libvirt group member
  sudo usermod -aG libvirt \$USERNAME

  echo set \$USERNAME as wheel group memmber
  sudo usermod -aG wheel \$USERNAME

  echo set \$USERNAME sudo without password enabled 
  echo "\$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee --append  /etc/sudoers
fi

if sudo dmidecode | grep -i N501VW ; then
   echo ============ asus zenbook N501VW fix grub =================
   if ! grep "i915\.enable_execlists=0" /etc/default/grub ; then
     sudo sed -i -e  's/GRUB_CMDLINE_LINUX=\"\(.*\)\"/GRUB_CMDLINE_LINUX="\1 nouveau.modeset=0 i915.enable_execlists=0 acpi_osi=\! acpi_osi=\\\"Windows 2009\\\""/' /etc/default/grub
   fi
   sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
   echo ========== asus zenbook install bumblebee nvidia https://fedoraproject.org/wiki/Bumblebee  ==================
   sudo dnf -y config-manager --add-repo=https://negativo17.org/repos/fedora-nvidia.repo
   sudo dnf -y install nvidia-driver kernel-devel akmod-nvidia dkms acpi
   sudo dnf -y copr enable chenxiaolong/bumblebee
   sudo dnf -y install akmod-bbswitch bumblebee primus
   sudo gpasswd -a \$USERNAME bumblebee
   sudo systemctl enable bumblebeed
   sudo systemctl disable nvidia-fallback
fi

echo set up gdm auto-login for user: \$USERNAME

cat > /tmp/custom.conf << FOEB
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=\$USERNAME
FOEB
sudo cp /tmp/custom.conf /etc/gdm/custom.conf
EOFSETUPUSER

chmod +x /usr/local/bin/setup_user_after_install.sh

cat /etc/resolv.conf
ping -c 1 8.8.8.8

cat >> /etc/resolv.conf << EOFRESOLV
nameserver 8.8.8.8
EOFRESOLV

ping -c 1 www.google.ba

rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub com.jgraph.drawio.desktop
# pivot_root: Invalid argument
#flatpak install -y flathub com.viber.Viber
 
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

#dnf check-update
#sudo dnf install code

curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -

curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
dnf -y install yarn


## disable printing daemons 
# chkconfig cups off

# hernad post end ==


# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
/sbin/chkconfig network off

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# off libvirt inside livecd
/sbin/chkconfig libvirtd off

%end


# --nochroot
# Allows you to specify commands that you would like to run outside of the chroot environment.
# The following example copies the file /etc/resolv.conf to the file system that was just installed.
#
# $INSTALL_ROOT is for the root of the filesystem of the LiveCD that will eventually be compressed. 
# This is where all of the packages get installed during the build process. 
# Use this if you want the files on the LiveCD OS filesystem.
# $LIVE_ROOT is the root of the CD. Use this if you want the files available without having to boot
# to the LiveCD or uncompressing the filesystem on the CD. 
# For example, you would copy files to $LIVE_ROOT if you wanted to be able to put the CD 
# in a running system and see them. As in your post above, /EFI, /isolinux, /LiveOS.
# There is no variable for the root of the installed (host) system. 
# You retain access to it by using the %post --nochroot
# touch $INSTALL_ROOT/this-is-install-root
# touch $LIVE_ROOT/this-is-live-root


%post --nochroot
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
  if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
  cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS
fi


%end

%post

cat >> /etc/rc.d/init.d/livesys << EOFLIVESYS


# disable gnome-software automatically downloading updates
cat >> /usr/share/glib-2.0/schemas/org.gnome.software.gschema.override << FOER
[org.gnome.software]
download-updates=false
FOER

# don't autostart gnome-software session service
rm -f /etc/xdg/autostart/gnome-software-service.desktop

# disable the gnome-software shell search provider
cat >> /usr/share/gnome-shell/search-providers/org.gnome.Software-search-provider.ini << FOEI
DefaultDisabled=true
FOEI

# don't run gnome-initial-setup u livecd rezimu
mkdir ~liveuser/.config
touch ~liveuser/.config/gnome-initial-setup-done

# suppress anaconda spokes redundant with gnome-initial-setup
cat >> /etc/sysconfig/anaconda << FOEA
[NetworkSpoke]
visited=1

[PasswordSpoke]
visited=1

[UserSpoke]
visited=1
FOEA


# Show harddisk install in shell dash
#sed -i -e 's/NoDisplay=true/NoDisplay=false/' /usr/share/applications/liveinst.desktop ""
# need to move it to anaconda.desktop to make shell happy
mv /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop

cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override << FOEOVER
[org.gnome.shell]
favorite-apps=['firefox.desktop', 'org.gnome.Nautilus.desktop', 'anaconda.desktop', 'org.gnome.Terminal.desktop' ]
FOEOVER

# Copy Anaconda branding in place
if [ -d /usr/share/lorax/product/usr/share/anaconda ]; then
    cp -a /usr/share/lorax/product/* /
fi

# rebuild schema cache with any overrides we installed
glib-compile-schemas /usr/share/glib-2.0/schemas

# set up auto-login
cat > /etc/gdm/custom.conf << FOECUSTOM
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
FOECUSTOM

# Turn off PackageKit-command-not-found while uninstalled
if [ -f /etc/PackageKit/CommandNotFound.conf ]; then
  sed -i -e 's/^SoftwareSourceSearch=true/SoftwareSourceSearch=false/' /etc/PackageKit/CommandNotFound.conf
fi

# make sure to set the right permissions and selinux contexts
chown -R liveuser:liveuser /home/liveuser/
restorecon -R /home/liveuser/

# hernad ovo nesto ne radi
#su liveuser -c /usr/local/bin/setup_user_after_install.sh

EOFLIVESYS

# ============= create file liveinst.sh ========================
cat > /usr/local/bin/liveinst.sh << FOELSH
#!/bin/bash

# set hostname before installation
HOSTNAME="fws.bring.out.ba"
if sudo dmidecode | grep -i N501VW ; then
   HOSTNAME="fws-zenbook.bring.out.ba"
fi
if sudo dmidecode | grep -i "Standard PC" ; then
  HOSTNAME="fws-kvm.bring.out.ba"
fi
if sudo dmidecode | grep -i "XPS 13" ; then
  HOSTNAME="fws-xps13.bring.out.ba"
fi

sudo hostnamectl set-hostname \$HOSTNAME
/usr/bin/liveinst --lang us --geoloc 0
FOELSH

chmod +x /usr/local/bin/liveinst.sh

# ============== create/modify file liveinst.desktop (run liveinst.sh) ==============================
cat > /usr/share/applications/liveinst.desktop << FOEDESK
[Desktop Entry]
Name=Install to Hard Drive
GenericName=Install
Comment=Install the live CD to your hard disk
Categories=System;Utility;X-Red-Hat-Base;X-Fedora;GNOME;GTK;
Exec=/usr/local/bin/liveinst.sh
Terminal=false
Type=Application
Icon=anaconda
StartupNotify=true
NoDisplay=false
X-Desktop-File-Install-Version=0.23
FOEDESK

#dnf -y install docker
#/sbin/chkconfig docker off

#/sbin/chkconfig postgresql off


%end

%packages
@anaconda-tools
@base-x
@core
@firefox
@fonts
@gnome-desktop
@guest-desktop-agents
@hardware-support
@libreoffice
@multimedia
@networkmanager-submodules
@printing
@workstation-product
aajohan-comfortaa-fonts
anaconda
dracut-live
glibc-all-langpacks
kernel
kernel-modules
kernel-modules-extra
memtest86+
syslinux
-@dial-up
-@input-methods
-@standard
-gfs2-utils
-reiserfs-utils

#hernad
ansible
google-chrome-stable.x86_64
htop
vim-enhanced
nodejs
gcc-c++ 
make
git
#vlc
tmux
tmux-powerline
vim-powerline
powerline
powerline-fonts
virt-manager
code
awscli
dnf-utils
flatpak
#postgresql
#postgresql-server
#postgresql-contrib
postgresql-devel
terminus-fonts

#docker
fuse-exfat
#transmission
#buildah
#maven
%end

