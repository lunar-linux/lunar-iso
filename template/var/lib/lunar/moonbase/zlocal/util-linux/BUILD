export PYTHONDONTWRITEBYTECODE=1 &&

#Unknown group 'rfkill', lets make one
add_priv_group rfkill &&

if module_installed Linux-PAM; then
  OPTS+=" --enable-chfn-chsh"
else
  OPTS+=" --disable-chfn-chsh"
fi &&

OPTS+=" --enable-agetty     \
        --enable-fsck       \
        --enable-mesg       \
        --enable-partx      \
        --enable-rename     \
        --enable-schedutils \
        --enable-vipw       \
        --enable-newgrp     \
        --enable-write      \
        --disable-kill      \
        --disable-static    \
        --enable-fs-paths-extra=/usr/bin:/usr/sbin"

default_config &&
make ${MAKES:+-j${MAKES}} &&
mkdir _pkg &&
make install DESTDIR=$(cd _pkg && pwd) &&
mv _pkg/sbin/sulogin _pkg/usr/sbin &&
mv _pkg/bin/lsblk _pkg/usr/bin &&

chmod 700 _pkg/usr/bin/wall &&
chmod 4711 _pkg/usr/bin/newgrp &&
if [ -f _pkg/usr/bin/chsh ]; then
  chmod 4711 _pkg/usr/bin/{chsh,chfn}
fi &&
if module_installed systemd; then
  sedit '/ListenStream/ aRuntimeDirectory=uuidd' _pkg/usr/lib/systemd/system/uuidd.socket
fi &&

# On merged /usr, merge staging /bin, /sbin, /lib into their /usr
# counterparts so cp does not try to overwrite the root symlinks.
if [ -L /lib ] && [ "$(readlink /lib)" = "usr/lib" ]; then
  for _dir in bin sbin lib; do
    if [ -d _pkg/$_dir ] && [ ! -L _pkg/$_dir ]; then
      cp -a _pkg/$_dir/* _pkg/usr/$_dir/ 2>/dev/null || true
      rm -rf _pkg/$_dir
    fi
  done
fi &&

cd _pkg &&
prepare_install &&
cp -rf ./* / &&

install -g0 -o0 -m755 $SCRIPT_DIRECTORY/make-issue /usr/bin/make-issue &&
install -Dm644 $SCRIPT_DIRECTORY/60-rfkill.rules /usr/lib/udev/rules.d/60-rfkill.rules &&
ln -sf /usr/bin/last /usr/bin/lastb &&

#/usr/lib/tmpfiles.d/uuidd-tmpfiles.conf:6: Failed to resolve user 'uuidd': No such process
add_priv_group uuidd &&
add_priv_user uuidd -d /var/lib/uuidd -g sddm
