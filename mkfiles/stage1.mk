.INTERMEDIATE: stage1 stage1-spool stage1-moonbase stage1-toolchain stage1-build stage1-cache

stage1: stage1-cache


# install the sources
$(ISO_STAMPS)/.stage1-spool: download
	@echo stage1-spool
	@mkdir -p $(ISO_TARGET)/var/spool/lunar
	@ln -f $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

stage1-spool: $(ISO_STAMPS)/.stage1-spool


# generate the required cache files
$(ISO_STAMPS)/.stage1-moonbase: bootstrap install-moonbase
	@echo stage1-moonbase
	@cp $(ISO_TARGET)/var/state/lunar/packages $(ISO_TARGET)/var/state/lunar/packages.backup
	@$(ISO_SOURCE)/scripts/bootstrap-finalize-root
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_module_index
	@$(ISO_SOURCE)/scripts/chroot-build lsh create_depends_cache
	@$(ISO_SOURCE)/scripts/chroot-build lsh update_plugins
	@touch $@

stage1-moonbase: $(ISO_STAMPS)/.stage1-moonbase


# first build sequence to get the toolchain installed properly
include $(ISO_SOURCE)/conf/modules.toolchain

$(ISO_STAMPS)/.stage1-toolchain: stage1-moonbase stage1-spool
	@echo stage1-toolchain
	@$(ISO_SOURCE)/scripts/chroot-build bash -c 'export LANG=C LC_ALL=C; mods=($(TOOLCHAIN_MODULES)); n=0; for mod in $${mods[@]}; do n=$$((n+1)); echo "-> BUILDING $$mod ($$n of $${#mods[@]})"; lin -rc $$mod; lsh module_installed $$mod || { echo "ERROR: $$mod failed to build" >&2; exit 1; }; done' </dev/null
	@touch $@

stage1-toolchain: $(ISO_STAMPS)/.stage1-toolchain


# first time build all the require modules for a minimal system
include $(ISO_SOURCE)/conf/modules.stage1

$(ISO_STAMPS)/.stage1: stage1-toolchain
	@echo stage1-build
	@$(ISO_SOURCE)/scripts/chroot-build bash -c 'export LANG=C LC_ALL=C; mods=($$(lsh sort_by_dependency $(filter-out $(TOOLCHAIN_MODULES),$(STAGE1_MODULES)))); n=0; for mod in $${mods[@]}; do n=$$((n+1)); echo "-> BUILDING $$mod ($$n of $${#mods[@]})"; lin -rc $$mod; lsh module_installed $$mod || { echo "ERROR: $$mod failed to build" >&2; exit 1; }; done' </dev/null
	@touch $@

stage1-build: $(ISO_STAMPS)/.stage1


# replace the cache with the new build cache
$(ISO_SOURCE)/cache/.stage1: stage1-build
	@echo stage1-cache
	@rm -rf $(ISO_SOURCE)/cache
	@cp -r $(ISO_TARGET)/var/cache/lunar $(ISO_SOURCE)/cache
	@grep $(patsubst %,-e^%:,$(STAGE1_MODULES)) $(ISO_TARGET)/var/state/lunar/packages | cat > $(ISO_SOURCE)/cache/packages
	@touch $@

stage1-cache: $(ISO_SOURCE)/cache/.stage1
