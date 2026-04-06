#!/bin/bash

set -euo pipefail

: "${ISO_SOURCE:?ISO_SOURCE is required}"
: "${ISO_TARGET:?ISO_TARGET is required}"

BOOTSTRAP_PREFIX="${BOOTSTRAP_PREFIX:-$ISO_TARGET/tools}"
BOOTSTRAP_WORKDIR="${BOOTSTRAP_WORKDIR:-$ISO_TARGET/.bootstrap-work}"
MOONBASE_ROOT="${MOONBASE_ROOT:-$ISO_TARGET/var/lib/lunar/moonbase/core}"

if [ -f "$ISO_SOURCE/conf/modules.bootstrap" ]; then
  # shellcheck disable=SC1091
  . "$ISO_SOURCE/conf/modules.bootstrap"
fi

BOOTSTRAP_TOOLCHAIN_FETCH_MODULES="${BOOTSTRAP_TOOLCHAIN_FETCH_MODULES:-kernel-headers gmp mpfr libmpc}"
BOOTSTRAP_TOOLCHAIN_SUPPORT_MODULES="${BOOTSTRAP_TOOLCHAIN_SUPPORT_MODULES:-gmp mpfr libmpc}"
BOOTSTRAP_CROSS_TEMP_TOOLS="${BOOTSTRAP_CROSS_TEMP_TOOLS:-m4 ncurses bash coreutils file findutils gawk grep gzip make patch sed tar xz}"
BOOTSTRAP_CHROOT_TEMP_TOOLS="${BOOTSTRAP_CHROOT_TEMP_TOOLS:-diffutils gettext perl bison zlib python ninja meson texinfo util-linux}"
BOOTSTRAP_IGNORE_MODULES="${BOOTSTRAP_IGNORE_MODULES:-cmake dialog less ncurses python-setuptools python-wheel python-build python-installer dbus systemd gnu-efi pciutils kbd iptables iproute2 check autoconf-archive intltool python-markupsafe python-jinja2 python-pyelftools IO-Capture Devel-CheckLib XML-Parser kmod Linux-PAM cracklib shadow e2fsprogs rpmunpack procps}"

bootstrap_default_target()
{
  local host cpu

  host="${BOOTSTRAP_HOST:-${ISO_BUILD:-$(gcc -dumpmachine)}}"
  cpu="${host%%-*}"
  printf '%s\n' "${cpu}-lfs-linux-gnu"
}

bootstrap_log()
{
  echo "[bootstrap] $*"
}

bootstrap_ignore_module()
{
  local module="$1"
  local ignored

  for ignored in $BOOTSTRAP_IGNORE_MODULES; do
    if [ "$ignored" = "$module" ]; then
      return 0
    fi
  done
  return 1
}

bootstrap_expand_dependency_alias()
{
  local dep="$1"

  case "$dep" in
    %SSL|%OSSL)
      printf '%s\n' "openssl"
      ;;
    *)
      printf '%s\n' "$dep"
      ;;
  esac
}

ensure_dir()
{
  mkdir -p "$@"
}

download_file()
{
  local url="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if command -v wget >/dev/null 2>&1; then
    wget -O "$dest.tmp" "$url"
  else
    curl -L -o "$dest.tmp" "$url"
  fi
  mv "$dest.tmp" "$dest"
}

module_dir()
{
  local module="$1"
  local path

  path="$(find "$MOONBASE_ROOT" -mindepth 1 -maxdepth 4 -type f -path "*/$module/DETAILS" | head -n 1)"
  [ -n "$path" ] || return 1
  dirname "$path"
}

module_exists()
{
  module_dir "$1" >/dev/null 2>&1
}

extract_assignment_block()
{
  local details="$1"
  local variable="$2"
  awk -v var="$variable" '
    BEGIN { capture = 0; depth = 0 }
    capture == 0 && $0 ~ ("^[[:space:]]*" var "[[:space:]]*=") {
      capture = 1
    }
    capture == 1 {
      print
      depth += gsub(/\(/, "&") - gsub(/\)/, "&")
      if ($0 !~ /\\[[:space:]]*$/ && depth <= 0) {
        exit
      }
    }
  ' "$details"
}

extract_assignment_lines()
{
  local details="$1"
  awk '
    /^[[:space:]]*[A-Z_][A-Z0-9_]*(\[[0-9]+\])?[[:space:]]*=/ {
      print
    }
  ' "$details"
}

extract_dependency_calls()
{
  local file="$1"
  awk '
    /^[[:space:]]*(depends|requires|module_depends)[[:space:]]+/ {
      print
    }
  ' "$file"
}

_metadata_loader()
{
  cat <<'EOF'
set -e
declare -a __module_depends=()

depends() { __module_depends+=("$1"); }
requires() { __module_depends+=("$1"); }
module_depends() { __module_depends+=("$1"); }
EOF
}

