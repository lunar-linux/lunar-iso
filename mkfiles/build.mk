build: build-toolchain


# generate the required cache files
$(ISO_TARGET)/.moonbase-build: $(ISO_TARGET)/.base $(ISO_TARGET)/.modules $(ISO_TARGET)/.moonbase-download 
	@echo build-moonbase
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

build-moonbase: $(ISO_TARGET)/.moonbase-build


# first build sequence to get the toolchain installed properly
# note: xz is added. The package list is empty and thereby the xz plugin isn't installed.
$(ISO_TARGET)/.toolchain: $(ISO_TARGET)/.moonbase-build $(ISO_TARGET)/.spool
	@echo build-toolchain
	@yes n | $(ISO_SOURCE)/scripts/chroot-build lin -rc kernel-headers glibc binutils gcc binutils glibc
	@touch $@

build-toolchain: $(ISO_TARGET)/.toolchain


# first time build all the require modules for a minimal system
STAGE1_MODULES=acl attr bash bzip2 coreutils cracklib dialog diffutils e2fsprogs file findutils gawk gettext glib-2 gmp grep gzip installwatch less libcap libffi libmpc lunar make mpfr ncurses net-tools patch procps readline sed shadow tar util-linux wget xz zlib

$(ISO_TARGET)/.stage1: $(ISO_TARGET)/.toolchain
	yes n | $(ISO_SOURCE)/scripts/chroot-build lin -rc $(STAGE1_MODULES)
	@touch $@

build-stage1: $(ISO_TARGET)/.stage1
