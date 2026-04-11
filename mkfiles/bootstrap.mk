.INTERMEDIATE: target bootstrap bootstrap-base bootstrap-sources bootstrap-toolchain bootstrap-modules

bootstrap: bootstrap-base install-moonbase bootstrap-sources bootstrap-toolchain bootstrap-modules


# this rule is shared with the download
$(ISO_STAMPS)/.target:
	@rm -rf $(ISO_TARGET)
	@mkdir -p $(ISO_TARGET) $(ISO_STAMPS)
	@touch $@

target: $(ISO_STAMPS)/.target


# fill the target with the base file required
$(ISO_STAMPS)/.base: $(ISO_STAMPS)/.target
	@echo bootstrap-base
	@mkdir -p $(ISO_TARGET)/{dev,proc,run,sys,tmp,usr/{bin,lib,sbin,src},var}
ifeq ($(ISO_MERGED_USR),yes)
	@ln -snf usr/bin $(ISO_TARGET)/bin
	@ln -snf usr/sbin $(ISO_TARGET)/sbin
	@ln -snf usr/lib $(ISO_TARGET)/lib
ifeq ($(ISO_ARCH),x86_64)
	@ln -snf usr/lib $(ISO_TARGET)/lib64
	@ln -snf lib $(ISO_TARGET)/usr/lib64
endif
ifeq ($(ISO_ARCH),i686)
	@ln -snf usr/lib $(ISO_TARGET)/lib32
	@ln -snf lib $(ISO_TARGET)/usr/lib32
endif
else
	@mkdir -p $(ISO_TARGET)/{bin,sbin,lib}
ifeq ($(ISO_ARCH),x86_64)
	@ln -snf lib $(ISO_TARGET)/lib64
	@ln -snf lib $(ISO_TARGET)/usr/lib64
endif
ifeq ($(ISO_ARCH),i686)
	@ln -snf lib $(ISO_TARGET)/lib32
	@ln -snf lib $(ISO_TARGET)/usr/lib32
endif
endif
	@ln -sf ../run/lock $(ISO_TARGET)/var/lock
	@ln -sf ../run $(ISO_TARGET)/var/run
	@cp -r $(ISO_SOURCE)/template/etc $(ISO_TARGET)
	@cp -r $(ISO_SOURCE)/template/var $(ISO_TARGET)
	@echo MAKES=$(ISO_MAKES) > $(ISO_TARGET)/etc/lunar/local/optimizations.GNU_MAKE
ifeq ($(ISO_MERGED_USR),yes)
	@echo "MERGED_USR=yes" > $(ISO_TARGET)/etc/lunar/local/merged-usr
endif
	@touch $@

bootstrap-base: $(ISO_STAMPS)/.base

$(ISO_STAMPS)/.bootstrap-sources: $(ISO_STAMPS)/.base $(ISO_STAMPS)/.install-moonbase
	@echo bootstrap-sources
	@$(ISO_SOURCE)/scripts/bootstrap-fetch-sources bootstrap
	@touch $@

bootstrap-sources: $(ISO_STAMPS)/.bootstrap-sources

$(ISO_STAMPS)/.bootstrap-toolchain: $(ISO_STAMPS)/.bootstrap-sources
	@echo bootstrap-toolchain
	@$(ISO_SOURCE)/scripts/bootstrap-build-toolchain
	@touch $@

bootstrap-toolchain: $(ISO_STAMPS)/.bootstrap-toolchain

$(ISO_STAMPS)/.bootstrap-modules: $(ISO_STAMPS)/.bootstrap-toolchain
	@echo bootstrap-modules
	@$(ISO_SOURCE)/scripts/bootstrap-build-modules
	@touch $@

bootstrap-modules: $(ISO_STAMPS)/.bootstrap-modules
