#
# Makefile to make ISO's
#

#
# all user configurable options are in conf/config
#

include conf/config

ISO_KSUFFIX = $(shell if echo $(ISO_KVER) | grep -q "^2\.6\." ; then echo 2.6 ; else echo 2.4 ; fi ;)

# need to make this defined during run-time
ISO_SOURCE = $(shell bash -c "pwd -P")

# define the location where the ISO will be generated
ISO_TARGET = $(ISO_SOURCE)/BUILD

export ISO_SOURCE ISO_TARGET ISO_VERSION ISO_CODENAME ISO_DATE ISO_CNAME ISO_KVER ISO_PVER ISO_LUNAR_MODULE ISO_KSUFFIX ISO_MAKES ISO_REDUCE

all: iso

iso: initrd proper $(ISO_TARGET)/.iso
$(ISO_TARGET)/.iso:
	@echo "Generating ISO"
	@scripts/isofs

proper: aaa_dev aaa_base $(ISO_TARGET)/.proper
$(ISO_TARGET)/.proper:
	@echo "Cleaning BUILD"
	@scripts/proper

aaa_dev: $(ISO_SOURCE)/aaa_dev/aaa_dev.tar.bz2
$(ISO_SOURCE)/aaa_dev/aaa_dev.tar.bz2: initrd

initrd: memtest kernels $(ISO_SOURCE)/initrd/initrd
$(ISO_SOURCE)/initrd/initrd:
	@echo "Generating initrd image"
	@scripts/initrd

kernels: rebuild $(ISO_SOURCE)/kernels/.kernels
$(ISO_SOURCE)/kernels/.kernels:
	@echo "Building precompiled kernels"
	@scripts/kernels

memtest: rebuild $(ISO_SOURCE)/memtest/memtest
$(ISO_SOURCE)/memtest/memtest:
	@echo "Generating memtest boot image"
	@scripts/memtest

aaa_base: rebuild $(ISO_SOURCE)/aaa_base/aaa_base.tar.bz2
$(ISO_SOURCE)/aaa_base/aaa_base.tar.bz2:
	@echo "Creating aaa_base.tar.bz2"
	@scripts/aaa_base

rebuild: etc $(ISO_TARGET)/.rebuild
$(ISO_TARGET)/.rebuild:
	@echo "Starting rebuild process"
	@scripts/rebuild

etc: moonbase unpack $(ISO_TARGET)/.etcf
$(ISO_TARGET)/.etcf:
	@echo "Copying miscfiles"
	@scripts/etc

moonbase: $(ISO_SOURCE)/template/moonbase.tar.bz2
$(ISO_SOURCE)/template/moonbase.tar.bz2:
	@echo "Getting a proper moonbase"
	@scripts/moonbase

unpack: cachefill dirs $(ISO_TARGET)/.unpack
$(ISO_TARGET)/.unpack:
	@echo "Unpacking binaries and copying sources"
	@scripts/unpack

cachefill: dirs $(ISO_TARGET)/.cachefill
$(ISO_TARGET)/.cachefill:
	@echo "Fetching cache tarballs and sources"
	@scripts/cachefill

dirs: init $(ISO_TARGET)/.dirs
$(ISO_TARGET)/.dirs:
	@echo "Creating LSB directory structure"
	@scripts/dirs

init: $(ISO_TARGET)/.init
$(ISO_TARGET)/.init:
	@echo "Creating BUILD root"
	@scripts/init


clean:
	umount BUILD/dev &> /dev/null || true
	umount BUILD/proc &> /dev/null || true
	rm -rf BUILD
	rm -rf initrd/BUILD initrd/initrd
	rm -rf aaa_base aaa_dev
	rm -rf memtest
	rm -rf kernels/TAR kernels/*.tar.bz2 kernels/.kernels kernels/.initrd_kernels
	rm -f template/moonbase.tar.bz2
	rm -f kernels/linux kernels/linux.map
	rm -f kernels/safe kernels/safe.map

blank:
	@scripts/blank

burn:
	@scripts/burn

# these are for hacking around and doing manual adjustments
tar:
	tar cf BUILD.tar BUILD

moonbase-extract:
	tar xf $(ISO_TARGET)/var/lib/lunar/moonbase.tar.bz2 -C $(ISO_TARGET)/var/lib/lunar
	rm $(ISO_TARGET)/var/lib/lunar/moonbase.tar.bz2
	@echo "Don't forget to do a 'make moonbase-pack!'"

moonbase-pack:
	tar cjf $(ISO_TARGET)/var/lib/lunar/moonbase.tar.bz2 -C $(ISO_TARGET)/var/lib/lunar moonbase/
	rm -rf $(ISO_TARGET)/var/lib/lunar/moonbase
	@echo "Packed up moonbase."


