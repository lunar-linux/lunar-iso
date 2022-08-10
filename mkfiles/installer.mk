.INTERMEDIATE: lunar-install

installer: lunar-install

# Install the Lunar installer
$(ISO_TARGET)/sbin/lunar-install:
	@echo lunar-install
	@make -C lunar-install install DESTDIR=$(ISO_TARGET)

# Generate locale list
$(ISO_TARGET)/usr/share/lunar-install/locale.list: iso-target
	@echo locale.list
	@mkdir -p $(ISO_TARGET)/usr/share/lunar-install
	@$(ISO_SOURCE)/scripts/chroot-build locale -a -v | \
	sed -rn 's;archive.*|locale:|language \||territory \|;;gp' | \
	awk '{printf $$0 ; printf " "} NR % 3 == 0 {print " "}' | \
	while read locale language territory ; do \
	  echo -e "$$locale\t$$language ($$territory)" ; \
	done > $@

$(ISO_TARGET)/usr/share/lunar-install/moonbase.tar.bz2: $(ISO_SOURCE)/spool/moonbase.tar.bz2 iso-target
	@cp $< $@

$(ISO_TARGET)/README: $(ISO_SOURCE)/template/README iso-target
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@

$(ISO_TARGET)/usr/share/lunar-install/motd: $(ISO_SOURCE)/template/motd iso-target
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:LUNAR_$(ISO_MAJOR):' $< > $@

lunar-install: $(ISO_TARGET)/sbin/lunar-install \
	$(ISO_TARGET)/usr/share/lunar-install/locale.list \
	$(ISO_TARGET)/usr/share/lunar-install/moonbase.tar.bz2 \
	$(ISO_TARGET)/README \
	$(ISO_TARGET)/usr/share/lunar-install/motd
