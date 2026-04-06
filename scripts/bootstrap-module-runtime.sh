#!/bin/bash

set -euo pipefail

: "${INSTALL_ROOT:?INSTALL_ROOT is required}"
: "${MODULE_DIR:?MODULE_DIR is required}"
: "${MODULE:?MODULE is required}"
: "${BOOTSTRAP_BUILD_ROOT:?BOOTSTRAP_BUILD_ROOT is required}"

message()
{
  echo "[$MODULE] $*"
}

sedit()
{
  local expr="$1"
  shift
  sed -i "$expr" "$@"
}

patch_it()
{
  patch -p1 "$@"
}

query()
{
  return 1
}

yes_no()
{
  return 1
}

persistent_add()
{
  :
}

persistent_remove()
{
  :
}

prepare_install()
{
  :
}

list_remove()
{
  local needle="$1"
  shift
  local item

  for item in "$@"; do
    [ "$item" = "$needle" ] || printf '%s\n' "$item"
  done
}

mk_source_dir()
{
  local dir="$1"
  mkdir -p "$BOOTSTRAP_BUILD_ROOT/$dir"
}

default_pre_build()
{
  :
}

run_make()
{
  if [ -n "${BOOTSTRAP_JOBS:-}" ]; then
    make -j "$BOOTSTRAP_JOBS" "$@"
  else
    make "$@"
  fi
}

default_build()
{
  if [ -x ./configure ]; then
    ./configure --prefix=/usr
    run_make
  elif [ -f meson.build ]; then
    meson setup build --prefix=/usr
    ninja -C build
  elif [ -f Makefile ] || [ -f makefile ] || [ -f GNUmakefile ]; then
    run_make
  fi
}

default_install()
{
  if [ -d build ] && [ -f meson.build ]; then
    DESTDIR="$INSTALL_ROOT" ninja -C build install
  elif [ -f Makefile ] || [ -f makefile ] || [ -f GNUmakefile ]; then
    make DESTDIR="$INSTALL_ROOT" install
  fi
}
