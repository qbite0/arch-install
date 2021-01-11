#!/bin/bash

curl -sL "raw.githubusercontent.com/qbite0/arch-installd/main/config.ini" -o config.ini

. ./config.ini # Загрузка конфига

loadkeys ru # Русская раскладка
setfont cyr-sun16 # Загрузка шрифта с поддержкой русского

memory=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f 2) # Получаем кол-во оперативной памяти в системе

echo "Создание таблицы разметки ("$disktable")"
parted $installdisk mktable $disktable>>./$logfile

echo "Создание EFI раздела ("$installdisk"1)..."
parted $installdisk mkpart "EFI" fat32 "1MiB" $bootsize"MiB">>./$logfile
echo "Создание swap раздела ("$installdisk"2)..."
parted $installdisk mkpart "Swap" linux-swap $bootsize"MiB" $(($bootsize+$memory))"MiB">>./$logfile
echo "Создание системного раздела ("$installdisk"3)..."
parted $installdisk mkpart "Root" ext4 $(($bootsize+$memory))"MiB" $(($bootsize+$memory+($rootsize*1024)))"MiB">>./$logfile
echo "Создание домашнего раздела ("$installdisk"4)..."
parted $installdisk mkpart "Home" ext4 $(($bootsize+$memory+($rootsize*1024)))"MiB" 100%>>./$logfile

echo "Установка флага загрузочного раздела ("$installdisk"1)..."
parted $installdisk set 1 esp on>>./$logfile

echo "Форматирование загрузочного раздела ("$installdisk"1) в fat32..."
mkfs.fat -F32 $installdisk"1">>./$logfile
echo "Форматирование swap раздела ("$installdisk"2) в linux-swap..."
mkswap  $installdisk"2">>./$logfile
echo "Форматирование системного раздела ("$installdisk"3) в ext4..."
mkfs.ext4 $installdisk"3">>./$logfile
echo "Форматирование домашнего раздела ("$installdisk"4) в ext4..."
mkfs.ext4 $installdisk"4">>./$logfile

echo "Монтирование swap раздела ("$installdisk"2)..."
swapon $installdisk"2"
echo "Монтирование системного раздела ("$installdisk"3) в /mnt..."
mount $installdisk"3" /mnt

mkdir /mnt/home # Папка home раздела

echo "Монтирование домашнего раздела ("$installdisk"4) в /mnt/home..."
mount $installdisk"4" /mnt/home

echo "Поиск зеркал..."
reflector -l 20 -p https --sort rate --save /etc/pacman.d/mirrorlist

echo "Установка системы и её основных пакетов ("$packages")..."
pacstrap /mnt $packages>>./$logfile

echo "Создание файла информации о файловых системах (/etc/fstab)..."
genfstab -U /mnt >> /mnt/etc/fstab

mv $logfile /mnt/$logfile
mv config.ini /mnt/config.ini

curl -sL "raw.githubusercontent.com/qbite0/arch-installd/main/chroot.sh" -o /mnt/chroot.sh

chmod +x /mnt/chroot.sh
arch-chroot /mnt ./chroot.sh
