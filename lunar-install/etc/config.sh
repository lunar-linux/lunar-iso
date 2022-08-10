#!/bin/bash
#############################################################
#                                                           #
# portions Copyright 2001 by Kyle Sallee                    #
# portions Copyright 2002 by Kagan Kongar                   #
# portions Copyright 2002 by rodzilla                       #
# portions Copyright 2003-2004 by tchan, kc8apf             #
# portions Copyright 2004-2007 by Auke Kok                  #
# portions Copyright 2008-2017 by Stefan Wold               #
#                                                           #
#############################################################
#                                                           #
# This file in released under the GPLv2                     #
#                                                           #
#############################################################

LOCALE_LIST=/usr/share/lunar-install/locale.list
PACKAGES_LIST=/var/cache/lunar/packages
KERNEL_LIST=/var/cache/lunar/kernels
KMOD_LIST=/var/spool/lunar/kmodules
MOONBASE_TAR=/usr/share/lunar-install/moonbase.tar.bz2
MOTD_FILE=/usr/share/lunar-install/motd

# answers to questions asked at the beginning of installing
BOOTLOADER=none
TZ=UTC

. /etc/lunar/config
for FUNCTION in $FUNCTIONS/installer/*.lunar
do
  . $FUNCTION
done

DIALOG="dialog
--backtitle
Lunar Linux Installer %VERSION% - %CODENAME% (%DATE%)
--stdout"

export IFS=$'\t\n'
ARCH=$(arch)
