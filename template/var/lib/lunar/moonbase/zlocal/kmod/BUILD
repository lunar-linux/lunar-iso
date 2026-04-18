OPTS+=" --with-zlib \
        --with-xz \
        --with-openssl"

./configure --prefix=     \
            --libdir=/lib \
            --datarootdir=/usr/share \
            --includedir=/usr/include \
            $OPTS  &&

default_make &&

install -dm755 /{etc,usr/lib}/{depmod,modprobe}.d &&

# Detect merged /usr layout
MERGED_USR=0
if [ -L /lib ] && [ "$(readlink /lib)" = "usr/lib" ]; then
  MERGED_USR=1
fi &&

# Traditional /bin + /sbin wrappers (work natively on merged /usr; on
# non-merged they remain the legacy entry points).
ln -sf /bin/kmod "/bin/lsmod" &&
for tool in {ins,rm,dep}mod mod{info,probe}; do
  ln -sf /bin/kmod "/sbin/$tool"
done &&

# On split /usr, mirror the wrappers under /usr/{bin,sbin} so they fall in
# systemd's default PATH (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin)
# and unit-file ConditionPathExists checks that expect /usr/bin/kmod resolve.
# systemd 260 switched kmod-static-nodes.service from /bin/kmod to
# /usr/bin/kmod; without this mirror the service is silently skipped and
# /dev/loop-control never gets created in the initrd, breaking dmsquash-live.
if [ "$MERGED_USR" -eq 0 ]; then
  ln -sf /bin/kmod "/usr/bin/kmod" &&
  ln -sf /bin/kmod "/usr/bin/lsmod" &&
  for tool in {ins,rm,dep}mod mod{info,probe}; do
    ln -sf /bin/kmod "/usr/sbin/$tool"
  done
fi