load_module_metadata()
{
  local module="$1"
  local details
  local depends_file
  local deps_snippet
  local assignment_snippet

  details="$(module_dir "$module")/DETAILS"
  depends_file="$(module_dir "$module")/DEPENDS"
  unset __module_depends VERSION SOURCE SOURCE2 SOURCE_URL SOURCE2_URL SOURCE_URL_FULL SOURCE_DIRECTORY BUILD_DIRECTORY PROFILE
  deps_snippet="$(extract_dependency_calls "$details")"
  if [ -f "$depends_file" ]; then
    deps_snippet="$deps_snippet
$(extract_dependency_calls "$depends_file")"
  fi
  assignment_snippet="$(extract_assignment_lines "$details")"
  eval "$(
    {
      printf '%s\n' "$(_metadata_loader)"
      cat <<EOF
set +u
MODULE="$module"
GNU_URL="https://ftpmirror.gnu.org"
KDE_URL="https://download.kde.org"
GNOME_URL="https://download.gnome.org"
KERNEL_URL="https://cdn.kernel.org"
SFORGE_URL="https://downloads.sourceforge.net/sourceforge"
XFREE86_URL="http://ftp.xfree86.org/pub/XFree86"
XORG_URL="https://www.x.org/releases"
LRESORT_URL="http://download.lunar-linux.org/lunar/cache"
NVIDIA_URL="https://download.nvidia.com/XFree86"
PATCH_URL="http://download.lunar-linux.org/lunar/patches/"
MIRROR_URL="http://download.lunar-linux.org/lunar/mirrors/"
BUILD_DIRECTORY="\${BUILD_DIRECTORY:-$BOOTSTRAP_WORKDIR/modules/$module}"
EOF
      printf '%s\n' "$assignment_snippet"
      printf '%s\n' "$deps_snippet"
      printf '%s\n' 'declare -p __module_depends 2>/dev/null || true'
      printf '%s\n' 'declare -p VERSION 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE2 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE_URL 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE2_URL 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE_URL_FULL 2>/dev/null || true'
      printf '%s\n' 'declare -p SOURCE_DIRECTORY 2>/dev/null || true'
      printf '%s\n' 'declare -p BUILD_DIRECTORY 2>/dev/null || true'
      printf '%s\n' 'declare -p PROFILE 2>/dev/null || true'
    } | bash | sed 's/^declare \(-[^ ]*\) /declare -g \1 /'
  )"
}

module_dependencies()
{
  local module="$1"
  local dep

  load_module_metadata "$module"
  for dep in "${__module_depends[@]:-}"; do
    dep="${dep%%:*}"
    dep="${dep%%\?*}"
    dep="${dep%%,*}"
    dep="$(bootstrap_expand_dependency_alias "$dep")"
    [ -n "$dep" ] || continue
    if module_exists "$dep"; then
      printf '%s\n' "$dep"
    fi
  done | sort -u
}

module_versions()
{
  local module="$1"
  load_module_metadata "$module"
  printf '%s\n' "${VERSION:-unknown}"
}

module_sources()
{
  local module="$1"
  local -a names=()
  local declared

  load_module_metadata "$module"
  if declare -p SOURCE >/dev/null 2>&1; then
    declared="$(declare -p SOURCE 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      names=("${SOURCE[@]}")
    elif [ -n "${SOURCE:-}" ]; then
      names=($SOURCE)
    fi
  fi

  if [ "${#names[@]}" -eq 0 ] && declare -p SOURCE_URL >/dev/null 2>&1; then
    declared="$(declare -p SOURCE_URL 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      local url
      for url in "${SOURCE_URL[@]}"; do
        names+=("${url##*/}")
      done
    elif [ -n "${SOURCE_URL:-}" ]; then
      for url in $SOURCE_URL; do
        names+=("${url##*/}")
      done
    fi
  fi

  if [ "${#names[@]}" -eq 0 ] && [ -n "${SOURCE_URL_FULL:-}" ]; then
    names+=("${SOURCE_URL_FULL##*/}")
  fi

  if declare -p SOURCE2 >/dev/null 2>&1; then
    declared="$(declare -p SOURCE2 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      names+=("${SOURCE2[@]}")
    elif [ -n "${SOURCE2:-}" ]; then
      names+=($SOURCE2)
    fi
  fi

  if [ "${#names[@]}" -gt 0 ]; then
    printf '%s\n' "${names[@]}"
  fi
}

