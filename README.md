# AoikEasyboxLinux
Let's take 10 minutes to create a customized Linux.

Tested working with:
- Debian 8.3
- Ubuntu 15.10
- LinuxMint 17.3
- CentOS 7
- Fedora 23
- OpenSUSE 42.1
- Other distributions should work as well

## Table of Contents
- [Motivation](#motivation)
- [How it works](#how-it-works)

## Motivation
I've been recently trying out different Linux distributions. To save disk space,
I have installed all of them into one single partition. To switch between these
distributions, I switch their files in and out of a ".os" directory, e.g.
".os/ubuntu", ".os/linuxmint", etc.

This just works, except I cannot switch files when a distribution is running
because with all its files put away the shutdown process will be broken.
Therefore to switch files, I need to first boot into another lightweight Linux
(in a different partition). Therefore I have decided to create a customized
Linux to serve the purpose.

## How it works
My design goals and decisions:
- **Fast to create**
  - Copy kernel files "vmlinuz" and "initrd.img", and other needed kernel
    modules from an existing distribution (say Ubuntu).
  - Copy other needed software (e.g. vim, curl, etc.) from the existing
    distribution too. Notice many binary files are compiled using dynamic linking.
    Their dependent library files must be copied as well. I've made a tool to
    help this (more about this below).
  - Copying from an existing distribution has the following merits:
    - Time spent on compilation is saved. And the existing Linux distribution's
      package manager can be used to install software needed. Great!
    - Time spent on driver finding and debugging is saved. If the kernel and
      software work in the existing distribution, they work in the customized
      Linux too.
  - To facilitate the copying process, I've written a utility script named
    [copytobase.sh](/util/copytobase.sh). It has the following features:
      - Copy a file or a directory to a base direcory.  
        E.g. `copytobase.sh /mnt/base /etc/hostname` will copy `/etc/hostname`
        to `/mnt/base/etc/hostname`.
      - Copy a chain of symbolic links as-is.  
        E.g. with a chain of symbolic links
        `/usr/bin/vim -> /etc/alternatives/vim -> /usr/bin/vim-basic`,  
        `copytobase.sh /mnt/base /usr/bin/vim` will copy the two symbolic links
        `/usr/bin/vim` and `/etc/alternatives/vim` along with the actual file
        `/usr/bin/vim-basic` as-is.
- **Moderate in size**
  - The final size of my customized Linux is around 100 MB.
  - To reduce overall size and keep things simple, I choose Busybox. It combines
    a bunch of everyday programs into a single executable. Most importantly, it
    provides an "init" program that supports "inittab"-style config file
    and spawning ttys, which is a perfect replacement of a more complicated
    init system such as "SysVInit" or "SystemD".
- **Support DHCP**
  - Busybox has provided DHCP client "udhcpc".
- **Support SSH**
  - I choose Dropbear, which is a simple replacement of OpenSSH Server.

Here are the [steps](/setup/steps.sh) to put things together. (Do not run it as
a script. Go through the steps manually.)

Try it out! After getting familiar with the steps, you should be able to create a
customized Linux within 10 minutes.
