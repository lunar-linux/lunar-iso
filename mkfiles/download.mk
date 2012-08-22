download-sources: install-moonbase download-lunar

install-sources: install-spool


# download the moonbase
$(ISO_SOURCE)/spool/moonbase.tar.bz2: $(ISO_SOURCE)/spool/.stamp
	@echo download-moonbase
	@wget -O $@ "`lsh eval echo '$$MOONBASE_URL'`/moonbase.tar.bz2" \
	  || { rm $@ ; exit 1 ; }
	@touch $@

# note: this installs an empty installed packages list
$(ISO_TARGET)/.moonbase-download: $(ISO_TARGET)/.stamp $(ISO_SOURCE)/spool/moonbase.tar.bz2
	@echo install-moonbase
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase
	@rm -r $(ISO_TARGET)/var/lib/lunar/moonbase
	@tar -xjf $(ISO_SOURCE)/spool/moonbase.tar.bz2 -C $(ISO_TARGET)/var/lib/lunar moonbase/core moonbase/aliases
	@mkdir -p $(ISO_TARGET)/var/lib/lunar/moonbase/zlocal
	@mkdir -p $(ISO_TARGET)/var/state/lunar/moonbase
	@touch $(ISO_TARGET)/var/state/lunar/{packages,depends}{,.backup}
	@touch $@

install-moonbase: $(ISO_TARGET)/.moonbase-download


# download on a lunar host
$(ISO_SOURCE)/spool/.copied: $(ISO_TARGET)/.moonbase-download
	@echo download-lunar
	@$(ISO_SOURCE)/scripts/download-lunar-spool
	@touch $@

download-lunar: $(ISO_SOURCE)/spool/.copied


# install the sources
$(ISO_TARGET)/.spool: $(ISO_SOURCE)/spool/.copied
	@echo install-spool
	@mkdir -p $(ISO_TARGET)/var/spool/lunar
	@cp $(ISO_SOURCE)/spool/* $(ISO_TARGET)/var/spool/lunar/
	@touch $@

install-spool: $(ISO_TARGET)/.spool


# create the spool directory
$(ISO_SOURCE)/spool/.stamp:
	@mkdir -p $(ISO_SOURCE)/spool
	@touch $@
