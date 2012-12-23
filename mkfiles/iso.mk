.INTERMEDIATE: iso iso-target iso-modules iso-tools iso-files iso-strip iso-isolinux

iso: $(ISO_SOURCE)/lunar-$(ISO_VERSION).iso


# Clean stage2 markers and mark the start of iso
$(ISO_TARGET)/.iso-target: kernel pack
	@echo iso-target
	@rm -f $(ISO_TARGET)/.stage2*
	@touch $@

iso-target: $(ISO_TARGET)/.iso-target


# Host system iso tools
iso-tools:
	@which mkisofs || lin cdrtools


# Remove non iso modules
include $(ISO_SOURCE)/conf/modules.iso

$(ISO_TARGET)/.iso-modules: iso-target
	@echo iso-modules
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lrm $(filter-out $(ISO_MODULES), $(ALL_MODULES))
	@touch $@

iso-modules: $(ISO_TARGET)/.iso-modules


# Prepare target files
$(ISO_TARGET)/etc/lsb-release: iso-modules
	@echo lsb-release
	@{ echo 'DISTRIB_ID="Lunar Linux"' ; \
	   echo 'DISTRIB_RELEASE="$(ISO_VERSION)"' ; \
	   echo 'DISTRIB_CODENAME="$(ISO_CODENAME)"' ; \
	   echo 'DISTRIB_DESCRIPTION="Lunar Linux $(ISO_CNAME)"' ; } > $@

$(ISO_TARGET)/etc/fstab: $(ISO_SOURCE)/livecd/template/etc/fstab iso-modules
	@cp $< $@

iso-files: $(ISO_TARGET)/etc/lsb-release $(ISO_TARGET)/etc/fstab


# Strip executables and libraries
$(ISO_TARGET)/.iso-strip: iso-modules
	@echo iso-strip
	@find \( -type f -perm /u=x -o -name 'lib*.so*' \) -exec strip {} \;
	@touch $@

iso-strip: $(ISO_TARGET)/.iso-strip


# Copy the isolinux files to the target
ISOLINUX_FILES=README f1.txt f2.txt f3.txt f4.txt generate-iso.sh isolinux.cfg

$(ISO_TARGET)/usr/share/syslinux/isolinux.bin: $(ISO_TARGET)/.iso-isolinux
	@test -f $@
	@touch $@

$(ISO_TARGET)/isolinux/isolinux.bin: $(ISO_TARGET)/usr/share/syslinux/isolinux.bin
	@cp $< $@

$(ISO_TARGET)/boot/linux: $(ISO_TARGET)/.iso-isolinux
	@test -f $@
	@touch $@

$(ISO_TARGET)/isolinux/linux: $(ISO_TARGET)/boot/linux
	@cp $< $@

$(ISO_TARGET)/boot/initrd: $(ISO_TARGET)/.iso-isolinux
	@test -f $@
	@touch $@

$(ISO_TARGET)/isolinux/initrd: $(ISO_TARGET)/boot/initrd
	@cp $< $@

$(ISO_TARGET)/isolinux/%: $(ISO_SOURCE)/isolinux/%
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

$(ISO_TARGET)/isolinux/%: $(ISO_SOURCE)/isolinux/%.$(ISO_ARCH)
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

$(ISO_TARGET)/.iso-isolinux: iso-target
	@echo iso-isolinux
	@mkdir -p $(ISO_TARGET)/isolinux
	@touch $@

iso-isolinux: $(ISO_TARGET)/.iso-isolinux $(ISO_TARGET)/isolinux/isolinux.bin $(ISO_TARGET)/isolinux/linux $(ISO_TARGET)/isolinux/initrd $(addprefix $(ISO_TARGET)/isolinux/, $(ISOLINUX_FILES))


# Generate the actual image
$(ISO_SOURCE)/lunar-$(ISO_VERSION).iso: iso-tools iso-files iso-isolinux iso-strip
	mkisofs -o $@.tmp -R -J -l \
	-V '$(ISO_LABEL) -v \
	-d -D -N -no-emul-boot -boot-load-size 4 -boot-info-table \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-m '$(ISO_TARGET)/.*' \
	-m '$(ISO_TARGET)/etc/lunar/local/*' \
	-m '$(ISO_TARGET)/tmp/*' \
	-m '$(ISO_TARGET)/var/tmp/*' \
	-m '$(ISO_TARGET)/var/spool/*' \
	-m '$(ISO_TARGET)/var/log/*' \
	-m '$(ISO_TARGET)/root/*' \
	-m '$(ISO_TARGET)/usr/lib/locale' \
	-m '$(ISO_TARGET)/usr/share/locale' \
	-m '$(ISO_TARGET)/usr/share/man' \
	-m '$(ISO_TARGET)/usr/share/info' \
	-m '$(ISO_TARGET)/usr/share/gtk-doc' \
	-m '$(ISO_TARGET)/usr/include' \
	-m '$(ISO_TARGET)/usr/src' \
	-m '$(ISO_TARGET)/var/state/lunar/module_history' \
	-m 'doc' \
	-A 'Lunar-$(ISO_VERSION)' $(ISO_TARGET)
	#mkhybrid $@.tmp
	mv $@.tmp $@
