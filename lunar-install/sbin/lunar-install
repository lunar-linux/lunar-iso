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

# start up the code
. /etc/lunar/installer/config

trap ":" INT QUIT

$DIALOG --infobox "Lunar Linux Installer %VERSION% - %CODENAME% starting... " 4 60

# turn off console blanking
/usr/bin/setterm -blank 0
cd /

# load modules when passed on the boot prompt$
IFS=$' \t\n'
for module in $(cat /proc/cmdline); do
  if grep -q "/${module}.ko:" /lib/modules/`uname -r`/modules.dep ; then
    modprobe $module
  fi
done
IFS=$'\t\n'

# allow custom startup scripts to run instead of the installer
if [ -x /run.sh ]; then
  echo ""
  echo "  /--------------------------------------------------\\"
  echo "  |                                                  |"
  echo "  |  Executing /run.sh instead of the Lunar Linux    |"
  echo "  |  Installer! If something goes wrong then you're  |"
  echo "  |  on your own, sorry...                           |"
  echo "  |                                                  |"
  echo "  \\--------------------------------------------------/"
  /run.sh
else
  main
fi
