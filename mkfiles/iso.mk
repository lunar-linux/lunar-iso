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
	@which isohybrid || lin syslinux


# Remove non iso modules
include $(ISO_SOURCE)/conf/modules.iso

SYSLINUX_FILES=isolinux.bin ldlinux.c32 libcom32.c32 libutil.c32

$(ISO_TARGET)/.iso-modules: iso-target $(addprefix $(ISO_TARGET)/isolinux/, $(SYSLINUX_FILES))
	@echo iso-modules
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lrm -n $(filter-out $(ISO_MODULES), $(ALL_MODULES))
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
ISOLINUX_FILES=README f1.txt f2.txt f3.txt f4.txt generate-iso.sh isolinux.cfg

.SECONDARY: $(addprefix $(ISO_TARGET)/usr/share/syslinux/, $(SYSLINUX_FILES))
$(addprefix $(ISO_TARGET)/usr/share/syslinux/, $(SYSLINUX_FILES)): $(ISO_TARGET)/.iso-isolinux
	@test -f $@
	@touch $@

$(ISO_TARGET)/isolinux/isolinux.bin: $(ISO_TARGET)/usr/share/syslinux/isolinux.bin
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


# Generate the actual image
$(ISO_SOURCE)/lunar-$(ISO_VERSION).iso: iso-tools iso-files iso-isolinux iso-strip installer
	@echo iso
	@mkisofs -o $@.tmp -R -J -l \
	-V '$(ISO_LABEL)' \
	-d -D -N -no-emul-boot -boot-load-size 4 -boot-info-table \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-m '$(ISO_TARGET)/.*' \
	-m '$(ISO_TARGET)/etc/lunar/local/*' \
	-m '$(ISO_TARGET)/tmp/*' \
	-m '$(ISO_TARGET)/var/tmp/*' \
	-m '$(ISO_TARGET)/var/spool/*' \
	-m '$(ISO_TARGET)/var/log/*' \
	-m '$(ISO_TARGET)/usr/lib/locale' \
	-m '$(ISO_TARGET)/usr/share/locale' \
	-m '$(ISO_TARGET)/usr/share/man/man2' \
	-m '$(ISO_TARGET)/usr/share/man/man3' \
	-m '$(ISO_TARGET)/usr/share/man/*/man2' \
	-m '$(ISO_TARGET)/usr/share/man/*/man3' \
	-m '$(ISO_TARGET)/usr/share/info' \
	-m '$(ISO_TARGET)/usr/share/gtk-doc' \
	-m '$(ISO_TARGET)/usr/include' \
	-m '$(ISO_TARGET)/usr/src' \
	-m '$(ISO_TARGET)/var/state/lunar/module_history' \
	-m 'doc' \
	-A 'Lunar-$(ISO_VERSION)' $(ISO_TARGET)
	@isohybrid $@.tmp
	@mv $@.tmp $@
