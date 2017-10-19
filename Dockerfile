FROM alpine:3.6

RUN apk add --no-cache bash \
						binutils \
						bison \
						bzip2 \
						coreutils \
						diffutils \
						findutils \
						gawk \
						gcc \
						grep \
						gzip \
						m4 \
						make \
						ld \
						openssl-dev \
						patch \
						perl \
						sed \
						tar \
						texinfo \
						wget \
						xz

WORKDIR /lfs/sources

RUN wget -O wget-list http://www.linuxfromscratch.org/lfs/view/stable/wget-list
RUN wget --input-file=wget-list; echo 0

RUN mkdir /lfs/tools
RUN ln -s /lfs/tools /

RUN tar xvf binutils-2.29.tar.bz2
WORKDIR binutils-2.29/build

RUN ../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

RUN make -j4
RUN make install
CMD ["/bin/bash"]
