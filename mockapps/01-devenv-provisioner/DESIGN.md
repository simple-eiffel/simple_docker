# DevEnv Provisioner - Technical Design

## Architecture

### Component Overview

```
+---------------------------------------------------------------+
|                    DevEnv Provisioner                          |
+---------------------------------------------------------------+
|  CLI Interface Layer                                           |
|    - devenv init          Initialize new environment           |
|    - devenv up            Start environment                    |
|    - devenv down          Stop environment                     |
|    - devenv status        Show environment status              |
|    - devenv template      Manage templates                     |
|    - devenv share         Team sharing commands                |
+---------------------------------------------------------------+
|  Business Logic Layer                                          |
|    - Environment Parser   Parse devenv.yaml files              |
|    - Template Engine      Apply and customize templates        |
|    - Dependency Resolver  Order service startup                |
|    - Health Monitor       Check service readiness              |
|    - State Manager        Track running environments           |
+---------------------------------------------------------------+
|  Integration Layer                                             |
|    - simple_docker        Container lifecycle management       |
|    - simple_yaml          Configuration file parsing           |
|    - simple_json          State persistence, API responses     |
|    - simple_file          Template file management             |
|    - simple_config        User settings persistence            |
|    - simple_cli           Argument parsing, output formatting  |
|    - simple_validation    Configuration validation             |
+---------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `DEVENV_CLI` | Command-line interface | parse_args, route_command, format_output |
| `DEVENV_ENGINE` | Core orchestration | up, down, status, apply_template |
| `DEVENV_PARSER` | Configuration parsing | parse_yaml, validate_config, resolve_refs |
| `DEVENV_TEMPLATE` | Template management | list, apply, customize, export |
| `DEVENV_SERVICE` | Service representation | container_spec, health_check, depends_on |
| `DEVENV_NETWORK` | Network configuration | create_network, connect_services |
| `DEVENV_VOLUME` | Volume configuration | create_volumes, mount_points |
| `DEVENV_STATE` | State persistence | save_state, load_state, track_containers |
| `DEVENV_HEALTH` | Health monitoring | check_ready, wait_for_healthy, timeout |
| `DEVENV_REPORTER` | Output formatting | text, json, table, progress |

### Command Structure

```bash
devenv <command> [options] [arguments]

Commands:
  init [template]     Initialize environment from template
  up                  Start all services in environment
  down                Stop all services
  restart [service]   Restart service(s)
  status              Show environment status
  logs [service]      View service logs
  exec <service>      Execute command in service container
  template            Template management subcommands
  share               Team sharing subcommands
  config              Configuration management

Global Options:
  -f, --file FILE     Environment file (default: devenv.yaml)
  -p, --project NAME  Project name (default: directory name)
  -v, --verbose       Verbose output
  --json              JSON output format
  --help              Show help

Examples:
  devenv init rails           # Initialize Rails + Postgres environment
  devenv up                   # Start all services
  devenv exec db psql         # Open psql shell in database
  devenv logs --follow web    # Tail web server logs
  devenv down --volumes       # Stop and remove volumes
```

### Data Flow

```
User Command -> CLI Parser -> Engine Router -> Service Handler
                                                    |
                                     +--------------+---------------+
                                     |              |               |
                                  Parser      Docker Client     State Manager
                                     |              |               |
                              YAML Config     Containers      State File
```

### Configuration Schema (devenv.yaml)

```yaml
# DevEnv Provisioner Configuration
version: "1.0"
name: my-project

# Service definitions
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./public:/usr/share/nginx/html
    depends_on:
      - api
    environment:
      BACKEND_URL: http://api:3000

  api:
    build: ./api
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/myapp
      REDIS_URL: redis://redis:6379

  db:
    image: postgres:16-alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: myapp
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

# Named volumes
volumes:
  db_data:
    driver: local

# Networks (optional, default bridge created)
networks:
  default:
    driver: bridge

# Template metadata (when used as template)
template:
  name: Full Stack Rails
  description: Rails API with Postgres, Redis, and Nginx
  tags: [rails, postgres, redis, nginx]
  author: DevEnv Team
  version: "1.0.0"
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| ConfigNotFound | Exit with help | "No devenv.yaml found. Run 'devenv init' to create one." |
| InvalidConfig | Show validation errors | "Configuration error: {details}" |
| ImagePullFailed | Retry with auth prompt | "Failed to pull image. Check network or authentication." |
| PortConflict | Suggest alternative | "Port 8080 in use. Try 'devenv up --port-offset 100'" |
| ContainerCrash | Show logs, suggest fix | "Service 'db' crashed. Logs: {last 10 lines}" |
| DockerNotRunning | Installation instructions | "Docker not responding. Is Docker Desktop running?" |

## GUI/TUI Future Path

**CLI foundation enables:**
- IDE plugins (VS Code, IntelliJ) that invoke CLI commands
- TUI dashboard showing service status with real-time updates
- Web UI for template browsing and environment management
- Shared components: DEVENV_ENGINE, DEVENV_PARSER, DEVENV_STATE

**What would change for TUI:**
- Add DEVENV_TUI class using simple_tui for terminal UI
- Event-driven updates via simple_docker log streaming
- Keyboard navigation for service selection

**What would change for GUI:**
- DEVENV_GUI class with simple_gui bindings
- Real-time container status visualization
- Drag-and-drop template customization
