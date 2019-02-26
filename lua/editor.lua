-- Wrapper for exit on internal server error
function exit (message)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.print(message)
    ngx.exit(ngx.HTTP_OK)
end

-- Package version to be checked
local PACKAGE_NAME = ngx.var.request_uri
if PACKAGE_NAME == '/' then
    exit('Package name is missing')
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
    exit('Cannot connect to database')
    return
end

-- Define key and ttl
local LATEST_VERSION_KEY = PACKAGE_NAME .. ":latest"
local TTL = 3600 * 24 -- Data time to live one day

-- Check if we have stored package's version
version, err = red:get(LATEST_VERSION_KEY)

-- If Key does not exist then make a request and save the latest version
if version == ngx.null then
    local requests = require "resty.requests"
    local json = require "cjson"

    -- Request URL
    local url = "https://registry.npmjs.org/-/package/" .. PACKAGE_NAME .. "/dist-tags"

    -- HTTP request
    local r, err = requests.get(url, {allow_redirects = true})
    if not r then
        exit('The latest version checking from npm was failed')
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
    ok, err = red:set(LATEST_VERSION_KEY, version, 'EX', TTL)
    if not ok then
        exit('Cannot save key to database')
        return
    end
end

-- Return latest version to user
ngx.say(version)
