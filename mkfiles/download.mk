.INTERMEDIATE: download install-moonbase download-lunar
.PHONY: download-moonbase moonbase-git

.SECONDARY: $(ISO_TARGET)/.install-moonbase

download: download-lunar


# download the moonbase
download-moonbase $(ISO_SOURCE)/spool/moonbase.tar.bz2:
	@echo download-moonbase
	@mkdir -p $(ISO_SOURCE)/spool
	@wget -O $@.tmp "`lsh echo '$$MOONBASE_URL'`/moonbase.tar.bz2"
	@mv $@.tmp $@


# note: this installs an empty installed packages list
$(ISO_TARGET)/.install-moonbase: $(ISO_SOURCE)/spool/moonbase.tar.bz2 target
	@echo install-moonbase
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase
	@rm -r $(ISO_TARGET)/var/lib/lunar/moonbase
	@tar -xjf $< -C $(ISO_TARGET)/var/lib/lunar moonbase/core moonbase/aliases
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase/zlocal
	@mkdir -p $(ISO_TARGET)/var/state/lunar/moonbase
	@touch $(ISO_TARGET)/var/state/lunar/{packages,depends}{,.backup}
	@touch $@

install-moonbase: $(ISO_TARGET)/.install-moonbase


# download on a lunar host
$(ISO_SOURCE)/spool/.copied: install-moonbase
	@echo download-lunar
	@$(ISO_SOURCE)/scripts/download-lunar-spool
	@touch $@

download-lunar: $(ISO_SOURCE)/spool/.copied


# Update the moonbase.tar.bz2 file from git
moonbase-git:
	@echo moonbase-git
	@$(ISO_SOURCE)/scripts/pack-moonbase-git
