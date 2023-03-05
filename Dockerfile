FROM ubuntu:jammy
ARG ASTERISK_VER=18
ARG DEBIAN_FRONTEND=noninteractive

#update & install required
RUN apt-get update && apt-get upgrade && apt-get install -y wget tar net-tools iputils-ping nano patch apt-utils

WORKDIR /usr/local/src

#download sources
RUN wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$ASTERISK_VER-current.tar.gz && \
    tar -zxf asterisk-$ASTERISK_VER-current.tar.gz && \
    rm asterisk-$ASTERISK_VER-current.tar.gz && \
    ls asterisk-$ASTERISK_VER.* > asteriskVersion.txt && \
    mv asterisk-$ASTERISK_VER.* asterisk

WORKDIR /usr/local/src/asterisk

#install required to compile
RUN ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    contrib/scripts/install_prereq install && \
    ./configure && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable chan_sip

#apply patch for Tiscali to work
COPY tiscalisip.patch tiscalisip.patch
RUN patch -b channels/sip/reqresp_parser.c -i tiscalisip.patch

#build
RUN make -j$(grep -c ^processor /proc/cpuinfo) && \
    make install && \
    make basic-pbx && \
    make config

#ims.tiscali.net not resolved by DNS: add to hosts file
#RUN echo "94.32.130.112 ims.tiscali.net" >> /etc/hosts

#clean
RUN make distclean && \
    rm -r /var/lib/apt/lists/* 
    #&& \
#    rm -r /usr/local/src/asterisk

#start Asterisk
CMD /etc/init.d/asterisk start
