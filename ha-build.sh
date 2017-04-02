#/bin/bash
make -C /usr/src/haproxy \
  TARGET=linux2628 \
  USE_PCRE=1 PCREDIR= \
  USE_OPENSSL=1 \
  USE_ZLIB=1 \
  USE_LUA=1 \
  LUA_INC=/usr/include/lua5.3 \
  CFLAGS="$(dpkg-buildflags --get CFLAGS) $(dpkg-buildflags --get CPPFLAGS)" \
  LDFLAGS="$(dpkg-buildflags --get LDFLAGS)" \
  all \
  install-bin
  
#  LUA_LIB_NAME=liblua5.2 \
  
  