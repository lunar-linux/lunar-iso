.INTERMEDIATE: pack pack-base

pack: pack-base


# Create listing of all potention installed files
.INTERMEDIATE: $(ISO_TARGET)/.aaa_base.found
$(ISO_TARGET)/.aaa_base.found: stage2
	@echo pack-find
	@find $(ISO_TARGET) ! -path '$(ISO_TARGET)/.*' -printf '/%P\n' \( \
	-path '$(ISO_TARGET)/dev' -o \
	-path '$(ISO_TARGET)/etc/lunar/local' -o \
	-path '$(ISO_TARGET)/mnt' -o \
	-path '$(ISO_TARGET)/proc' -o \
	-path '$(ISO_TARGET)/root' -o \
	-path '$(ISO_TARGET)/sys' -o \
	-path '$(ISO_TARGET)/tmp' -o \
	-path '$(ISO_TARGET)/usr/include' -o \
	-path '$(ISO_TARGET)/usr/lib' -o \
	-path '$(ISO_TARGET)/usr/libexec' -o \
	-path '$(ISO_TARGET)/usr/share' -o \
	-path '$(ISO_TARGET)/var/cache' -o \
	-path '$(ISO_TARGET)/var/lib/lunar' -o \
	-path '$(ISO_TARGET)/var/log' -o \
	-path '$(ISO_TARGET)/var/spool' -o \
	-path '$(ISO_TARGET)/var/state/lunar' \) -prune > $@

# Create listing of all installed files
.INTERMEDIATE: $(ISO_TARGET)/.aaa_base.tracked
$(ISO_TARGET)/.aaa_base.tracked: stage2
	@echo pack-tracked
	@sort -u $(ISO_TARGET)/var/log/lunar/install/* > $@

# Filter listing of all installed files
.INTERMEDIATE: $(ISO_TARGET)/.aaa_base.filtered
$(ISO_TARGET)/.aaa_base.filtered: $(ISO_TARGET)/.aaa_base.found $(ISO_TARGET)/.aaa_base.tracked
	@echo pack-filtered
	@sort $^ | uniq -d > $@

# Diff listing of files
.INTERMEDIATE: $(ISO_TARGET)/.aaa_base.list
$(ISO_TARGET)/.aaa_base.list: $(ISO_TARGET)/.aaa_base.found $(ISO_TARGET)/.aaa_base.filtered
	@echo pack-list
	@sort $^ | uniq -u | sed 's:^/::' > $@

# Create tar with not tracked files
$(ISO_TARGET)/var/spool/lunar/aaa_base.tar.bz2: $(ISO_TARGET)/.aaa_base.list
	@echo pack-base
	@tar -cjf $@ -C $(ISO_TARGET) --no-recursion -T $<

pack-base: $(ISO_TARGET)/var/spool/lunar/aaa_base.tar.bz2
