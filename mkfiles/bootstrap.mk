bootstrap: bootstrap-base bootstrap-lunar

# file the target with the base file required
$(ISO_TARGET)/.base: $(ISO_TARGET)/.stamp
	@mkdir -p $(ISO_TARGET)/{bin,dev,etc,lib,mnt,proc,root,run,sbin,sys,tmp,usr,var} $(ISO_TARGET)/run/lock $(ISO_TARGET)/usr/{bin,include,lib,libexec,sbin,src,share} $(ISO_TARGET)/var/{cache,empty,lib,log,spool,state,tmp}
	@ln -sf lib $(ISO_TARGET)/lib32
	@ln -sf lib $(ISO_TARGET)/lib64
	@ln -sf lib $(ISO_TARGET)/usr/lib32
	@ln -sf lib $(ISO_TARGET)/usr/lib64
	@ln -sf ../run/lock $(ISO_TARGET)/var/lock
	@ln -sf ../run $(ISO_TARGET)/var/run
	@cp -r $(ISO_SOURCE)/template/etc $(ISO_TARGET)
	@touch $@

bootstrap-base: $(ISO_TARGET)/.base

# bootstrap on a lunar host
$(ISO_SOURCE)/cache/.copied:
	@$(ISO_SOURCE)/scripts/bootstrap-lunar-cache
	@touch $@

$(ISO_TARGET)/.modules: $(ISO_SOURCE)/cache/.copied $(ISO_TARGET)/.stamp
	for archive in $(ISO_SOURCE)/cache/*-$(ISO_BUILD).tar.bz2 ; do \
	  tar -xjf "$$archive" -C $(ISO_TARGET) || exit 1 ; \
	done
	@touch $@

bootstrap-lunar: $(ISO_TARGET)/.modules


$(ISO_TARGET)/.stamp:
	@mkdir -p $(ISO_TARGET)
	@touch $@
