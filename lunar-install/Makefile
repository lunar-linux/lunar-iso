

include ../conf/config

installer_PROGS = sbin/lunar-install sbin/lish
installer_LIBS = $(shell ls -1 lib/*)
installer_CONFIG = etc/config

all: sbin/lunar-install etc/config

SBINDIR=$(PREFIX)/sbin
LIBDIR=$(PREFIX)/var/lib/lunar/functions/installer
ETCDIR=$(PREFIX)/etc/lunar/installer

install: $(installer_PROGS) $(installer_CONFIG) $(installer_LIBS)
	install -d $(DESTDIR)$(SBINDIR)
	install -d $(DESTDIR)$(ETCDIR)
	install -d $(DESTDIR)$(LIBDIR)
	for lib in $(installer_LIBS); do \
	  install -m0644 $$lib $(DESTDIR)/$(LIBDIR); \
	done
	for script in $(installer_PROGS); do \
	  install -m0755 $$script $(DESTDIR)$(SBINDIR); \
	done
	for config in $(installer_CONFIG); do \
	  install -m0644 $$config $(DESTDIR)$(ETCDIR); \
	done

sbin/lunar-install: sbin/lunar-install.sh
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' \
	     -e 's:%CODENAME%:$(ISO_CODENAME):g' \
	     -e 's:%DATE%:$(ISO_DATE):g' \
	     -e 's:%KERNEL%:$(ISO_KERNEL):g' \
	     -e 's:%CNAME%:$(ISO_CNAME):g' \
	     -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' \
	     -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@

etc/config: etc/config.sh
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' \
	     -e 's:%CODENAME%:$(ISO_CODENAME):g' \
	     -e 's:%DATE%:$(ISO_DATE):g' \
	     -e 's:%KERNEL%:$(ISO_KERNEL):g' \
	     -e 's:%CNAME%:$(ISO_CNAME):g' \
	     -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' \
	     -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@
