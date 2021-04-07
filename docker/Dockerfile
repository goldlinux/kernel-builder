ARG ARCH=
FROM ${ARCH}debian:buster
LABEL authors="Rob Thomas <xrobau@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
RUN echo "dash dash/sh boolean false" | debconf-set-selections &&  dpkg-reconfigure dash

RUN echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommends

RUN apt-get update && apt-get install -y dialog apt-utils locales

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y \
      vim vim-autopep8 nano git curl sudo mc \
      build-essential pbuilder devscripts squashfs-tools \
      genisoimage lsb-release fakechroot libtool libapt-pkg-dev \
      quilt python3-lxml python3-setuptools python3-nose \
      python3-coverage python3-sphinx python3-pystache python3-git \
      python3-pip python3-psutil python3-flake8 python3-autopep8 \
      flake8 pkg-config debhelper gosu po4a openssh-client jq unzip \
      syslinux grub2 figlet toilet

# Install open-vmdk
#RUN wget -O /tmp/open-vmdk-master.zip https://github.com/vmware/open-vmdk/archive/master.zip && \
#    unzip -d /tmp/ /tmp/open-vmdk-master.zip && \
#    cd /tmp/open-vmdk-master/ && \
#    make && \
#    make install

#
# live-build: building with local packages fails due to missing keys
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=941691
# https://salsa.debian.org/live-team/live-build/merge_requests/30
#
RUN wget https://salsa.debian.org/jestabro-guest/live-build/commit/63425b3e4f7ad3712ced4c9a3584ef9851c0355a.patch \
      -O /usr/local/63425b3e4f7ad3712ced4c9a3584ef9851c0355a.patch

RUN git clone https://salsa.debian.org/live-team/live-build.git /usr/local/live-build && \
    cd /usr/local/live-build && git checkout debian/1%20190311 && \
    patch -p1 < /usr/local/63425b3e4f7ad3712ced4c9a3584ef9851c0355a.patch && \
    dch -n "Applying fix for missing archive keys" && \
    dpkg-buildpackage -us -uc && \
    sudo dpkg -i ../live-build*.deb

#
# live-build: building in docker fails with mounting /proc | /sys
#
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=919659
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=921815
# https://salsa.debian.org/installer-team/debootstrap/merge_requests/26
#
RUN wget https://salsa.debian.org/klausenbusk-guest/debootstrap/commit/a9a603b17cadbf52cb98cde0843dc9f23a08b0da.patch \
      -O /usr/local/a9a603b17cadbf52cb98cde0843dc9f23a08b0da.patch && \
    git clone https://salsa.debian.org/installer-team/debootstrap /usr/local/debootstrap && \
    cd /usr/local/debootstrap && git checkout 1.0.114 && \
    patch -p1 < /usr/local/a9a603b17cadbf52cb98cde0843dc9f23a08b0da.patch && \
    dch -n "Applying fix for docker image compile" && \
    dpkg-buildpackage -us -uc && \
    sudo dpkg -i ../debootstrap*.deb

RUN apt-get update && apt-get install -y \
      autotools-dev libglib2.0-dev libboost-filesystem-dev libperl-dev \
      autoconf automake cpio rsync libmnl-dev libncurses5-dev flex bison \
      libelf-dev bc kmod dkms cdbs cmake elfutils libdw-dev systemtap-sdt-dev \
      libunwind-dev libslang2-dev python-dev libiberty-dev binutils-dev \
      libnuma-dev libbabeltrace-dev liblua5.3-dev libjson-c-dev libnl-3-dev \
      libnl-genl-3-dev libpopt-dev libsnmp-dev libssl-dev libnl-nf-3-dev \
      libnfnetlink-dev libipset-dev iptables-dev linux-libc-dev kpartx \
      parted udev grub-pc grub2-common

# fpm: a command-line program designed to help you build packages (e.g. deb)
RUN apt-get update && apt-get install -y \
      ruby ruby-dev rubygems; \
      gem install --no-document fpm

#
# Install Packer
#
RUN if dpkg-architecture -ii386 || dpkg-architecture -iamd64; then \
      export LATEST="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer | \
      jq -r -M '.current_version')"; \
      echo "url https://releases.hashicorp.com/packer/${LATEST}/packer_${LATEST}_linux_amd64.zip" |\
        curl -K- | gzip -d > /usr/bin/packer && \
      chmod +x /usr/bin/packer; \
    fi

# Allow password-less 'sudo' for all users in group 'sudo'
RUN sed "s/^%sudo.*/%sudo\tALL=(ALL) NOPASSWD:ALL/g" -i /etc/sudoers && \
    chmod a+s /usr/sbin/useradd /usr/sbin/groupadd /usr/sbin/gosu /usr/sbin/usermod

RUN apt-get -y --no-install-recommends install zip librsvg2-bin uuid-dev iasl nasm php-cli

# Cleanup
RUN rm -rf /tmp/*

# Disable mouse in vim
COPY vimrc.local /etc/vim/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
