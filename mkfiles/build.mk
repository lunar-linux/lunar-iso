build: build-toolchain

$(ISO_TARGET)/.moonbase-build: $(ISO_TARGET)/.base $(ISO_TARGET)/.modules $(ISO_TARGET)/.moonbase-download 
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

build-moonbase: $(ISO_TARGET)/.moonbase-build

$(ISO_TARGET)/.toolchain: $(ISO_TARGET)/.moonbase-build
	yes n | lin -rc kernel-headers glibc binutils gcc binutils glibc
	@touch $@

build-toolchain: $(ISO_TARGET)/.toolchain

$(ISO_TARGET)/.stage1: $(iso_target)/.toolchain

build-stage1: $(ISO_TARGET)/.stage1
