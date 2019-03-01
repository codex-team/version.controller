# Version controller

Check package's updates and track versions in use. 

## API

There is a simple one route API. CORS support is enabled.

### Request

Send a POST request to uri `/check`

| Field   | Example              | Description                               |
| ------- | -------------------- | ----------------------------------------- |
| package | `@editorjs/editorjs` | Name of the package to be checked         |
| version | `2.10.0`             | (optional) Current version of the package |

#### Example

```shell
curl -X POST http://localhost:8888/check -d "package=@editorjs/editorjs" -d "version=2.10.0"
```

### Response 

For a success request the latest version will be returned.

```json
{
  "version": "2.11.2"
}
```

On any error you will get an object with a field 'error'.

```json
{
  "error": "Package name is missing"
}
```

```json
{
  "error": "Method not allowed"
}
```  

## Development

Run local server:

```shell
docker-compose up
```

To enable live lua code reloading uncomment the following string in the [`lua/package.lua`](lua/package.lua) file and reload the server.

```nginx
#lua_code_cache off;
``` 

Now you can send requests to `http://locahost:8888/check` url.
