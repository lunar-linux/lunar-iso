.PHONY: stage1 stage1-spool stage1-moonbase stage1-toolchain stage1-build stage1-cache

stage1: stage1-cache


# install the sources
$(ISO_TARGET)/.stage1-spool: $(ISO_SOURCE)/spool/.copied
	@echo stage1-spool
	@mkdir -p $(ISO_TARGET)/var/spool/lunar
	@ln -f $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

stage1-spool: $(ISO_TARGET)/.stage1-spool


# generate the required cache files
$(ISO_TARGET)/.stage1-moonbase: $(ISO_TARGET)/.bootstrap-modules $(ISO_TARGET)/.install-moonbase
	@echo stage1-moonbase
	@grep -E '^make:' $(ISO_TARGET)/var/state/lunar/packages > $(ISO_TARGET)/var/state/lunar/packages.tmp || true
	@LUNAR_VER=$$(grep 'VERSION=' $(ISO_TARGET)/var/lib/lunar/moonbase/zlocal/lunar/DETAILS 2>/dev/null | head -1 | sed 's/.*VERSION=//'); \
	  echo "lunar:$$(date +%Y%m%d):installed:$${LUNAR_VER:-0}:0KB" >> $(ISO_TARGET)/var/state/lunar/packages.tmp
	@mv $(ISO_TARGET)/var/state/lunar/packages.tmp $(ISO_TARGET)/var/state/lunar/packages
	@cp $(ISO_TARGET)/var/state/lunar/packages $(ISO_TARGET)/var/state/lunar/packages.backup
	@$(ISO_SOURCE)/scripts/bootstrap-finalize-root
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

stage1-moonbase: $(ISO_TARGET)/.stage1-moonbase


# first build sequence to get the toolchain installed properly
include $(ISO_SOURCE)/conf/modules.toolchain

$(ISO_TARGET)/.stage1-toolchain: $(ISO_TARGET)/.stage1-moonbase $(ISO_TARGET)/.stage1-spool
	@echo stage1-toolchain
	@$(ISO_SOURCE)/scripts/chroot-build bash -c 'export LANG=C LC_ALL=C; for mod in $(TOOLCHAIN_MODULES); do lin -rc $$mod; lsh module_installed $$mod || { echo "ERROR: $$mod failed to build" >&2; exit 1; }; done' </dev/null
	@touch $@

stage1-toolchain: $(ISO_TARGET)/.stage1-toolchain


# first time build all the require modules for a minimal system
include $(ISO_SOURCE)/conf/modules.stage1

$(ISO_TARGET)/.stage1: $(ISO_TARGET)/.stage1-toolchain
	@echo stage1-build
	@$(ISO_SOURCE)/scripts/chroot-build bash -c 'export LANG=C LC_ALL=C; for mod in `lsh sort_by_dependency $(filter-out $(TOOLCHAIN_MODULES),$(STAGE1_MODULES))`; do lin -rc $$mod; lsh module_installed $$mod || { echo "ERROR: $$mod failed to build" >&2; exit 1; }; done' </dev/null
	@touch $@

stage1-build: $(ISO_TARGET)/.stage1


# replace the cache with the new build cache
$(ISO_SOURCE)/cache/.stage1: $(ISO_TARGET)/.stage1
	@echo stage1-cache
	@rm -rf $(ISO_SOURCE)/cache
	@cp -r $(ISO_TARGET)/var/cache/lunar $(ISO_SOURCE)/cache
	@grep $(patsubst %,-e^%:,$(STAGE1_MODULES)) $(ISO_TARGET)/var/state/lunar/packages | cat > $(ISO_SOURCE)/cache/packages
	@touch $@

stage1-cache: $(ISO_SOURCE)/cache/.stage1
