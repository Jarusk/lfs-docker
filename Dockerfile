FROM alpine:3.6

ARG jobs=4

RUN apk add --no-cache bash binutils bison bzip2 coreutils diffutils
RUN apk add --no-cache findutils gawk gcc grep gzip m4 make openssl libc-dev python-dev gcc
RUN apk add --no-cache openssl-dev patch perl sed tar texinfo wget xz

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

RUN make -j$jobs

RUN case $(uname -m) in \
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;\
esac

RUN make install
CMD ["/bin/bash"]
