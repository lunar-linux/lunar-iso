#
# Makefile to make ISO's
#

#
# all user configurable options are in conf/config
#

# need to make this defined during run-time
ISO_SOURCE = $(shell bash -c "pwd -P")

# define the kernel arch name
###ISO_KARCH=$(shell arch | grep -qw i.86 && echo i386 || arch)
# and the general arch (i386/i686)
ISO_ARCH=$(shell arch)

include conf/config

###ISO_KSUFFIX = $(shell if echo $(ISO_KVER) | grep -q "^2\.6\." ; then echo 2.6 ; else echo 2.4 ; fi ;)

# define the location where the ISO will be generated
ISO_TARGET = $(ISO_SOURCE)/BUILD

###export ISO_SOURCE ISO_TARGET ISO_MAJOR ISO_MINOR ISO_VERSION ISO_CODENAME \
###       ISO_DATE ISO_CNAME ISO_KVER ISO_PVER ISO_GRSVER ISO_LUNAR_MODULE \
###       ISO_KSUFFIX ISO_MAKES ISO_REDUCE ISO_BUILD ISO_KARCH ISO_GCCARCH

export ISO_SOURCE ISO_TARGET ISO_BUILD

all: build

include mkfiles/bootstrap.mk
include mkfiles/download.mk
include mkfiles/build.mk

clean:
	rm -r $(ISO_TARGET) $(ISO_SOURCE)/{spool,cache}

# Convenient target for development
chroot:
	$(ISO_SOURCE)/scripts/chroot-build su -

