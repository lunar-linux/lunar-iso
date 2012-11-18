.INTERMEDIATE: iso iso-target iso-modules iso-tools iso-files iso-isolinux

iso: $(ISO_SOURCE)/lunar-$(ISO_VERSION)-$(ISO_ARCH).iso


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
	{ echo 'DISTRIB_ID="Lunar Linux"' ; \
	  echo 'DISTRIB_RELEASE="$(ISO_VERSION)"' ; \
	  echo 'DISTRIB_CODENAME="$(ISO_CODENAME)"' ; \
	  echo 'DISTRIB_DESCRIPTION="Lunar Linux $(ISO_CNAME)"' ; } > $@

iso-files: $(ISO_TARGET)/etc/lsb-release


# Copy the isolinux files to the target
$(ISO_TARGET)/usr/share/syslinux/isolinux.bin: $(ISO_TARGET)/.iso-isolinux
	@touch $@

$(ISO_TARGET)/isolinux/isolinux.bin: $(ISO_TARGET)/usr/share/syslinux/isolinux.bin
	@cp $< $@

$(ISO_TARGET)/.iso-isolinux: iso-target
	@cp -r $(ISO_SOURCE)/isolinux $(ISO_TARGET)
	@touch $@

iso-isolinux: $(ISO_TARGET)/.iso-isolinux $(ISO_TARGET)/isolinux/isolinux.bin


# Generate the actual image
$(ISO_SOURCE)/lunar-$(ISO_VERSION)-$(ISO_ARCH).iso: iso-tools iso-files iso-isolinux
	mkisofs -o $@.tmp -R -J -l \
		-V "Lunar-Linux_`echo -n $(ISO_CODENAME) | tr '[:space:]' _`" -v \
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
	-m '$(ISO_TARGET)/usr/share/locale' \
	-m '$(ISO_TARGET)/usr/share/man' \
	-m '$(ISO_TARGET)/usr/share/info' \
	-m '$(ISO_TARGET)/usr/share/gtk-doc' \
	-m '$(ISO_TARGET)/usr/include' \
	-m '$(ISO_TARGET)/usr/src' \
	-m '$(ISO_TARGET)/var/state/lunar/module_history' \
	-m 'lib*.a' \
	-m 'doc' \
	-A "Lunar-$(ISO_VERSION)" $(ISO_TARGET)
	#mkhybrid $@.tmp
	mv $@.tmp $@
