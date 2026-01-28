# Ephemeral Test Runner - Technical Design

## Architecture

### Component Overview

```
+---------------------------------------------------------------+
|                    Ephemeral Test Runner                       |
+---------------------------------------------------------------+
|  CLI Interface Layer                                           |
|    - testrun run [suite]      Execute test suite               |
|    - testrun fixture          Fixture management               |
|    - testrun env              Environment definitions          |
|    - testrun results          Result analysis                  |
|    - testrun debug            Debug failed tests               |
+---------------------------------------------------------------+
|  Business Logic Layer                                          |
|    - Environment Manager  Provision/teardown test environments |
|    - Fixture Loader       Load database fixtures               |
|    - Test Executor        Run test commands, capture output    |
|    - Result Parser        Parse test framework output          |
|    - Cleanup Orchestrator Ensure complete resource cleanup     |
+---------------------------------------------------------------+
|  Integration Layer                                             |
|    - simple_docker        Container lifecycle                  |
|    - simple_json          Configuration, results               |
|    - simple_yaml          Environment definitions              |
|    - simple_file          Fixture files                        |
|    - simple_cli           Argument parsing                     |
|    - simple_testing       Test framework integration           |
|    - simple_sql           Database fixture loading             |
|    - simple_template      Result report generation             |
+---------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `TESTRUN_CLI` | Command-line interface | parse_args, route_command, format_output |
| `TESTRUN_ENGINE` | Core orchestration | provision, execute, capture, cleanup |
| `TESTRUN_ENVIRONMENT` | Environment definition | services, fixtures, network, volumes |
| `TESTRUN_SERVICE` | Service in test environment | container_spec, health_check, fixture |
| `TESTRUN_FIXTURE` | Database fixture | load, apply, verify |
| `TESTRUN_EXECUTOR` | Test command execution | run_command, capture_output, timeout |
| `TESTRUN_RESULT` | Test execution results | passed, failed, skipped, duration |
| `TESTRUN_PARSER` | Parse test output | junit_xml, tap, simple_testing |
| `TESTRUN_CLEANUP` | Resource cleanup | remove_containers, remove_networks, remove_volumes |
| `TESTRUN_DEBUG` | Debug mode | preserve_env, attach_shell, inspect |
| `TESTRUN_REPORTER` | Result reporting | text, json, junit_xml, html |

### Command Structure

```bash
testrun <command> [options] [arguments]

Commands:
  run [suite]           Execute test suite in ephemeral environment
  fixture               Fixture management subcommands
  env                   Environment definition subcommands
  results               Result analysis subcommands
  debug <run-id>        Debug a failed test run
  clean                 Force cleanup of orphaned resources

Run Options:
  -e, --env FILE        Environment definition file (default: testrun.yaml)
  -f, --fixture FILE    Fixture file to load
  -p, --parallel N      Run N test files in parallel
  -t, --timeout SECS    Test timeout in seconds
  --preserve-on-fail    Keep environment on test failure
  --output FORMAT       Result format (text, json, junit)
  --retry N             Retry failed tests N times

Fixture Commands:
  fixture load FILE     Load fixture into running environment
  fixture export DB     Export current database as fixture
  fixture validate      Validate fixture files

Examples:
  testrun run                           # Run all tests
  testrun run tests/integration         # Run specific suite
  testrun run --parallel 4              # Parallel execution
  testrun run --preserve-on-fail        # Debug failures
  testrun debug last                    # Debug last failed run
  testrun results --format junit        # Export JUnit XML
  testrun clean                         # Cleanup orphaned resources
```

### Data Flow

```
Test Command -> CLI Parser -> Engine
                                |
                    +-----------+-----------+
                    |           |           |
               Provision    Execute     Capture
                    |           |           |
              Environment   Tests      Results
                    |           |           |
                    +-----------+-----------+
                                |
                             Cleanup
                                |
                           Report Output
```

### Environment Schema (testrun.yaml)

```yaml
# Ephemeral Test Runner Environment Definition
version: "1.0"
name: my-app-tests

# Test environment services
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: test
      POSTGRES_DB: test_db
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 2s
      timeout: 3s
      retries: 10
    fixtures:
      - fixtures/schema.sql
      - fixtures/seed_data.sql

  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]

  api:
    build: .
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:test@db:5432/test_db
      REDIS_URL: redis://redis:6379
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]

# Test configuration
tests:
  # Test command to run
  command: ./run_tests.sh
  # Or for Eiffel projects
  # command: ./EIFGENs/my_app_tests/W_code/my_app.exe

  # Working directory in test container
  workdir: /app

  # Timeout per test file
  timeout: 300

  # Environment variables for tests
  environment:
    TEST_ENV: integration
    DATABASE_URL: postgres://postgres:test@db:5432/test_db

  # Output format expected from test command
  output_format: simple_testing  # or: junit, tap, mocha

  # Retry flaky tests
  retry_count: 2

# Fixture configuration
fixtures:
  # Auto-load fixtures before tests
  auto_load: true

  # Fixture directory
  directory: ./fixtures

  # Fixture order
  order:
    - schema.sql
    - reference_data.sql
    - test_data.sql

# Cleanup configuration
cleanup:
  # Always cleanup, even on failure (default)
  always: true
  # Preserve environment for N seconds on failure for debugging
  preserve_on_fail: 0
  # Resources to clean
  include:
    - containers
    - networks
    - volumes

# Parallel execution
parallel:
  # Number of parallel workers
  workers: 4
  # Isolation level: per-suite or per-file
  isolation: per-file
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| EnvironmentStartFailed | Cleanup partial, show logs | "Failed to start 'db': {container logs}" |
| FixtureLoadFailed | Cleanup, show error | "Fixture error: {SQL error message}" |
| TestTimeout | Capture partial results, cleanup | "Test timed out after {n}s. Partial results saved." |
| CleanupFailed | Log orphaned resources | "Warning: Could not remove container {id}. Run 'testrun clean'" |
| HealthCheckFailed | Show service logs | "Service 'api' failed health check. Logs: {last 20 lines}" |

## GUI/TUI Future Path

**CLI foundation enables:**
- IDE test runner integration (VS Code, IntelliJ)
- TUI with real-time test progress
- Web dashboard for test analytics
- CI/CD dashboard integration

**What would change for TUI:**
- Add TESTRUN_TUI class using simple_tui
- Real-time test progress with pass/fail indicators
- Service health status panel
- Log streaming panel for debugging

**What would change for GUI:**
- TESTRUN_GUI class with simple_gui bindings
- Visual test timeline
- Service topology diagram
- Interactive result browser
