## This is a RC kernel and can't be considered stable. Please use non-RC releases if you don't specifically require features only available in this RC version.

A custom Linux kernel 5.3 rc with specific PDS CPU scheduler related patchset selector (stock CFS and CFS+TurboSched are also an option) and added tweaks for a nice interactivity/performance balance, aiming for the best gaming experience.

Various personalization options available and userpatches support (put your own patches in the same dir as the PKGBUILD, with the ".mypatch" extension.

TurboSched : https://lkml.org/lkml/2019/7/25/296

PDS-mq was originally created by Alfred Chen : http://cchalpha.blogspot.com/
While he dropped it with kernel 5.1 in favor of its BMQ evolution/rework, my pretty bad gaming experiences with BMQ up to this point convinced me to keep PDS afloat for as long as it'll make sense/I'll be able to.

Comes with a slightly modified Arch config asking for a few core personalization settings at compilation time.
If you want to streamline your kernel config for lower footprint and faster compilations : https://wiki.archlinux.org/index.php/Modprobed-db
You can enable support for it at the beginning of the PKGBUILD file. Make sure to read everything you need to know about it.