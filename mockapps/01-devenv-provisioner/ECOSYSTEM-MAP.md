# DevEnv Provisioner - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_docker** | Container lifecycle management | Core engine, all container operations |
| **simple_yaml** | Parse devenv.yaml configuration | DEVENV_PARSER class |
| **simple_json** | State persistence, API responses | DEVENV_STATE, DEVENV_REPORTER |
| **simple_file** | Template file management | DEVENV_TEMPLATE class |
| **simple_cli** | Command-line interface | DEVENV_CLI argument parsing |
| **simple_config** | User settings persistence | Global config, credentials |
| **simple_validation** | Configuration validation | DEVENV_PARSER validation rules |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_http** | Cloud sync, registry auth | Pro/Enterprise tier features |
| **simple_encryption** | Credential storage | When storing registry passwords |
| **simple_csv** | Export environment list | Reporting features |
| **simple_template** | Custom template rendering | Advanced template variables |
| **simple_hash** | Config fingerprinting | Change detection, caching |

## Integration Patterns

### simple_docker Integration

**Purpose:** All container lifecycle management

**Usage:**
```eiffel
class DEVENV_ENGINE

feature -- Container Management

    start_service (a_service: DEVENV_SERVICE)
            -- Start container for service.
        local
            l_spec: CONTAINER_SPEC
        do
            l_spec := a_service.to_container_spec
            if attached docker_client.run_container (l_spec) as c then
                state.track_container (a_service.name, c.id)
            end
        end

    stop_all_services
            -- Stop all containers in environment.
        do
            across state.tracked_containers as entry loop
                docker_client.stop_container (entry.item, 10).do_nothing
            end
        end

feature {NONE} -- Implementation

    docker_client: DOCKER_CLIENT
            -- Docker client for container operations.

end
```

**Data flow:** DEVENV_SERVICE -> CONTAINER_SPEC -> DOCKER_CLIENT -> Docker Engine

### simple_yaml Integration

**Purpose:** Parse devenv.yaml configuration files

**Usage:**
```eiffel
class DEVENV_PARSER

feature -- Parsing

    parse_file (a_path: STRING): DEVENV_CONFIG
            -- Parse devenv.yaml file.
        local
            l_yaml: SIMPLE_YAML
            l_doc: YAML_DOCUMENT
        do
            create l_yaml
            l_doc := l_yaml.parse_file (a_path)
            Result := parse_document (l_doc)
        ensure
            result_valid: Result.is_valid
        end

feature {NONE} -- Implementation

    parse_document (a_doc: YAML_DOCUMENT): DEVENV_CONFIG
            -- Convert YAML document to config object.
        local
            l_services: YAML_MAP
        do
            create Result.make
            Result.set_name (a_doc.string_at ("name"))
            Result.set_version (a_doc.string_at ("version"))

            l_services := a_doc.map_at ("services")
            across l_services.keys as k loop
                Result.add_service (parse_service (k, l_services.map_at (k)))
            end
        end

end
```

**Data flow:** YAML file -> SIMPLE_YAML -> YAML_DOCUMENT -> DEVENV_CONFIG

### simple_json Integration

**Purpose:** State persistence and structured output

**Usage:**
```eiffel
class DEVENV_STATE

feature -- Persistence

    save_state
            -- Save current state to .devenv/state.json.
        local
            l_json: SIMPLE_JSON_OBJECT
        do
            create l_json.make
            l_json.put_string (project_name, "project")
            l_json.put_object (containers_to_json, "containers")
            l_json.put_integer (started_at.as_timestamp, "started_at")
            file_write (state_file_path, l_json.to_string)
        end

    load_state
            -- Load state from .devenv/state.json.
        local
            l_json: SIMPLE_JSON
            l_content: STRING
        do
            l_content := file_read (state_file_path)
            create l_json
            if attached l_json.parse (l_content) as v and then v.is_object then
                restore_from_json (v.as_object)
            end
        end

end
```

**Data flow:** Runtime state <-> JSON file

### simple_cli Integration

**Purpose:** Command-line argument parsing and formatted output

**Usage:**
```eiffel
class DEVENV_CLI

feature -- Command Routing

    execute
            -- Parse arguments and execute command.
        local
            l_parser: CLI_PARSER
        do
            create l_parser.make ("devenv")
            l_parser.add_command ("up", agent do_up)
            l_parser.add_command ("down", agent do_down)
            l_parser.add_command ("status", agent do_status)
            l_parser.add_flag ("verbose", "v", "Verbose output")
            l_parser.add_option ("file", "f", "Configuration file", "devenv.yaml")

            l_parser.parse_and_execute (arguments)
        end

feature {NONE} -- Commands

    do_up (a_args: CLI_ARGUMENTS)
            -- Handle 'devenv up' command.
        do
            if a_args.has_flag ("verbose") then
                reporter.set_verbose (True)
            end
            engine.start_environment
            reporter.show_status (engine.status)
        end

end
```

### simple_validation Integration

**Purpose:** Validate devenv.yaml configuration

**Usage:**
```eiffel
class DEVENV_VALIDATOR

feature -- Validation

    validate_config (a_config: DEVENV_CONFIG): VALIDATION_RESULT
            -- Validate configuration.
        local
            l_validator: SIMPLE_VALIDATOR
        do
            create l_validator.make
            create Result.make

            -- Required fields
            l_validator.require_non_empty (a_config.name, "name")
            l_validator.require_non_empty (a_config.version, "version")

            -- Service validation
            across a_config.services as svc loop
                l_validator.require_non_empty (svc.image, "services." + svc.name + ".image")
                validate_ports (svc.ports, l_validator)
                validate_volumes (svc.volumes, l_validator)
            end

            Result := l_validator.result
        end

end
```

## Dependency Graph

```
devenv_provisioner
    |
    +-- simple_docker (required)
    |       +-- simple_ipc
    |       +-- simple_json
    |       +-- simple_file
    |       +-- simple_logger
    |
    +-- simple_yaml (required)
    |
    +-- simple_json (required)
    |
    +-- simple_cli (required)
    |
    +-- simple_file (required)
    |
    +-- simple_config (required)
    |
    +-- simple_validation (required)
    |
    +-- simple_http (optional, Pro tier)
    |
    +-- simple_encryption (optional, credentials)
    |
    +-- simple_template (optional, advanced)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-23-0
            http://www.eiffel.com/developers/xml/configuration-1-23-0.xsd"
        name="devenv_provisioner"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <target name="devenv_provisioner">
        <root class="DEVENV_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true"
                        invariant="true" loop="true" supplier_precondition="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="devenv"/>
        <setting name="dead_code_removal" value="feature"/>

        <capability>
            <concurrency support="none"/>
            <void_safety support="all"/>
        </capability>

        <!-- simple_* ecosystem dependencies -->
        <library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
        <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL/simple_config/simple_config.ecf"/>
        <library name="simple_validation" location="$SIMPLE_EIFFEL/simple_validation/simple_validation.ecf"/>

        <!-- ISE dependencies (only when no simple_* alternative) -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>
    </target>

    <!-- CLI executable target -->
    <target name="devenv_cli" extends="devenv_provisioner">
        <root class="DEVENV_CLI" feature="make"/>
    </target>

    <!-- Test target -->
    <target name="devenv_tests" extends="devenv_provisioner">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
