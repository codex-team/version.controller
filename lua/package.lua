-- Wrapper for exit on internal server error
function exit (message, status)
    ngx.status = status
    ngx.say('{"error": "' .. message .. '"}')
    ngx.exit(ngx.HTTP_OK)
end

-- Drop all non-POST requests
local REQUEST_METHOD = ngx.var.request_method
if REQUEST_METHOD ~= 'POST' then
    exit('Method not allowed', ngx.HTTP_NOT_ALLOWED)
    return
end

-- Parse request data
local get, post, files = require "resty.reqargs"()

-- Package version to be checked
local PACKAGE_NAME = post['package']
if not PACKAGE_NAME then
    exit('Package name is missing', ngx.HTTP_BAD_REQUEST)
    return
end

-- Set up Redis connection
local REDIS_HOST = 'redis'
local REDIS_PORT = '6379'
local redis = require "resty.redis"
local red = redis:new()

-- Connection timeout 1 sec
red:set_timeout(1000)

-- Try to make a connection
local ok, err = red:connect(REDIS_HOST, REDIS_PORT)
if not ok then
    exit('Cannot connect to database', ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

-- Define key and ttl
local PACKAGE_VERSION_KEY = PACKAGE_NAME .. ":latest"
local TTL = 3600 * 24 -- Data time to live one day

-- Check if we have stored package's version
version, err = red:GET(PACKAGE_VERSION_KEY)

-- If Key does not exist then make a request and save the latest version
if version == ngx.null then
    local requests = require "resty.requests"
    local json = require "cjson"

    -- Request URL
    local url = "https://registry.npmjs.org/-/package/" .. PACKAGE_NAME .. "/dist-tags"

    -- HTTP request
    local r, err = requests.get(url, {allow_redirects = true})
    if not r then
        exit('The latest version checking from npm was failed', ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    -- Get response body and parse it
    local body = r:body()
    local decoded_body = json.decode(body)

    -- Get value for key 'latest'
    body = decoded_body['latest']

    -- Save result to global variable
    version = body

    -- Save result to database for some time
    ok, err = red:SET(PACKAGE_VERSION_KEY, version, 'EX', TTL)
    if not ok then
        exit('Cannot save key to database', ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
end

-- If client has send his package's version then hit counter
local CLIENT_PACKAGE_VERSION = post['version']
if CLIENT_PACKAGE_VERSION then
    -- Hit metrika counter by target version and client ip
    local ip = ngx.var.http_x_real_ip
    local CLIENTS_ID_KEY = PACKAGE_VERSION_KEY .. ':clients'

    ok, err = red:HINCRBY(CLIENTS_ID_KEY, ip, 1)
end

-- Return latest version to user
ngx.say('{"version": "' .. version .. '"}')
