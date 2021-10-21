KVERS=5.4.155
VERS=1
KFIRMWARE=20201218
ORIG=src/linux-$(KVERS).tar.xz
FORIG=src/linux-firmware-$(KFIRMWARE).tar.gz
#KERNELREV=$(KVERS)-$(VERS)
#DEST=linux-$(KVERS)-$(VERS)
DEST=kernel/linux-$(KVERS)
FDEST=kernel/linux-firmware-$(KFIRMWARE)
DIR=$(shell pwd)

export KERNELREV DEST DIR


