#!/bin/bash

cd ..

touch .lunar-cd

mkisofs -o ../unnamed.iso -R \
        -V "unnamed" -v  \
        -d -D -N -no-emul-boot -boot-load-size 4 -boot-info-table \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -A "unnamed" .

rm -f .lunar.cd
