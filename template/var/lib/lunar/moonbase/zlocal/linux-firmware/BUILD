_DESTDIR=$SOURCE_DIRECTORY/__destdir

# Detect merged /usr - if /lib is a symlink, firmware goes to /usr/lib
if [ -L /lib ]; then
  FIRMWAREDIR=/usr/lib/firmware
else
  FIRMWAREDIR=/lib/firmware
fi

install -d ${_DESTDIR}${FIRMWAREDIR} &&
./copy-firmware.sh --zstd --ignore-duplicates ${_DESTDIR}${FIRMWAREDIR} &&

if [[ "$FW_NFP" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR/netronome" &&
  rm -f "$SOURCE_DIRECTORY/LICENSE.Netronome"
fi &&

if [[ "$FW_MELLANOX" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR/mellanox"
fi &&

if [[ "$FW_MARVELL" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR"/{libertas,mwl8k,mwlwifi,mrvl} &&
  rm -f "$SOURCE_DIRECTORY"/LICENSE.{Marvell,NXP}
fi &&

if [[ "$FW_QCOM" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR"/{qcom,a300_*} &&
  rm -f "$SOURCE_DIRECTORY"/LICENSE.qcom
fi &&

if [[ "$FW_LIQUIDIO" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR/liquidio" &&
  rm -f "$SOURCE_DIRECTORY"/LICENSE.cavium_liquidio
fi &&

if [[ "$FW_QLOGIC" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR"/{qlogic,qed,ql2???_*,c{b,t,t2}fw-*} &&
  rm -f "$SOURCE_DIRECTORY"/LICENSE.{qla1280,qla2xxx}
fi &&

if [[ "$FW_BNX2X" != "y" ]]; then
  rm -rf "$_DESTDIR$FIRMWAREDIR"/bnx2x*
fi &&

prepare_install &&

cp -rf $_DESTDIR/* / &&

gather_docs GPL* LICEN* WHENCE
