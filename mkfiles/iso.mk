.INTERMEDIATE: iso iso-tools iso-files iso-isolinux

iso: $(ISO_SOURCE)/lunar-$(ISO_VERSION)-$(ISO_ARCH).iso


# Host system iso tools
iso-tools:
	@which mkisofs || lin cdrtools


# Prepare target files
$(ISO_TARGET)/etc/lunar.release: stage2-target
	echo 'DISTRIB_ID="Lunar Linux"'                        > $@
	echo 'DISTRIB_RELEASE="$(ISO_VERSION)"'               >> $@
	echo 'DISTRIB_CODENAME="$(ISO_CODENAME)"'             >> $@
	echo 'DISTRIB_DESCRIPTION="Lunar Linux $(ISO_CNAME)"' >> $@
	echo "Lunar Linux $(ISO_CNAME)" > $@

iso-files: $(ISO_TARGET)/etc/lunar.release


# Copy the isolinux files to the target
$(ISO_TARGET)/usr/share/syslinux/isolinux.bin: stage2
	@touch $@

$(ISO_TARGET)/isolinux/isolinux.bin: $(ISO_TARGET)/usr/share/syslinux/isolinux.bin
	@cp $< $@

$(ISO_TARGET)/.iso-isolinux: stage2-target
	@cp -r $(ISO_SOURCE)/isolinux $(ISO_TARGET)
	@touch $@

iso-isolinux: $(ISO_TARGET)/.iso-isolinux $(ISO_TARGET)/isolinux/isolinux.bin


# Generate the actual image
$(ISO_SOURCE)/lunar-$(ISO_VERSION)-$(ISO_ARCH).iso: iso-tools iso-files iso-isolinux
	mkisofs -o $@.tmp -R -J -l \
	-V "Lunar-Linux $(ISO_CODENAME)" -v \
	-d -D -N -no-emul-boot -boot-load-size 4 -boot-info-table \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-m spool -m doc \
	-A "Lunar-$(ISO_VERSION)" $(ISO_TARGET)
	#mkhybrid $@.tmp
	mv $@.tmp $@