module_source_urls()
{
  local module="$1"
  local -a urls=()
  local declared

  load_module_metadata "$module"
  if declare -p SOURCE_URL >/dev/null 2>&1; then
    declared="$(declare -p SOURCE_URL 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      urls=("${SOURCE_URL[@]}")
    elif [ -n "${SOURCE_URL:-}" ]; then
      urls=($SOURCE_URL)
    fi
  fi

  if [ "${#urls[@]}" -eq 0 ] && [ -n "${SOURCE_URL_FULL:-}" ]; then
    urls+=("$SOURCE_URL_FULL")
  fi

  if declare -p SOURCE2_URL >/dev/null 2>&1; then
    declared="$(declare -p SOURCE2_URL 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      urls+=("${SOURCE2_URL[@]}")
    elif [ -n "${SOURCE2_URL:-}" ]; then
      urls+=($SOURCE2_URL)
    fi
  fi

  if [ "${#urls[@]}" -gt 0 ]; then
    printf '%s\n' "${urls[@]}"
  fi
}

module_source_entries()
{
  local module="$1"
  local declared
  local -a source_names=()
  local -a source_urls=()
  local -a source2_names=()
  local -a source2_urls=()
  local idx

  load_module_metadata "$module"

  if declare -p SOURCE >/dev/null 2>&1; then
    declared="$(declare -p SOURCE 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      source_names=("${SOURCE[@]}")
    elif [ -n "${SOURCE:-}" ]; then
      source_names=($SOURCE)
    fi
  fi

  if declare -p SOURCE_URL >/dev/null 2>&1; then
    declared="$(declare -p SOURCE_URL 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      source_urls=("${SOURCE_URL[@]}")
    elif [ -n "${SOURCE_URL:-}" ]; then
      source_urls=($SOURCE_URL)
    fi
  fi

  if [ "${#source_names[@]}" -eq 0 ] && [ -n "${SOURCE_URL_FULL:-}" ]; then
    printf '%s\t%s\n' "${SOURCE_URL_FULL##*/}" "$SOURCE_URL_FULL"
  else
    for idx in "${!source_names[@]}"; do
      if [ "${#source_urls[@]}" -eq "${#source_names[@]}" ] && [ "${#source_urls[@]}" -gt 0 ]; then
        printf '%s\t%s\n' "${source_names[$idx]}" "${source_urls[$idx]}"
      elif [ "${#source_urls[@]}" -gt 0 ]; then
        printf '%s\t%s\n' "${source_names[$idx]}" "${source_urls[0]}"
      elif [ -n "${SOURCE_URL_FULL:-}" ] && [ "${#source_names[@]}" -eq 1 ]; then
        printf '%s\t%s\n' "${source_names[$idx]}" "$SOURCE_URL_FULL"
      else
        printf '%s\t%s\n' "${source_names[$idx]}" ""
      fi
    done
  fi

  if declare -p SOURCE2 >/dev/null 2>&1; then
    declared="$(declare -p SOURCE2 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      source2_names=("${SOURCE2[@]}")
    elif [ -n "${SOURCE2:-}" ]; then
      source2_names=($SOURCE2)
    fi
  fi

  if declare -p SOURCE2_URL >/dev/null 2>&1; then
    declared="$(declare -p SOURCE2_URL 2>/dev/null)"
    if [[ "$declared" == declare\ -a* ]]; then
      source2_urls=("${SOURCE2_URL[@]}")
    elif [ -n "${SOURCE2_URL:-}" ]; then
      source2_urls=($SOURCE2_URL)
    fi
  fi

  for idx in "${!source2_names[@]}"; do
    if [ "${#source2_urls[@]}" -eq "${#source2_names[@]}" ] && [ "${#source2_urls[@]}" -gt 0 ]; then
      printf '%s\t%s\n' "${source2_names[$idx]}" "${source2_urls[$idx]}"
    elif [ "${#source2_urls[@]}" -gt 0 ]; then
      printf '%s\t%s\n' "${source2_names[$idx]}" "${source2_urls[0]}"
    else
      printf '%s\t%s\n' "${source2_names[$idx]}" ""
    fi
  done
}

module_has_payload_sources()
{
  local module="$1"

  load_module_metadata "$module"
  if declare -p SOURCE >/dev/null 2>&1 || [ -n "${SOURCE_URL_FULL:-}" ] || declare -p SOURCE2 >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

extract_archive()
{
  local archive="$1"
  local dest="$2"

  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" ;;
    *.tar.bz2|*.tbz|*.tbz2) tar -xjf "$archive" -C "$dest" ;;
    *.tar.xz|*.txz) tar -xJf "$archive" -C "$dest" ;;
    *.tar.lz|*.tar.lzma) tar --lzma -xf "$archive" -C "$dest" ;;
    *.tar) tar -xf "$archive" -C "$dest" ;;
    *.zip) unzip -q "$archive" -d "$dest" ;;
    *) return 1 ;;
  esac
}

