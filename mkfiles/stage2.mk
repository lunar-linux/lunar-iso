.INTERMEDIATE: stage2 stage2-target stage2-base stage2-modules stage2-spool stage2-extract-moonbase stage2-moonbase stage2-toolchain stage2-build

.SECONDARY: $(ISO_TARGET)/.stage2-target $(ISO_TARGET)/.stage2-base $(ISO_TARGET)/.stage2-modules $(ISO_TARGET)/.stage2-spool $(ISO_TARGET)/.stage2-extract-moonbase $(ISO_TARGET)/.stage2-moonbase $(ISO_TARGET)/.stage2-toolchain $(ISO_TARGET)/.stage2

stage2: stage2-build $(ISO_TARGET)/var/cache/lunar/packages


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
	@ln -sf lib $(ISO_TARGET)/lib32
	@ln -sf lib $(ISO_TARGET)/lib64
	@mkdir -p $(ISO_TARGET)/usr
	@ln -sf lib $(ISO_TARGET)/usr/lib32
	@ln -sf lib $(ISO_TARGET)/usr/lib64
	@cp -r $(ISO_SOURCE)/template/etc $(ISO_TARGET)
	@echo MAKES=$(ISO_MAKES) > $(ISO_TARGET)/etc/lunar/local/optimizations.GNU_MAKE
	@touch $@

stage2-base: $(ISO_TARGET)/.stage2-base


# install the module caches
$(ISO_TARGET)/.stage2-modules: stage2-target
	@echo stage2-modules
	@for archive in $(ISO_SOURCE)/cache/*-$(ISO_BUILD).tar.xz ; do \
	  tar -xJf "$$archive" -C $(ISO_TARGET) || exit 1 ; \
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
	@ln $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

stage2-spool: $(ISO_TARGET)/.stage2-spool


$(ISO_TARGET)/.stage2-extract-moonbase: stage2-target $(ISO_SOURCE)/spool/moonbase.tar.bz2
	@echo stage2-extract-moonbase
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase
	@rm -r $(ISO_TARGET)/var/lib/lunar/moonbase
	@tar -xjf $(ISO_SOURCE)/spool/moonbase.tar.bz2 -C $(ISO_TARGET)/var/lib/lunar moonbase/core moonbase/aliases
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase/zlocal
	@mkdir -p $(ISO_TARGET)/var/state/lunar/moonbase
	@touch $(ISO_TARGET)/var/state/lunar/packages{,.backup}
	@cp $(ISO_SOURCE)/template/var/state/lunar/depends $(ISO_TARGET)/var/state/lunar/depends
	@cp $(ISO_TARGET)/var/state/lunar/depends{,.backup}
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
$(ISO_SOURCE)/conf/modules.all: $(ISO_SOURCE)/spool/moonbase.tar.bz2
	@echo ALL_MODULES=`tar -tf $< | sed -n 's@^moonbase/core/\([^/]*/\)*\([^/]\+\)/DETAILS$$@\2@p'` > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(ISO_SOURCE)/conf/modules.all
endif
include $(ISO_SOURCE)/conf/modules.stage2
include $(ISO_SOURCE)/conf/modules.kernel
include $(ISO_SOURCE)/conf/modules.exclude
-include $(ISO_SOURCE)/conf/modules.exclude.$(ISO_ARCH)

$(ISO_TARGET)/.stage2-toolchain: stage2-moonbase stage2-spool $(ISO_SOURCE)/conf/modules.all
	@echo stage2-toolchain
	@ASK_FOR_REBUILDS=n PROMPT_DELAY=0  $(ISO_SOURCE)/scripts/chroot-build lin -c $(STAGE2_MODULES)
	@touch $@

stage2-toolchain: $(ISO_TARGET)/.stage2-toolchain

$(ISO_TARGET)/.stage2: stage2-toolchain
	@echo stage2-build
	# XXX UGLY HACK XXX
	# lvm has a confusing dependency on %UDEV, which is so confusing
	# that it was commented out.  In the context of building an ISO,
	# though, lvm gets built before any kind of udev is available.
	# Edit lvm2's DEPENDS by arbitrarily nominating systemd which
	# will be installed anyway, to ensure systemd is built before
	# lbm2.
	@echo 'depends systemd' >> $(ISO_TARGET)/var/lib/lunar/moonbase/core/filesys/lvm2/DEPENDS
	@cp /etc/resolv.conf $(ISO_TARGET)/etc/resolv.conf
	@ASK_FOR_REBUILDS=n PROMPT_DELAY=0 $(ISO_SOURCE)/scripts/chroot-build bash -c 'for mod in `lsh sort_by_dependency $(filter-out $(KERNEL_MODULES) $(STAGE2_MODULES) $(EXCLUDE_MODULES),$(ALL_MODULES))`; do lin -c $$mod || exit 1; done'
	@rm -f $(ISO_TARGET)/etc/resolv.conf
	@touch $@

stage2-build: $(ISO_TARGET)/.stage2

$(ISO_TARGET)/var/cache/lunar/packages: stage2-build
	@mkdir -p $(ISO_TARGET)/var/cache/lunar
	@cp $(ISO_TARGET)/var/state/lunar/packages $@
