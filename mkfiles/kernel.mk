.INTERMEDIATE: kernel linux

kernel: linux


.SECONDARY: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar
$(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar: stage2
	@echo linux
	@cp $(ISO_SOURCE)/kernels/conf/generic.$(ISO_ARCH) $(ISO_TARGET)/etc/lunar/local/.config.current
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -c linux
	@mv $(ISO_TARGET)/boot/vmlinuz-* $(ISO_TARGET)/boot/linux
	@mv $(ISO_TARGET)/boot/initramfs-*.img $(ISO_TARGET)/boot/initrd
	@bunzip2 -c $(ISO_TARGET)/var/cache/lunar/linux-$$($(ISO_SOURCE)/scripts/chroot-build lvu installed linux)-$(ISO_BUILD).tar.bz2 > $@.tmp
	@rm $(ISO_TARGET)/var/cache/lunar/linux-$$($(ISO_SOURCE)/scripts/chroot-build lvu installed linux)-$(ISO_BUILD).tar.bz2
	@mv $@.tmp $@

.INTERMEDIATE: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).files
$(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).files: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar
	@find $(ISO_TARGET)/usr/src -path '$(ISO_TARGET)/usr/src/linux*' ! -type d \( \
	-type l -o \
	-path '$(ISO_TARGET)/usr/src/linux-*/.config' -o \
	-path '$(ISO_TARGET)/usr/src/linux-*/Module.symvers' -o \
	-path '$(ISO_TARGET)/usr/src/linux-*/scripts/*' -o \
	-path '$(ISO_TARGET)/usr/src/linux-*/include/*' -o \
	-name 'Makefile*' -o \
	-name 'Kconfig*' \) -printf 'usr/src/%P\n' > $@

$(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar.bz2: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).files
	@tar -rf $< -C $(ISO_TARGET) -T $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).files
	@rm $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).files
	@echo 'linux-$(ISO_ARCH):You have no choice' > $(ISO_TARGET)/var/cache/lunar/kernels
	@bzip2 $<

linux: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar.bz2
