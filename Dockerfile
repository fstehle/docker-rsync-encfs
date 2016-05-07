FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y encfs rsync && \
  rm -rf /var/lib/apt/lists/*

ADD ./docker-run.sh /usr/local/bin/docker-run

EXPOSE 873
VOLUME /data

CMD ["/usr/local/bin/docker-run"]
