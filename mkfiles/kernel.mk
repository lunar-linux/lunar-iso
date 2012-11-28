.INTERMEDIATE: kernel linux

kernel: linux


$(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar.bz2: stage2
	cp $(ISO_SOURCE)/kernels/conf/generic $(ISO_TARGET)/etc/lunar/local/.config.current
	yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -c linux
	mv $(ISO_TARGET)/boot/vmlinuz-* $(ISO_TARGET)/boot/linux
	mv $(ISO_TARGET)/boot/initramfs-*.img $(ISO_TARGET)/boot/initrd
	mv $(ISO_TARGET)/var/cache/lunar/linux-$$($(ISO_SOURCE)/scripts/chroot-build lvu installed linux)-$(ISO_BUILD).tar.bz2 $@

linux: $(ISO_TARGET)/var/cache/lunar/linux-$(ISO_ARCH).tar.bz2
