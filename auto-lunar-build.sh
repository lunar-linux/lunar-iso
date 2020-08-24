#!/bin/bash

echo "Build started at $(date)"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:.
export PATH

sudo rm -rf lunar-iso

git clone git@github.com:lunar-linux/lunar-iso.git
cd lunar-iso
# git checkout fix-iso-build

corecount=$(grep processor /proc/cpuinfo | wc -l)
makecount=$[corecount*2]

cat >> conf/config << EOT
ISO_ARCH = $(arch)
ISO_MAJOR = 1.7.1
ISO_MINOR = $(date +testing-%Y%m%d)

ifeq (,\$(ISO_MINOR))
  ISO_VERSION = \$(ISO_MAJOR)-\$(ISO_ARCH)
else
  ISO_VERSION = \$(ISO_MAJOR)-\$(ISO_MINOR)-\$(ISO_ARCH)
endif

ISO_CODENAME = Mare Incognitum

ISO_BUILD = \$(ISO_ARCH)-pc-linux-gnu

ISO_CNAME = \$(ISO_VERSION) (\$(ISO_CODENAME) - \$(ISO_DATE))

ISO_LABEL = \$(shell echo -n Lunar-Linux \$(ISO_CODENAME) | tr '[:space:]' _)

ISO_LUNAR_MODULE = lunar

ISO_MAKES = ${makecount}

ISO_GCCARCH = $(arch)
EOT

sudo make || sudo make || sudo make

if [ -f *.iso ]
then
    mkdir -p ../daily
    cp *.iso ../daily
    xz -9 ../daily/*.iso
    for i in *.xz
    do
        if ! [ -f ${i}.sha256 ]
        then
            sha256sum $i > ${i}.sha256
        fi
    done
    rsync -av ../daily/* shell.lart.ca:data/webpage/lart.ca/public/lunar
fi

echo "Build finished at $(date)"
