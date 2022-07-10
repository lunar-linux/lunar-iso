.INTERMEDIATE: iso iso-target iso-modules iso-tools iso-files iso-strip iso-isolinux iso-efi iso-sfs
.PHONY: iso-tools

iso: $(ISO_SOURCE)/lunar-$(ISO_VERSION).iso

# Blank for i686 builds for now
XORRISO_EFI_OPTS :=

# Clean stage2 markers and mark the start of iso
$(ISO_TARGET)/.iso-target: kernel pack
	@echo iso-target
	@rm -f $(ISO_TARGET)/.stage2*
	@touch $@

iso-target: $(ISO_TARGET)/.iso-target


# Host system iso tools
iso-tools:
	@which xorriso &> /dev/null || lin libisoburn
	@which isohybrid &> /dev/null || lin syslinux
	@which efitool-mkusb &> /dev/null || lin efitools
	@which mksquashfs &> /dev/null || lin squashfs
	@which rsync &> /dev/null || lin rsync

# Remove non iso modules
include $(ISO_SOURCE)/conf/modules.iso

SYSLINUX_FILES=isolinux.bin isohdpfx.bin ldlinux.c32 libcom32.c32 libutil.c32

$(ISO_TARGET)/.iso-modules: iso-target $(addprefix $(ISO_TARGET)/isolinux/, $(SYSLINUX_FILES))
	@echo iso-modules
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lrm -n $(filter-out $(ISO_MODULES), $(ALL_MODULES))
	@rm -rf $(ISO_TARGET)/usr/lib/python*
	@touch $@

iso-modules: $(ISO_TARGET)/.iso-modules


# Prepare target files
ISO_ETC_FILES=lsb-release os-release fstab motd issue issue.net

$(ISO_TARGET)/etc/%: $(ISO_SOURCE)/livecd/template/etc/% iso-modules
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

# Symlinks need special care
$(ISO_TARGET)/.iso-files: iso-target
	@echo iso-files
	@rm -f $(ISO_TARGET)/etc/dracut.conf.d/02-lunar-live.conf $(ISO_TARGET)/etc/ssh/ssh_host_*
	@for unit in sockets.target.wants/sshd.socket multi-user.target.wants/sshd.service multi-user.target.wants/sshd-keys.service ; do \
	  rm -f $(ISO_TARGET)/etc/systemd/system/$$unit ; \
	done
	@$(ISO_SOURCE)/scripts/chroot-build bash -c 'for unit in systemd-networkd systemd-resolved ; do systemctl disable $$unit; done'
	@[ ! -d $(ISO_TARGET)/etc/dracut.conf.d ] || rmdir --ignore-fail-on-non-empty $(ISO_TARGET)/etc/dracut.conf.d
	@cp -r $(ISO_SOURCE)/livecd/template/etc/systemd $(ISO_TARGET)/etc
	@> $(ISO_TARGET)/etc/machine-id
	@ln -sf ../../../tmp/random-seed $(ISO_TARGET)/var/lib/systemd/random-seed
	@mkdir -p $(ISO_TARGET)/var/cache/man
	@find $(ISO_TARGET)/etc/skel/ -type f -exec cp {} $(ISO_TARGET)/root/ \;
	@ln -sf /tmp/resolv.conf $(ISO_TARGET)/etc/resolv.conf
	@ln -sf /tmp/dhcpcd.duid $(ISO_TARGET)/etc/dhcpcd.duid
	@touch $@

iso-files: $(ISO_TARGET)/.iso-files $(addprefix $(ISO_TARGET)/etc/, $(ISO_ETC_FILES))


# Strip executables and libraries
$(ISO_TARGET)/.iso-strip: iso-modules
	@echo iso-strip
	@find $(ISO_TARGET) \( -type f -perm /u=x -o -name 'lib*.so*' -o -name '*.ko' \) -exec strip --strip-unneeded {} \;
	@touch $@

iso-strip: $(ISO_TARGET)/.iso-strip


# Copy the isolinux files to the target
ISOLINUX_FILES=README f1.txt f2.txt f3.txt generate-iso.sh isolinux.cfg

.SECONDARY: $(addprefix $(ISO_TARGET)/usr/share/syslinux/, $(SYSLINUX_FILES))
$(addprefix $(ISO_TARGET)/usr/share/syslinux/, $(SYSLINUX_FILES)): $(ISO_TARGET)/.iso-isolinux
	@test -f $@
	@touch $@

$(ISO_TARGET)/isolinux/isolinux.bin: $(ISO_TARGET)/usr/share/syslinux/isolinux.bin
	@cp $< $@

$(ISO_TARGET)/isolinux/isohdpfx.bin: $(ISO_TARGET)/usr/share/syslinux/isohdpfx.bin
	@cp $< $@

$(ISO_TARGET)/isolinux/ldlinux.c32: $(ISO_TARGET)/usr/share/syslinux/ldlinux.c32
	@cp $< $@

$(ISO_TARGET)/isolinux/libcom32.c32: $(ISO_TARGET)/usr/share/syslinux/libcom32.c32
	@cp $< $@

$(ISO_TARGET)/isolinux/libutil.c32: $(ISO_TARGET)/usr/share/syslinux/libutil.c32
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

$(ISO_TARGET)/isolinux/%: $(ISO_SOURCE)/isolinux/% $(ISO_TARGET)/.iso-isolinux
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

