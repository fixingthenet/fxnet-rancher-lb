FROM ruby:2.3-slim

ENV HAPROXY_MAJOR 1.7
ENV HAPROXY_VERSION 1.7.3
ENV HAPROXY_MD5 fe529c240c08e4004c6e9dcf3fd6b3ab

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list

# see http://sources.debian.net/src/haproxy/1.5.8-1/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN set -x \
   && apt-get update -y \
   && apt-get install -y \
   build-essential \
   libssl-dev \
   zlib1g-dev \
   libpcre3-dev \
   liblua5.3-dev \
   curl \
   inotify-tools

RUN set -x \
  && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
  && echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
  && mkdir -p /usr/src \
  && tar -xzf haproxy.tar.gz -C /usr/src \
  && mv "/usr/src/haproxy-$HAPROXY_VERSION" /usr/src/haproxy \
  && rm haproxy.tar.gz

#see http://git.haproxy.org/?p=haproxy.git;a=blob_plain;f=Makefile;hb=HEAD
ADD ha-build.sh /ha-build.sh
RUN /ha-build.sh \
  && mkdir -p /usr/local/etc/haproxy \
  && cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
  && rm -rf /usr/src/haproxy

# Customisation from haproxy upstream
#RUN wget  http://rubygems.org/downloads/rubygems-update-2.6.7.gem
#RUN echo "gem: --no-ri --no-rdoc" > /root/.gemrc
#RUN gem install --local rubygems-update-2.6.7.gem
#RUN update_rubygems

RUN gem install bundler

WORKDIR /
ADD Gemfile $APP_DIR
ADD Gemfile.lock $APP_DIR
RUN bundle

# ---------------NO BUILD FROM HERE ----

RUN set -x \
   && apt-get update -y \
   && apt-get install -y \
      diffutils \
      joe \
      hatop


ENV STACK_DOMAIN none
ENV HAPROXY_CONFIG /usr/local/etc/haproxy/haproxy.cfg
ENV HAPROXY_BACKEND_CONFIG /usr/local/etc/haproxy/haproxy-backends.cfg
ENV HAPROXY_DOMAIN_MAP /usr/local/etc/haproxy/domain.map

ENV RANCHER_URL http://rancher-metadata.rancher.internal/2015-12-19
ENV RANCHER_LABEL net.fixingthe.lb_config
ENV RANCHER_TAG all


ADD haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
ADD ssl.crt /usr/local/etc/haproxy/ssl.crt

ENV APP_DIR /code
WORKDIR $APP_DIR
ADD Gemfile $APP_DIR
ADD Gemfile.lock $APP_DIR
RUN bundle
ADD . $APP_DIR

# see https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
# not using bash leads to zombie apocalypse!
# perhaps I should use tinit

CMD ["/bin/bash", "-c", "set -e && /code/bin/ragent_server"]
