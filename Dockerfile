FROM openresty/openresty:alpine-fat

RUN apk add --no-cache git
ARG luarocks=/usr/local/openresty/luajit/bin/luarocks

# Lua HTTP request helper
# See: https://github.com/tokers/lua-resty-requests
RUN $luarocks install lua-resty-requests

# Lua request data parser
# See: https://github.com/bungle/lua-resty-reqargs
RUN $luarocks install lua-resty-reqargs