$(ISO_TARGET)/isolinux/%: $(ISO_SOURCE)/isolinux/%.$(ISO_ARCH) $(ISO_TARGET)/.iso-isolinux
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%KERNEL%:$(ISO_KERNEL):g' -e 's:%CNAME%:$(ISO_CNAME):g' -e 's:%COPYRIGHTYEAR%:$(ISO_COPYRIGHTYEAR):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

$(ISO_TARGET)/.iso-isolinux: iso-target
	@echo iso-isolinux
	@mkdir -p $(ISO_TARGET)/isolinux
	@touch $@

iso-isolinux: $(ISO_TARGET)/.iso-isolinux $(addprefix $(ISO_TARGET)/isolinux/, $(SYSLINUX_FILES)) $(ISO_TARGET)/isolinux/linux $(ISO_TARGET)/isolinux/initrd $(addprefix $(ISO_TARGET)/isolinux/, $(ISOLINUX_FILES))

# Setup EFI for USB and CD
$(ISO_TARGET)/.iso-efi: iso-target
	@echo "Setting up iso-efi"
	@mkdir -p $(ISO_TARGET)/EFI/boot $(ISO_TARGET)/loader/entries $(ISO_TARGET)/EFI/lunariso
	@touch $@

$(ISO_TARGET)/EFI/boot/bootx64.efi: /usr/share/efitools/efi/PreLoader.efi
	@cp $< $@

$(ISO_TARGET)/EFI/boot/HashTool.efi: /usr/share/efitools/efi/HashTool.efi
	@cp $< $@

$(ISO_TARGET)/EFI/boot/loader.efi: $(ISO_TARGET)/usr/lib/systemd/boot/efi/systemd-bootx64.efi
	@cp $< $@

$(ISO_TARGET)/loader/loader.conf: $(ISO_SOURCE)/efiboot/loader/loader.conf
	@cp $< $@

$(ISO_TARGET)/loader/entries/lunariso-x86_64.conf: $(ISO_SOURCE)/efiboot/loader/entries/lunariso-x86_64-cd.conf $(ISO_TARGET)/.iso-efi
	@sed -e 's:%VERSION%:$(ISO_VERSION):g' -e 's:%CODENAME%:$(ISO_CODENAME):g' -e 's:%DATE%:$(ISO_DATE):g' -e 's:%LABEL%:$(ISO_LABEL):' $< > $@

$(ISO_TARGET)/EFI/lunariso/efiboot.img: $(ISO_TARGET)/.iso-efi
	@echo "Creating EFI boot image"
	@$(ISO_SOURCE)/scripts/create-efi-image

ifeq ($(ISO_ARCH),x86_64)
XORRISO_EFI_OPTS := -eltorito-alt-boot -e EFI/lunariso/efiboot.img -no-emul-boot -isohybrid-gpt-basdat
iso-efi: $(ISO_TARGET)/.iso-efi $(ISO_TARGET)/EFI/boot/bootx64.efi $(ISO_TARGET)/EFI/boot/HashTool.efi $(ISO_TARGET)/EFI/boot/loader.efi $(ISO_TARGET)/loader/loader.conf $(ISO_TARGET)/loader/entries/lunariso-x86_64.conf $(ISO_TARGET)/EFI/lunariso/efiboot.img
else
iso-efi:
	@$(SHELL) -c true
endif

# Generate squashfs image
$(ISO_TARGET)/.iso-sfs: iso-target iso-strip installer
	@echo "Preparing squashfs image"
	@mkdir -p $(ISO_TARGET)/LiveOS
	@touch $@

$(ISO_TARGET)/LiveOS/squashfs.img: $(ISO_TARGET)/.iso-sfs
	@echo "Creating squashfs image"
	@$(ISO_SOURCE)/scripts/make-squashfs

iso-sfs: $(ISO_TARGET)/LiveOS/squashfs.img

# Generate the actual image
$(ISO_SOURCE)/lunar-$(ISO_VERSION).iso: iso-tools iso-files iso-isolinux iso-efi iso-strip iso-sfs
	@echo iso
	@xorriso -as mkisofs \
	-iso-level 3 \
	-full-iso9660-filenames \
	-o $@.tmp -l \
	-eltorito-boot isolinux/isolinux.bin \
	-eltorito-catalog isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-isohybrid-mbr $(ISO_TARGET)/isolinux/isohdpfx.bin \
	$(XORRISO_EFI_OPTS) \
	-m '$(ISO_TARGET)/.*' \
	-m '$(ISO_TARGET)/boot' \
	-m '$(ISO_TARGET)/bin' \
	-m '$(ISO_TARGET)/sbin' \
	-m '$(ISO_TARGET)/usr' \
	-m '$(ISO_TARGET)/dev' \
	-m '$(ISO_TARGET)/etc' \
	-m '$(ISO_TARGET)/home' \
	-m '$(ISO_TARGET)/lib*' \
	-m '$(ISO_TARGET)/root' \
	-m '$(ISO_TARGET)/var' \
	-m '$(ISO_TARGET)/media' \
	-m '$(ISO_TARGET)/mnt' \
	-m '$(ISO_TARGET)/opt' \
	-m '$(ISO_TARGET)/run' \
	-m '$(ISO_TARGET)/proc' \
	-m '$(ISO_TARGET)/srv' \
	-m '$(ISO_TARGET)/sys' \
	-m '$(ISO_TARGET)/tmp' \
	-publisher "Lunar Linux - http://www.lunar-linux.org/" \
	-volid '$(ISO_LABEL)' \
	-appid 'Lunar-$(ISO_VERSION)' $(ISO_TARGET)
	@mv $@.tmp $@
