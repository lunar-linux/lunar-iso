.INTERMEDIATE: lunar-install

installer: lunar-install

# Install the Lunar installer
$(ISO_TARGET)/sbin/lunar-install:
	@echo lunar-install
	@make -C lunar-install install DESTDIR=$(ISO_TARGET)

$(ISO_TARGET)/usr/share/lunar-install/moonbase.tar.bz2: $(ISO_SOURCE)/spool/moonbase.tar.bz2 iso-target
	@install -Dm644 $< $@

$(ISO_TARGET)/README: $(ISO_SOURCE)/template/README iso-target
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@

$(ISO_TARGET)/usr/share/lunar-install/motd: $(ISO_SOURCE)/template/motd iso-target
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@

$(ISO_TARGET)/sbin/mkfs.zfs: $(ISO_SOURCE)/lunar-install/sbin/mkfs.zfs
	install -m 755 $< $@

lunar-install: $(ISO_TARGET)/sbin/lunar-install \
	$(ISO_TARGET)/usr/share/lunar-install/moonbase.tar.bz2 \
	$(ISO_TARGET)/README \
	$(ISO_TARGET)/usr/share/lunar-install/motd
	$(ISO_TARGET)/sbin/mkfs.zfs
