FROM ubuntu:jammy
ENV ASTERISK_VER 18

#update & install required
RUN apt-get update && apt-get upgrade && apt-get install -y wget tar net-tools iputils-ping nano patch

WORKDIR /usr/local/src
#download sources
RUN wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$ASTERISK_VER-current.tar.gz && \
    tar -zxf asterisk-$ASTERISK_VER-current.tar.gz && \
    rm asterisk-$ASTERISK_VER-current.tar.gz

RUN ls asterisk-$ASTERISK_VER.* > asteriskVersion.txt && \
    mv asterisk-$ASTERISK_VER.* asterisk


ENV DEBIAN_FRONTEND noninteractive

WORKDIR /usr/local/src/asterisk

#install required to compile
RUN ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    #DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
    #dpkg-reconfigure --frontend noninteractive tzdata && \
    contrib/scripts/install_prereq install

##OK FINO A QUA, niente di interattivo. Controlla timezone e

RUN ./configure

RUN make menuselect.makeopts && \
    menuselect/menuselect --enable chan_sip

#apply patch for Tiscali to work
COPY tiscalisip.patch tiscalisip.patch
RUN patch -b channels/sip/reqresp_parser.c -i tiscalisip.patch

#build
RUN make && \
    make install && \
    make basic-pbx && \
    make config

#ims.tiscali.net not resolved by DNS: add to hosts file
#RUN echo "94.32.130.112 ims.tiscali.net" >> /etc/hosts

#clean
RUN make distclean
RUN rm -r /var/lib/apt/lists/*

#start Asterisk
CMD /etc/init.d/asterisk start
