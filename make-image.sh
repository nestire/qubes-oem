#!/usr/bin/env bash

command -v wget >/dev/null 2>&1 || { echo >&2 "Please install 'wget' first.  Aborting."; exit 1; }


set -xe

if [ "$1" = "de" ]; then
	./make-ks.sh de
	cp ks-de.cfg ks.cfg
    echo "Build DE"
elif [ "$1" = "en" ]; then
	./make-ks.sh en
	cp ks-en.cfg ks.cfg
    echo "Build EN"
else
    echo "Usage: ./make-image.sh en\|de"
    exit
fi
QUBES_RELEASE="R4.2.0"
RELEASE_ISO_FILENAME="Qubes-${QUBES_RELEASE}-x86_64.iso"
CUSTOM_ISO_FILENAME="Qubes-${QUBES_RELEASE}-oem-x86_64-${1}.img"


if [ ! -f "${RELEASE_ISO_FILENAME}" ]; then
	wget -q "https://ftp.qubes-os.org/iso/${RELEASE_ISO_FILENAME}" -O unverified.iso
	wget -q "https://ftp.qubes-os.org/iso/${RELEASE_ISO_FILENAME}.asc"
	gpgv --keyring ./qubes-release-keyring.gpg "${RELEASE_ISO_FILENAME}.asc" unverified.iso
	mv unverified.iso "${RELEASE_ISO_FILENAME}"
fi


dd if=/dev/zero of=qubes_oem.img bs=1M count=500 
cat "${RELEASE_ISO_FILENAME}" qubes_oem.img > $CUSTOM_ISO_FILENAME
DEV_QUBES_IMG="$(sudo losetup -f -P --show $CUSTOM_ISO_FILENAME)"
#FIXME Start and End not acurate 
echo -e "n \n\n\n\n w "|sudo  fdisk ${DEV_QUBES_IMG}
sudo mkfs.ext4 ${DEV_QUBES_IMG}p4 
sudo tune2fs -L QUBES_OEM ${DEV_QUBES_IMG}p4

if [[ -d /tmp/mnt ]] ; then
	rm -rf /tmp/mnt
fi	

mkdir /tmp/mnt
sudo mount ${DEV_QUBES_IMG}p4 /tmp/mnt
sudo cp ks.cfg /tmp/mnt
sudo cp -r nitrokey /tmp/mnt
sudo umount /tmp/mnt
sudo losetup -d ${DEV_QUBES_IMG}



