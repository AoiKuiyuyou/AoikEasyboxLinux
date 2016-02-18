#

# Although this file's name ends with ".sh", it's not intended to be run as a
# a script directly. Instead, run the commands below step by step manually.

# Prevent to be run as script
exit

# Assume we are in a running Linux.

# Log in as "root" user
su - root

# Clone the repository
git clone https://github.com/AoiKuiyuyou/AoikEasyboxLinux ~/AoikEasyboxLinux

# Prepare utility script "copytobase.sh".
# "copytobase.sh" helps copy files from running Linux to AoikEasyboxLinux.
chmod 755 ~/AoikEasyboxLinux/util/copytobase.sh

# Create a mount point directory
mkdir -pv /mnt/base

# Mount AoikEasyboxLinux's root partition.
#
# Make sure the partition's filesystem is ext3 or ext4.
# Other filesystems may not be supported out-of-box by the initrd.img in use.
#
# Remember to adjust "sdaN" to your own value.
mount /dev/sdaN /mnt/base

# Delete existing files.
# WARNING: Double check the right partition is mounted and make sure all
#          important files have been backed up.
rm -rf /mnt/base/*

# Create "aoikeasyboxlinux.txt".
# Used for Grub4DOS's "find --set-root" to locate the root partition.
touch /mnt/base/aoikeasyboxlinux.txt

# Create basic directories
mkdir -pv /mnt/base/bin
mkdir -pv /mnt/base/boot
mkdir -pv /mnt/base/dev
mkdir -pv /mnt/base/etc/init.d
mkdir -pv /mnt/base/etc/rc.d
mkdir -pv /mnt/base/home
mkdir -pv /mnt/base/lib/modules
mkdir -pv /mnt/base/lib64
mkdir -pv /mnt/base/media
mkdir -pv /mnt/base/mnt/sda{1,2,3,4,5,6,7,8,9}
mkdir -pv /mnt/base/opt
mkdir -pv /mnt/base/proc
mkdir -pv /mnt/base/root
mkdir -pv /mnt/base/sbin
mkdir -pv /mnt/base/srv
mkdir -pv /mnt/base/sys
mkdir -pv /mnt/base/tmp
mkdir -pv /mnt/base/usr
mkdir -pv /mnt/base/var/log
mkdir -pv /mnt/base/var/run/utmp

# Copy kernel "vmlinuz" and "initrd.img"
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /boot/vmlinuz-`uname -r`

ln -sfv "vmlinuz-`uname -r`" /mnt/base/boot/vmlinuz

## Debian 8.3, Ubuntu 15.10, LinuxMint 17.3
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /boot/"initrd.img-`uname -r`"

ln -sfv "initrd.img-`uname -r`" /mnt/base/boot/initrd.img

## CentOS 7, Fedora 23
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /boot/"initramfs-`uname -r`.img"

ln -sfv "initramfs-`uname -r`.img" /mnt/base/boot/initrd.img

## OpenSUSE 42.1
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /boot/"initrd-`uname -r`"

ln -sfv "initrd-`uname -r`" /mnt/base/boot/initrd.img

# Copy filesystem kernel modules (e.g. msdos.ko)
find /lib/modules/`uname -r`/kernel/fs/ -type f -print0 |
xargs -0 -n1 -I '{}' ~/AoikEasyboxLinux/util/copytobase.sh /mnt/base '{}'

# Create a symlink "0" for "/lib/modules/`uname -r`",
# e.g. /mnt/base/lib/modules/0 -> 3.19.0-32-generic
# so that in startup script we can write
# "/lib/modules/0/" instead of "/lib/3.19.0-32-generic/".
ln -sfv `uname -r` /mnt/base/lib/modules/0

# Copy "/etc/fstab"
## The entry for root partition should be changed.
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/fstab

# Set up build tools

## Debian 8.3, Ubuntu 15.10, LinuxMint 17.3
apt-get install -y build-essential
apt-get install -y zlib1g-dev

## CentOS 7, Fedora 23
yum groupinstall -y "Development Tools"
yum install -y zlib-devel

## OpenSUSE 42.1
zypper install -t pattern devel_basis
zypper install libz1

# Compile busybox
mkdir ~/AoikEasyboxLinux/Busybox
cd ~/AoikEasyboxLinux/Busybox
curl -O https://busybox.net/downloads/busybox-1.24.1.tar.bz2
tar xvf busybox-1.24.1.tar.bz2
cd busybox-1.24.1
make defconfig
make
#^ Result executable is "~/AoikEasyboxLinux/Busybox/busybox-1.24.1/busybox"

# Copy busybox to running Linux
cp -av ~/AoikEasyboxLinux/Busybox/busybox-1.24.1/busybox /bin/busybox

# Copy busybox to AoikEasyboxLinux.
# "--ldd" option will copy dynamically linked library files too.
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base /bin/busybox

# Create symbolic links for busybox commands.
# E.g. /mnt/base/bin/which -> busybox
for cmd_name in $(/mnt/base/bin/busybox --list)
do
    ln -sfv busybox /mnt/base/bin/"$cmd_name"
done

# Move some symbolic links from "bin" to "sbin"
rm -fv /mnt/base/bin/init
ln -sfv ../bin/busybox /mnt/base/sbin/init

rm -fv /mnt/base/bin/getty
ln -sfv ../bin/busybox /mnt/base/sbin/getty

rm -fv /mnt/base/bin/poweroff
ln -sfv ../bin/busybox /mnt/base/sbin/poweroff

rm -fv /mnt/base/bin/reboot
ln -sfv ../bin/busybox /mnt/base/sbin/reboot

rm -fv /mnt/base/bin/swapoff
ln -sfv ../bin/busybox /mnt/base/sbin/swapoff

# Add DNS support.
# Copy files needed for DNS to work.
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/hostname

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/resolv.conf
#^ Notice Ubuntu and LinuxMint has this symbolic file:
## /etc/resolv.conf -> ../run/resolvconf/resolv.conf

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/nsswitch.conf

## Debian 8.3, Ubuntu 15.10, LinuxMint 17.3
for x in /lib/x86_64-linux-gnu/libnss*
do
    ~/AoikEasyboxLinux/util/copytobase.sh /mnt/base "$x"
done

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libresolv.so.2

## CentOS 7, Fedora 23
for x in /usr/lib64/libnss*
do
    ~/AoikEasyboxLinux/util/copytobase.sh /mnt/base "$x"
done

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libresolv.so.2

## OpenSUSE 42.1
for x in /usr/lib64/libnss*
do
    ~/AoikEasyboxLinux/util/copytobase.sh /mnt/base "$x"
done

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libresolv.so

# Add DHCP support.
# Busybox has provided "udhcpc".

# Add "udhcpc" config files.
mkdir -pv /mnt/base/usr/share/udhcpc/

cp -av ~/AoikEasyboxLinux/udhcpc/default.script /mnt/base/usr/share/udhcpc/default.script

chmod 755 /mnt/base/usr/share/udhcpc/default.script

# Add SSH support.
# We use Dropbear in lieu of OpenSSH Server.

# Compile Dropbear
mkdir ~/AoikEasyboxLinux/Dropbear
cd ~/AoikEasyboxLinux/Dropbear
curl -O https://matt.ucc.asn.au/dropbear/dropbear-2015.71.tar.bz2
tar xvf dropbear-2015.71.tar.bz2
cd dropbear-2015.71
./configure
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" STATIC=0 MULTI=1
#^ "STATIC=0" means disable static linking.
## "MULTI=1" means compile into a single executable "dropbearmulti".
## "zlib" dev lib is required.
## Result executable is "~/AoikEasyboxLinux/Dropbear/dropbear-2015.71/dropbearmulti"

# Copy dropbearmulti to running Linux
cp -av ~/AoikEasyboxLinux/Dropbear/dropbear-2015.71/dropbearmulti /bin/dropbearmulti

# Copy dropbearmulti to AoikEasyboxLinux.
# "--ldd" option will copy dynamically linked library files too.
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base /bin/dropbearmulti

ln -sfv dropbearmulti /mnt/base/bin/dropbear
ln -sfv dropbearmulti /mnt/base/bin/dbclient
ln -sfv dropbearmulti /mnt/base/bin/dropbearkey
ln -sfv dropbearmulti /mnt/base/bin/dropbearconvert
ln -sfv dropbearmulti /mnt/base/bin/scp

# Set up Dropbear config files
mkdir -pv /mnt/base/etc/dropbear

# If running Linux's RSA host key exists
if [ -f /etc/ssh/ssh_host_rsa_key ]; then
    # Use running Linux's host key
    /mnt/base/bin/dropbearconvert openssh dropbear /etc/ssh/ssh_host_rsa_key /mnt/base/etc/dropbear/dropbear_rsa_host_key
else
    # Create new host key
    /mnt/base/bin/dropbearkey -t rsa -f /mnt/base/etc/dropbear/dropbear_rsa_host_key
fi

# If running Linux's DSA host key exists
if [ -f /etc/ssh/ssh_host_dsa_key ]; then
    # Use running Linux's host key
    /mnt/base/bin/dropbearconvert openssh dropbear /etc/ssh/ssh_host_dsa_key /mnt/base/etc/dropbear/dropbear_dss_host_key
else
    # Create new host key
    /mnt/base/bin/dropbearkey -t dss -f /mnt/base/etc/dropbear/dropbear_dss_host_key
fi

# If running Linux's ECDSA host key exists
if [ -f /etc/ssh/ssh_host_ecdsa_key ]; then
    # Use running Linux's host key
    /mnt/base/bin/dropbearconvert openssh dropbear /etc/ssh/ssh_host_ecdsa_key /mnt/base/etc/dropbear/dropbear_ecdsa_host_key
else
    # Create new host key
    /mnt/base/bin/dropbearkey -t ecdsa -f /mnt/base/etc/dropbear/dropbear_ecdsa_host_key
fi

# Copy "authorized_keys"
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base ~/.ssh/authorized_keys

chmod 644 /mnt/base/root/.ssh/authorized_keys

# Copy Bash executable and libs
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base `which bash`

## CentOS 7, Fedora 23
ln -sfv /usr/bin/bash /mnt/base/bin/bash

# Copy "terminfo".
# Some paths below may not exist.
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/terminfo
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/terminfo
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/share/terminfo
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base ~/.terminfo

# Copy "inputrc"
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/inputrc

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base ~/.inputrc

## Copy files needed by bash to implement login shell
touch /mnt/base/var/log/lastlog

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/issue

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/passwd

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/group

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/shadow

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/shells

## Debian 8.3, Ubuntu 15.10, LinuxMint 17.3
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib64/ld-linux-x86-64.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libc.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libcrypt.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libm.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libnsl.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libnss_compat.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libutil.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/x86_64-linux-gnu/libz.so.1

## CentOS 7, Fedora
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/ld-linux-x86-64.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib64/ld-linux-x86-64.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libc.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libcrypt.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libm.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libnsl.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libnss_compat.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libutil.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/lib64/libz.so.1

## OpenSUSE 42.1
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/ld-linux.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib64/ld-linux-x86-64.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libc.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libcrypt.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libm.so.6

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libnsl.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libnss_compat.so.2

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libutil.so.1

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /lib/libz.so.1

# Copy global login config files
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/profile

## Debian 8.3, Ubuntu 15.10, LinuxMint 17.3, OpenSUSE 42.1
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/bash.bashrc

## CentOS 7, Fedora 23
~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/bashrc

# Create per-user login config files.
# To keep it simple, we create do-nothing config files here.
cat <<'ZZZ' > /mnt/base/root/.profile
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
ZZZ

touch /mnt/base/root/.bashrc

# Copy Vim.
# Notice Busybox has provided "vi".
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base `which vim`

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/vim/

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/vimrc

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /etc/virc

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base /usr/share/vim/

~/AoikEasyboxLinux/util/copytobase.sh /mnt/base ~/.vimrc

# Copy wget.
# Notice Busybox has provided "wget" but does not support recursive option "-r".
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base `which wget`

# Copy curl
~/AoikEasyboxLinux/util/copytobase.sh --ldd /mnt/base `which curl`

# Set up "/etc/inittab"
cp -av ~/AoikEasyboxLinux/init/inittab /mnt/base/etc/inittab

chmod 644 /mnt/base/etc/inittab

# Set up "/etc/init.d/rcS"
cp -av ~/AoikEasyboxLinux/init/rcS /mnt/base/etc/init.d/rcS

chmod 744 /mnt/base/etc/init.d/rcS

# Set up boot loader.
# We use Grub4DOS here. It works like this:
# - Grub4DOS stage-0 boot loader in MBR loads Grub4DOS stage-1 boot loader
#   "grldr" in a partition root.
# - Grub4DOS stage-1 boot loader "grldr" reads config file "menu.lst" in a
#   partition root.
# - Grub4DOS stage-1 boot loader "grldr" loads AoikEasyboxLinux's kernel file
#   "/boot/vmlinuz".

# Install Grub4DOS stage-0 boot loader to MBR.
#
# WARNING: This will destroy existing MBR, making you unable to boot into
#          existing operating systems. Do not proceed if you are unsure about
#          the consequences.
# WARNING: Make sure /dev/sdX (adjust "X" to your own value) is the right disk
#          in case multiple disks are connected. If unsure, use "fdisk" to
#          double check.
chmod 744 _GRUB4DOS_DIR_/bootlace.com

_GRUB4DOS_DIR_/bootlace.com --time-out=0 --mbr-disable-floppy /dev/sdX
#^ "bootlace.com" works on both Linux and DOS.
## In DOS, use "0x80" instead of "/dev/sda" to mean the first disk.

# Install Grub4DOS stage-1 boot loader to AoikEasyboxLinux's partition root
cp -av _GRUB4DOS_DIR_/grldr /mnt/base/grldr

chmod 644 /mnt/base/grldr

# Create Grub4DOS config file "menu.lst".
# Remember to adjust "/dev/sdaN" to your own value.
cat <<'ZZZ' > /mnt/base/menu.lst
title AoikEasyboxLinux
    find --set-root /aoikeasyboxlinux.txt
    kernel /boot/vmlinuz root=/dev/sdaN init=/sbin/init
    initrd /boot/initrd.img

title AoikEasyboxLinux (Networking)
    find --set-root /aoikeasyboxlinux.txt
    kernel /boot/vmlinuz root=/dev/sdaN init=/sbin/init udhcpc dropbear
    initrd /boot/initrd.img
ZZZ

chmod 644 /mnt/base/menu.lst
