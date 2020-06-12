FROM debian:latest

RUN apt-get update \
    && apt-get install -y \
    osc \
    curl \
    perl \
    libxml-libxml-perl \
    locales \
  && true

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

COPY tools/ /tools/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
