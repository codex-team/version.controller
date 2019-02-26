FROM openresty/openresty:alpine-fat

RUN apk add --no-cache git
ARG luarocks=/usr/local/openresty/luajit/bin/luarocks

# Lua HTTP request helper
# https://github.com/tokers/lua-resty-requests
RUN $luarocks install lua-resty-requests
