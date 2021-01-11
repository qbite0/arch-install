#!/bin/bash

. ./config.ini # Загрузка конфига

echo "Создание начального загрузочного диска системы..."
mkinitcpio -p linux>>./$logfile

echo "Установка часового пояса..."
timedatectl set-timezone $region

echo "Синхронизация времени..."
hwclock --systohc

echo "Настройка local.gen файла..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/; s/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen

echo "Запуск local-gen..."
locale-gen>>./$logfile
echo "Установка системного языка..."
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
export LANG=ru_RU.UTF-8

echo "Добавление русской раскладки..."
echo "KEYMAP=ru">/etc/vconsole.conf
echo "Установка шрифта cyr-sun16 (для отображения русской раскладки)..."
echo "FONT=cyr-sun16">>/etc/vconsole.conf

echo "Установка названия компьютера..."
echo $hostname > /etc/hostname

echo "Настройка hosts файла..."
echo "127.0.0.1 localhost">>/etc/hosts
echo "::1 localhost">>/etc/hosts
echo "127.0.1.1 "$hostname>>/etc/hosts

echo "Включение NetworkManager'a..."
systemctl enable NetworkManager>>./$logfile

echo "Смена пароля у root..."
echo "root:"$rootpassword | chpasswd

echo "Создание пользователя "$user"..."
useradd -m -g users -G wheel -s /bin/bash $user
echo "Смена пароля у "$user"..."
echo $user":"$userpassword | chpasswd

echo "Настройка sudo (/etc/sudoers файла)..."
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo "Установка grub и efibootmanager..."
yes | pacman -S grub efibootmgr>>./$logfile

mkdir /boot/efi

echo "Монтирование efi boot раздела"
mount $installdisk"1" /boot/efi

echo "Установка grub..."
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi>>./$logfile
echo "Создание конфигурации grub..."
grub-mkconfig -o /boot/grub/grub.cfg>>./$logfile
