#!/bin/bash

cd ..

touch .lunar-cd

mkisofs -o ../lunar-linux.iso -R -J -l \
        -V '%LABEL%' -v \
        -d -D -N -no-emul-boot -boot-load-size 4 -boot-info-table \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -A 'Lunar-%VERSION%' .

rm -f .lunar.cd
