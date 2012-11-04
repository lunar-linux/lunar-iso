.INTERMEDIATE: target bootstrap bootstrap-base bootstrap-lunar

.SECONDARY: $(ISO_TARGET)/.base $(ISO_TARGET)/.modules $(ISO_SOURCE)/cache/.copied

bootstrap: bootstrap-base bootstrap-lunar


# this rule is shared with the download
$(ISO_TARGET)/.target:
	@rm -rf $(ISO_TARGET)
	@mkdir -p $(ISO_TARGET)
	@touch $@

target: $(ISO_TARGET)/.target


# fill the target with the base file required
$(ISO_TARGET)/.base: target
	@echo bootstrap-base
	@mkdir -p $(ISO_TARGET)/{boot,bin,dev,etc,lib,mnt,proc,root,run,sbin,sys,tmp,usr,var} $(ISO_TARGET)/run/lock $(ISO_TARGET)/usr/{bin,include,lib,libexec,sbin,src,share} $(ISO_TARGET)/var/{cache,empty,lib,log,spool,state,tmp}
	@ln -sf lib $(ISO_TARGET)/lib32
	@ln -sf lib $(ISO_TARGET)/lib64
	@ln -sf lib $(ISO_TARGET)/usr/lib32
	@ln -sf lib $(ISO_TARGET)/usr/lib64
	@ln -sf ../run/lock $(ISO_TARGET)/var/lock
	@ln -sf ../run $(ISO_TARGET)/var/run
	@cp -r $(ISO_SOURCE)/template/etc $(ISO_TARGET)
	@echo MAKES=$(ISO_MAKES) > $(ISO_TARGET)/etc/lunar/local/optimizations.GNU_MAKE
	@touch $@

bootstrap-base: $(ISO_TARGET)/.base


# bootstrap on a lunar host
$(ISO_SOURCE)/cache/.copied:
	@echo bootstrap-lunar-cache
	@$(ISO_SOURCE)/scripts/bootstrap-lunar-cache
	@touch $@

# note: use cat after grep to ignore the exit code of grep
$(ISO_TARGET)/.modules: $(ISO_SOURCE)/cache/.copied
	@echo bootstrap-lunar
	@mkdir -p $(ISO_TARGET)
	@for archive in $(ISO_SOURCE)/cache/*-$(ISO_BUILD).tar.bz2 ; do \
	  tar -xjf "$$archive" -C $(ISO_TARGET) || exit 1 ; \
	done
	@mkdir -p $(ISO_TARGET)/var/state/lunar
	@touch $(ISO_TARGET)/var/state/lunar/packages.backup
	@grep -v "`sed 's/^/^/;s/:.*/:/' $(ISO_SOURCE)/cache/packages`" $(ISO_TARGET)/var/state/lunar/packages.backup | cat > $(ISO_TARGET)/var/state/lunar/packages
	@cat $(ISO_SOURCE)/cache/packages >> $(ISO_TARGET)/var/state/lunar/packages
	@cp $(ISO_TARGET)/var/state/lunar/packages $(ISO_TARGET)/var/state/lunar/packages.backup
	@touch $@

bootstrap-lunar: $(ISO_TARGET)/.modules