module_primary_source()
{
  local module="$1"
  local source

  source="$(module_sources "$module" | head -n 1)"
  [ -n "$source" ] || return 1
  printf '%s\n' "$ISO_SOURCE/spool/$source"
}

target_arch_from_triplet()
{
  case "${1%%-*}" in
    x86_64) echo x86_64 ;;
    i?86) echo i686 ;;
    aarch64|arm64) echo aarch64 ;;
    arm*) echo arm ;;
    *) echo "${1%%-*}" ;;
  esac
}

linux_arch_from_triplet()
{
  case "${1%%-*}" in
    x86_64|i?86) echo x86 ;;
    aarch64|arm64) echo arm64 ;;
    arm*) echo arm ;;
    *) echo "${1%%-*}" ;;
  esac
}

bootstrap_resolve_modules()
{
  local seeds=("$@")
  local module
  local -A seen=()
  local -a ordered=()

  _bootstrap_dfs()
  {
    local mod="$1"
    local dep

    [ -n "$mod" ] || return 0
    if bootstrap_ignore_module "$mod"; then
      return 0
    fi
    if [ "${seen[$mod]:-0}" -eq 1 ]; then
      return 0
    fi
    seen[$mod]=1
    if module_exists "$mod"; then
      while read -r dep; do
        [ -n "$dep" ] || continue
        _bootstrap_dfs "$dep"
      done < <(module_dependencies "$mod")
    fi
    ordered+=("$mod")
  }

  for module in "${seeds[@]}"; do
    _bootstrap_dfs "$module"
  done

  if [ "${#ordered[@]}" -gt 0 ]; then
    printf '%s\n' "${ordered[@]}" | awk 'NF && !seen[$0]++'
  fi
}

bootstrap_write_package_entry()
{
  local module="$1"
  local version="${2:-unknown}"
  local status_dir="$ISO_TARGET/var/state/lunar"

  mkdir -p "$status_dir"
  touch "$status_dir/packages" "$status_dir/packages.backup"
  if ! grep -q "^$module:" "$status_dir/packages" 2>/dev/null; then
    printf '%s:%s:installed:%s:0KB\n' "$module" "$(date +%Y%m%d)" "$version" >> "$status_dir/packages"
    cp "$status_dir/packages" "$status_dir/packages.backup"
  fi
}

bootstrap_tool()
{
  local tool="$1"
  local target="${BOOTSTRAP_TARGET:-$(bootstrap_default_target)}"

  if [ -x "$BOOTSTRAP_PREFIX/bin/$target-$tool" ]; then
    printf '%s\n' "$BOOTSTRAP_PREFIX/bin/$target-$tool"
  elif [ -x "$BOOTSTRAP_PREFIX/bin/$tool" ]; then
    printf '%s\n' "$BOOTSTRAP_PREFIX/bin/$tool"
  else
    command -v "$target-$tool" 2>/dev/null || command -v "$tool"
  fi
}

bootstrap_env_exports()
{
  cat <<EOF
export BOOTSTRAP_PREFIX=$BOOTSTRAP_PREFIX
export PATH=$BOOTSTRAP_PREFIX/bin:\$PATH
export PKG_CONFIG_PATH=$BOOTSTRAP_PREFIX/lib/pkgconfig:$BOOTSTRAP_PREFIX/lib64/pkgconfig:\${PKG_CONFIG_PATH:-}
export PKG_CONFIG_LIBDIR=$BOOTSTRAP_PREFIX/lib/pkgconfig:$BOOTSTRAP_PREFIX/lib64/pkgconfig
export CC="${BOOTSTRAP_TARGET:-$(bootstrap_default_target)}-gcc --sysroot=$ISO_TARGET"
export CXX="${BOOTSTRAP_TARGET:-$(bootstrap_default_target)}-g++ --sysroot=$ISO_TARGET"
export AR="$(bootstrap_tool ar)"
export AS="$(bootstrap_tool as)"
export LD="$(bootstrap_tool ld)"
export RANLIB="$(bootstrap_tool ranlib)"
export STRIP="$(bootstrap_tool strip)"
export NM="$(bootstrap_tool nm)"
export OBJCOPY="$(bootstrap_tool objcopy)"
export OBJDUMP="$(bootstrap_tool objdump)"
export READELF="$(bootstrap_tool readelf)"
export DEFAULT_PREFIX=/usr
export DOCUMENT_DIRECTORY=/usr/share/doc
export BUILD_DIRECTORY=/usr/src
export ENABLE_LARGEFILE="${ENABLE_LARGEFILE:-n}"
export BIGFILES="${BIGFILES:-}"
export CFLAGS="-O2"
export CXXFLAGS="-O2"
export LDFLAGS=""
export DESTDIR=$ISO_TARGET
export INSTALL_ROOT=$ISO_TARGET
EOF
}
