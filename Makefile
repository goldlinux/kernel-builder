include Makefile.inc

.PHONY: all clean distclean prep modules deb patch unpatch sgm-dahdi firmware test

test: kernel/linux-image-$(KVERS)-$(VERS)_$(KVERS)-$(VERS)_amd64.deb
	# If this fails, the kernel did not build Dahdi or our USB device
	@dpkg-deb --contents $<  | grep ua32xx.ko && echo ua32xx.ko found
	@dpkg-deb --contents $< | grep dahdi.ko && echo dahdi.ko found

clean:
	[ -d $(DIR)/kernel ] && cd $(DIR)/kernel && rm -rf * || :

distclean: clean
	rm -rf $(DEST) $(FDEST) src/dahdi-linux

firmware: $(FORIG)
	mkdir -p $(FDEST) && \
		tar -C $(FDEST) --strip-components=1 -xf $(FORIG)

.dockerimg: $(wildcard docker/*)
	docker build -t kernbuild docker && touch .dockerimg

prep: .dockerimg /usr/bin/ccache $(DEST)/.config patch
	@if ! grep -q DAHDI $(DEST)/.config; then echo ".config has no DAHDI lines"; exit 1; fi

/usr/bin/ccache:
	apt-get -y install ccache

/usr/bin/gcc:
	apt-get -y install build-essential flex bison libelf-dev libssl-dev



modules:
	cd $(DEST) && make -j$(shell nproc) CC="ccache gcc" $@

kernel/linux-image-$(KVERS)-$(VERS)_$(KVERS)-$(VERS)_amd64.deb: prep
	cd $(DEST) && make -j$(shell nproc) CC="ccache gcc" LOCALVERSION="-$(VERS)" KDEB_PKGVERSION="$(KVERS)-$(VERS)" EMAIL="Rob Thomas <xrobau@gmail.com>" deb-pkg

$(DEST)/.config: $(DEST)/Makefile sgm-dahdi $(DEST)/arch/x86/configs/gold_defconfig patch
	cd $(DEST) && make gold_defconfig
	touch $(DEST)/.config

$(DEST)/arch/x86/configs/gold_defconfig: gold_defconfig
	cp -p $(@F) $@

$(DEST)/Makefile: $(ORIG)
	mkdir -p $(DEST) && \
	tar -C $(DEST) --strip-components=1 -xf $(ORIG) && \
	touch $@

patch: $(DEST)/.patched

$(DEST)/.patched:
	@cd $(DEST); \
	for x in $(wildcard $(DIR)/patches/*.patch); do \
		echo Applying patch $$(basename $$x); \
		patch -p0 < $$x; \
	done; \
	for x in $(wildcard $(DIR)/patches/*.sh); do \
		echo Running patch script $$(basename $$x); \
		$$x -i; \
	done
	@touch $@

unpatch:
	@[ -d $(DEST) ] && cd $(DEST) && \
	for x in $(wildcard $(DIR)/patches/*.patch); do \
		echo Removing patch $$(basename $$x); \
		patch -R -N -r/dev/null -p0 < $$x || :; \
	done && \
	for x in $(wildcard $(DIR)/patches/*.sh); do \
		echo Running patch uninstall $$(basename $$x); \
		$$x -u; \
	done && \
	rm -f .patched || :

src/linux-%.xz:
	@mkdir -p src
	@wget https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F) -O $@

src/linux-firmware-%.tar.gz:
	@mkdir -p src
	wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/$(@F) -O $@

sgm-dahdi: src/dahdi-linux $(DEST)/drivers/dahdi src/dahdi-linux/include/dahdi/version.h $(DEST)/include/dahdi $(DEST)/include/uapi/dahdi dmpatched

dmpatched: $(DEST)/drivers/.Makefile_patched

$(DEST)/drivers/.Makefile_patched:
	@sed -i -e '/linux\/dahdi/d' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/dahdi_config.h:CONFIG_HDLC' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/dahdi_config.h:CONFIG_HDLC_MODULE' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/dahdi_config.h:CONFIG_PPP' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/dahdi_config.h:CONFIG_PPP_MODULE' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/dahdi_config.h:CONFIG_DAHDI_CORE_TIMER' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_DAHDI_NET' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_DAHDI_PPP' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_DAHDI_ECHOCAN_PROCESS_TX' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_DAHDI_MIRROR' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_CALC_XLAW' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_DAHDI_WATCHDOG' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/kernel.h:CONFIG_PROC_FS' \
		-e '/^config_leak_ignores=/a include/uapi/dahdi/user.h:CONFIG_DAHDI_MIRROR' \
		$(DEST)/scripts/headers_install.sh && \
	sed -i -e '/dahdi/d' -e '/endmenu/i source "drivers/dahdi/Kconfig"' $(DEST)/drivers/Kconfig && \
	sed -i -e '/dahdi/d' $(DEST)/drivers/Makefile && \
	echo 'obj-$$(CONFIG_DAHDI)  += dahdi/' >> $(DEST)/drivers/Makefile && \
	touch $@

src/dahdi-linux:
	cd src && git clone -b sgm https://github.com/goldlinux/dahdi-linux.git

src/dahdi-linux/include/dahdi/version.h:
	cd src/dahdi-linux && make include/dahdi/version.h

$(DEST)/drivers/dahdi:
	rsync -av --delete  $(shell pwd)/src/dahdi-linux/drivers/dahdi/ $@

$(DEST)/include/dahdi $(DEST)/include/uapi/dahdi:
	mkdir -p $@ && cp $(shell pwd)/src/dahdi-linux/include/dahdi/*.h $@
 

