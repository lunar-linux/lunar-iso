.INTERMEDIATE: installer lunar-install

installer: lunar-install


# Install the Lunar installer
$(ISO_TARGET)/.lunar-install: iso-target
	@echo lunar-install
	@cp -r $(ISO_SOURCE)/lunar-install/* $(ISO_TARGET)
	@touch $@

lunar-install: $(ISO_TARGET)/.lunar-install
