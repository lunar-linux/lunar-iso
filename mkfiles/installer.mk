.INTERMEDIATE: installer lunar-install

installer: lunar-install


# Install the Lunar installer
$(ISO_TARGET)/.lunar-install: iso-target
	@echo lunar-install
	@cp -r $(ISO_SOURCE)/lunar-install/* $(ISO_TARGET)
	@touch $@

# Generate locale list
$(ISO_TARGET)/usr/share/lunar-install/locale.list: iso-target
	@echo locale.list
	@mkdir -p $(ISO_TARGET)/usr/share/lunar-install
	@$(ISO_SOURCE)/scripts/chroot-build locale -a -v | \
	sed -rn 's;archive.*|locale:|language \||territory \|;;gp' | \
	awk '{printf $$0 ; printf " "} NR % 3 == 0 {print " "}' | \
	while read locale language territory ; do \
	  echo -e "$$locale\t$$language ($$territory)" ; \
	done > $@

lunar-install: $(ISO_TARGET)/.lunar-install $(ISO_TARGET)/usr/share/lunar-install/locale.list
