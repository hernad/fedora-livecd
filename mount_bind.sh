[ -d /var/cache/live ] || sudo mkdir /var/cache/live
[ -d /var/tmp ] || sudo mkdir /var/tmp


if ! findmnt -l /var/cache/live ; then
    echo mount bind /var/cache/live
    sudo mount --bind /mnt/var_cache_live /var/cache/live
else
    echo mount /mnt/var_cache_live exists
fi


if ! findmnt -l /var/tmp ; then
    echo mount bind /var/tmp
    sudo mount --bind /mnt/var_tmp /var/tmp
else
    echo mount /mnt/var_tmp exists
fi
