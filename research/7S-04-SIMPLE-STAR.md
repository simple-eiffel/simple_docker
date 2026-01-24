# 7S-04: SIMPLE-STAR Ecosystem Integration


**Date**: 2026-01-23

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Ecosystem Dependencies

### Required Libraries
- **simple_json** - JSON parsing for API responses (SIMPLE_JSON_OBJECT, SIMPLE_JSON_ARRAY)
- **simple_http** - HTTP communication (SIMPLE_HTTP_CLIENT)

## Integration Patterns

### With simple_json

```eiffel
-- Parsing container list response
json: SIMPLE_JSON_ARRAY
container: DOCKER_CONTAINER

json := parser.parse_array (response_body)
across json as j loop
    if attached j.as_object as obj then
        create container.make_from_json (obj)
    end
end
```

### With simple_http

```eiffel
-- Making API request
http: SIMPLE_HTTP_CLIENT
response: HTTP_RESPONSE

create http.make_with_socket ("/var/run/docker.sock")
response := http.get ("/containers/json")
if response.status_code = 200 then
    -- Parse JSON response
end
```

## API Consistency

Follows simple_* patterns:
- **Multiple creation procedures** - make, make_from_json
- **Fluent builder** - CONTAINER_SPEC method chaining
- **Query/Command separation** - Clear distinction
- **Design by Contract** - Full DBC coverage
- **Quick facade** - SIMPLE_DOCKER_QUICK for beginners

## Usage Examples

```eiffel
-- Quick: Run PostgreSQL
docker: SIMPLE_DOCKER_QUICK
create docker.make
docker.postgres ("mypassword")

-- Full: Custom container
client: DOCKER_CLIENT
spec: CONTAINER_SPEC
create client.make
create spec.make ("myapp:latest")
spec.set_name ("myapp-instance")
    .add_port (8080, 80)
    .set_restart_policy ("always")
container := client.run_container (spec)
```
