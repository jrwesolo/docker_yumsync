FROM centos:7.2.1511
MAINTAINER Jordan Wesolowski <jrwesolo@gmail.com>

# gosu install
ENV GOSU_VERSION 1.9
RUN curl -o /usr/local/bin/gosu -sSL https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64 && \
    curl -o /usr/local/bin/gosu.asc -sSL https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc && \
    gpg -q --keyserver pgp.mit.edu --recv-keys BF357DD4 && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

# EPEL required for python-pip
RUN yum install -y epel-release && \
    yum install -y createrepo python-pip PyYAML && \
    yum clean all

# used for yumsync backup and restore
RUN yum install -y pv && \
    yum clean all

ENV YUMSYNC_VERSION=0.4.0
RUN curl -sSL "https://github.com/jrwesolo/yumsync/archive/v${YUMSYNC_VERSION}.tar.gz" | \
    tar -C /usr/local/src -xz && \
    cd "/usr/local/src/yumsync-${YUMSYNC_VERSION}" && \
    python setup.py install && \
    rm -rf "/usr/local/src/yumsync-${YUMSYNC_VERSION}"

ENV YUMSYNC_CONF=/etc/yumsync \
    YUMSYNC_DATA=/data \
    YUMSYNC_USER=yumsync YUMSYNC_UID=489 \
    YUMSYNC_GROUP=yumsync YUMSYNC_GID=489

RUN groupadd -g $YUMSYNC_GID $YUMSYNC_GROUP && \
    useradd -s /bin/bash -d $YUMSYNC_CONF -M -N -u $YUMSYNC_UID -g $YUMSYNC_GROUP $YUMSYNC_USER && \
    mkdir -p $YUMSYNC_DATA $YUMSYNC_CONF && \
    chown $YUMSYNC_USER:$YUMSYNC_GROUP $YUMSYNC_DATA $YUMSYNC_CONF && \
    chmod 0755 $YUMSYNC_DATA $YUMSYNC_CONF

COPY docker /docker

VOLUME $YUMSYNC_DATA
ENTRYPOINT ["/docker/run"]
CMD []
