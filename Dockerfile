################################################################################
# Builder image
################################################################################
FROM centos:7.7.1908 as kreon-ardb-builder

# Install dependencies
RUN yum groupinstall -y "Development Tools" && \
    yum install -y epel-release centos-release-scl && \
    yum install -y cmake3 devtoolset-7-gcc devtoolset-7-gcc-c++ numactl-devel boost-devel wget which && \
    yum clean all \
    && rm -rf /var/cache/yum \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

WORKDIR /root
COPY . kreon-ardb

# Copy in Kreon, build
RUN git clone https://github.com/yinqiwen/ardb && \
    # FIXME: Download open source and build as "Release"...
    (cd ardb/deps && git clone https://github.com/CARV-ICS-FORTH/kreon.git ) && \
    # (mv kreon-ardb/kreon ardb/deps/) && \
    mkdir ardb/deps/kreon/build && \
    (cd ardb/deps/kreon/build && scl enable devtoolset-7 -- /bin/bash -c "cmake3 .. && make")

# Patch and build Ardb
RUN cp -r /root/kreon-ardb/src /root/ardb
RUN  cd /root/ardb && storage_engine=kreon make server

RUN strip ardb/src/ardb-server
RUN strip ardb/deps/kreon/build/kreon_lib/mkfs.kreon

################################################################################
# Kreon-Ardb distribution
################################################################################
FROM centos:7.7.1908 as kreon-ardb

# Install dependencies
RUN yum install -y numactl && \
    yum clean all \
    && rm -rf /var/cache/yum \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY --from=kreon-ardb-builder /root/ardb/ardb.conf /etc
COPY --from=kreon-ardb-builder /root/ardb/src/ardb-server /usr/bin
COPY --from=kreon-ardb-builder /root/ardb/deps/kreon/build/kreon_lib/mkfs.kreon /usr/local/bin
COPY --from=kreon-ardb-builder /root/ardb/deps/kreon/build/tests/mkfs.kreon.single.sh /usr/bin

RUN sed -ri 's|^home(\s)+..|home /var/ardb|' /etc/ardb.conf && \
    sed -i 's|16379|6379|' /etc/ardb.conf && \
    mkdir -p /var/ardb/data

EXPOSE 6379

WORKDIR /
COPY start.sh /

ENTRYPOINT ["./start.sh"]
