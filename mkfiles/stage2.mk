.INTERMEDIATE: stage2 stage2-target stage2-base stage2-modules stage2-spool stage2-extract-moonbase stage2-moonbase stage2-build

stage2: stage2-build


# clean the target directory for stage2
$(ISO_TARGET)/.stage2-target: stage1
	@echo stage2-target
	@rm -rf $(ISO_TARGET)
	@mkdir $(ISO_TARGET)
	@touch $@

stage2-target: $(ISO_TARGET)/.stage2-target


# create base directory structure
$(ISO_TARGET)/.stage2-base: stage2-target
	@echo stage2-base
	@mkdir -p $(ISO_TARGET)/{bin,dev,etc,lib,mnt,proc,root,run,sbin,sys,tmp,usr,var} $(ISO_TARGET)/run/lock $(ISO_TARGET)/usr/{bin,include,lib,libexec,sbin,src,share} $(ISO_TARGET)/var/{cache,empty,lib,log,spool,state,tmp}
	@ln -sf lib $(ISO_TARGET)/lib32
	@ln -sf lib $(ISO_TARGET)/lib64
	@ln -sf lib $(ISO_TARGET)/usr/lib32
	@ln -sf lib $(ISO_TARGET)/usr/lib64
	@ln -sf ../run/lock $(ISO_TARGET)/var/lock
	@ln -sf ../run $(ISO_TARGET)/var/run
	@cp -r $(ISO_SOURCE)/template/etc $(ISO_TARGET)
	@echo MAKES=$(ISO_MAKES) > $(ISO_TARGET)/etc/lunar/local/optimizations.GNU_MAKE
	@touch $@

stage2-base: $(ISO_TARGET)/.stage2-base


# install the module caches
$(ISO_TARGET)/.stage2-modules: stage2-target
	@echo stage2-modules
	@for archive in $(ISO_SOURCE)/cache/*-$(ISO_BUILD).tar.bz2 ; do \
	  tar -xjf "$$archive" -C $(ISO_TARGET) || exit 1 ; \
	done
	@mkdir -p $(ISO_TARGET)/var/state/lunar
	@touch $(ISO_TARGET)/var/state/lunar/packages.backup
	@grep -v "`sed 's/^/^/;s/:.*/:/' $(ISO_SOURCE)/cache/packages`" $(ISO_TARGET)/var/state/lunar/packages.backup | cat > $(ISO_TARGET)/var/state/lunar/packages
	@cat $(ISO_SOURCE)/cache/packages >> $(ISO_TARGET)/var/state/lunar/packages
	@cp $(ISO_TARGET)/var/state/lunar/packages $(ISO_TARGET)/var/state/lunar/packages.backup
	@touch $@

stage2-modules: $(ISO_TARGET)/.stage2-modules


# copy the source files
$(ISO_TARGET)/.stage2-spool: stage2-target download
	@echo stage2-spool
	@mkdir -p $(ISO_TARGET)/var/spool/lunar
	@cp $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

stage2-spool: $(ISO_TARGET)/.stage2-spool


$(ISO_TARGET)/.stage2-extract-moonbase: stage2-target $(ISO_SOURCE)/spool/moonbase.tar.bz2
	@echo stage2-extract-moonbase
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase
	@rm -r $(ISO_TARGET)/var/lib/lunar/moonbase
	@tar -xjf $(ISO_SOURCE)/spool/moonbase.tar.bz2 -C $(ISO_TARGET)/var/lib/lunar moonbase/core moonbase/aliases
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase/zlocal
	@mkdir -p $(ISO_TARGET)/var/state/lunar/moonbase
	@touch $(ISO_TARGET)/var/state/lunar/{packages,depends}{,.backup}
	@touch $@

stage2-extract-moonbase: $(ISO_TARGET)/.stage2-extract-moonbase


# generate the required cache files
$(ISO_TARGET)/.stage2-moonbase: stage2-base stage2-modules stage2-extract-moonbase
	@echo stage2-build-moonbase
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

stage2-moonbase: $(ISO_TARGET)/.stage2-moonbase


# build all the require modules for the iso
STAGE2_MODULES=kernel-headers glibc gcc binutils pkgconfig xz gettext attr acl gawk sed ncurses readline zlib cracklib libcap util-linux e2fsprogs libffi gmp bzip2 glib-2 wget shadow coreutils net-tools gzip mpfr procps file bash dialog diffutils findutils grep installwatch less tar patch libmpc lunar make

$(ISO_TARGET)/.stage2: stage2-moonbase stage2-spool
	@echo stage2-build
	#@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -c kernel-headers glibc gcc binutils
	@yes n | tr -d '\n' | $(ISO_SOURCE)/scripts/chroot-build lin -c $(STAGE2_MODULES)
	@touch $@

stage2-build: $(ISO_TARGET)/.stage2
