# Detect merged /usr layout
MERGED_USR=0
if [ -L /lib ] && [ "$(readlink /lib)" = "usr/lib" ]; then
  MERGED_USR=1
fi &&

prepare_install &&

# prepare_install/lrm may leave stale hashed command paths pointing at the
# pre-removal /bin entries. Refresh them after restoring the hierarchy.
hash -r &&

# On merged /usr, lrm removes the /bin, /lib, /sbin symlinks during
# prepare_install. Restore them first so the rest of the script works.
if [ "$MERGED_USR" -eq 1 ]; then
  mkdir -p /usr/{bin,lib,sbin}
  ln -snf usr/bin  /bin
  ln -snf usr/lib  /lib
  ln -snf usr/sbin /sbin
  case "$(uname -m)" in
    x86_64)
      ln -snf usr/lib /lib64
      ln -snf lib     /usr/lib64
      ;;
    i686)
      ln -snf usr/lib /lib32
      ln -snf lib     /usr/lib32
      ;;
  esac
else
  mkdir -p /{bin,lib,sbin}
  case "$(uname -m)" in
    x86_64)
      ln -snf lib /lib64
      ln -snf lib /usr/lib64
      ;;
    i686)
      ln -snf lib /lib32
      ln -snf lib /usr/lib32
      ;;
  esac
fi &&

# / Requirements
mkdir -p /{boot,dev,etc,media,mnt,opt,srv,tmp,usr,var} &&

# / Specific Options
mkdir -p /{home,root} &&

# /etc Requirements
mkdir -p /etc/opt &&

# /etc Specific Options
ln -sf /proc/self/mounts /etc/mtab &&

# /lib Specific Options
mkdir -p /lib/modules &&

# /usr Requirements
mkdir -p /usr/{bin,include,lib,local,sbin,share} &&

# /usr Specific Options
mkdir -p /usr/{games,src} &&

# /usr/local Requirements
mkdir -p /usr/local/{bin,etc,games,include,lib,man,sbin,share,src} &&

# /usr/share Requirements
mkdir -p /usr/share/{man,misc} &&

# /usr/share Specific Options
mkdir -p /usr/share/games &&

# /var Requirements
mkdir -p /var/{cache,lib,local,log,opt,spool,tmp} &&
# /var Systemd addition
ln -sfT ../run /var/run &&
ln -sfT ../run/lock /var/lock &&

# /var Specific Options
mkdir -p /var/games &&

# Linux addition
mkdir -p /{proc,sys} &&

# / Systemd addition
mkdir -p /run/lock &&

# ld.so.conf and ld.so.conf.d
mkdir -p /etc/ld.so.conf.d &&

# Always overwrite ld.so.conf with our version
install -Dm644 $SCRIPT_DIRECTORY/templates/etc/ld.so.conf /etc/ld.so.conf &&

# Migration code
if [ ! -e "/etc/nsswitch.conf" ] || [ "$(md5sum /etc/nsswitch.conf | cut -d' ' -f1)" == "3579b33b39600875ee113b4b63e895c5" ]; then
  install -Dm644 $SCRIPT_DIRECTORY/templates/etc/nsswitch.conf /etc/nsswitch.conf
fi
