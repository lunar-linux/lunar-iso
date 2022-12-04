#
# Makefile to make ISO's
#

# Default target
all: iso

#
# all user configurable options are in conf/config
#

# need to make this defined during run-time
ISO_SOURCE:=$(shell bash -c "pwd -P")

# define the kernel arch name
###ISO_KARCH=$(shell arch | grep -qw i.86 && echo i386 || arch)
# and the general arch (i386/i686)
ISO_ARCH:=$(shell arch)

include $(ISO_SOURCE)/conf/config

$(ISO_SOURCE)/conf/config:
	@echo First copy conf/config.in to conf/config and change the base
	@echo parameters. Afterwards run make again.

###ISO_KSUFFIX = $(shell if echo $(ISO_KVER) | grep -q "^2\.6\." ; then echo 2.6 ; else echo 2.4 ; fi ;)

ifeq ($(ISO_GCCARCH),x86-64)
  ISO_LD_LINUX = ld-linux-$(ISO_GCCARCH).so.2
else
  ISO_LD_LINUX = ld-linux.so.2
endif

# define the location where the ISO will be generated
ISO_TARGET = $(ISO_SOURCE)/BUILD

###export ISO_SOURCE ISO_TARGET ISO_MAJOR ISO_MINOR ISO_VERSION ISO_CODENAME \
###       ISO_DATE ISO_CNAME ISO_KVER ISO_PVER ISO_GRSVER ISO_LUNAR_MODULE \
###       ISO_KSUFFIX ISO_MAKES ISO_REDUCE ISO_BUILD ISO_KARCH ISO_GCCARCH

export ISO_SOURCE ISO_TARGET ISO_BUILD ISO_VERSION ISO_CODENAME ISO_DATE ISO_LABEL ISO_MAJOR

.SUFFIXES:

include mkfiles/bootstrap.mk
include mkfiles/download.mk
include mkfiles/stage1.mk
include mkfiles/stage2.mk
include mkfiles/pack.mk
include mkfiles/kernel.mk
include mkfiles/installer.mk
include mkfiles/iso.mk

clean:
	rm -rf $(ISO_TARGET) $(ISO_SOURCE)/{spool,cache}

# Convenient target for development
chroot:
	$(ISO_SOURCE)/scripts/chroot-build /bin/bash

dist:
	@sha1sum lunar-$(ISO_VERSION).iso > lunar-$(ISO_VERSION).iso.sha1
	@xz lunar-$(ISO_VERSION).iso
	@sha1sum lunar-$(ISO_VERSION).iso.xz > lunar-$(ISO_VERSION).iso.xz.sha1
