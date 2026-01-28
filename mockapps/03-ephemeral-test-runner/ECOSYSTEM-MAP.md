# Ephemeral Test Runner - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_docker** | Container lifecycle for test services | TESTRUN_ENGINE - all container operations |
| **simple_json** | Configuration, test results | TESTRUN_RESULT, result parsing |
| **simple_yaml** | Environment definition files | TESTRUN_ENVIRONMENT parsing |
| **simple_file** | Fixture files, result output | TESTRUN_FIXTURE, TESTRUN_REPORTER |
| **simple_cli** | Command-line interface | TESTRUN_CLI argument parsing |
| **simple_testing** | Test framework integration | Result parsing, test execution |
| **simple_config** | User settings | Global configuration |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_sql** | Database fixture loading | PostgreSQL/MySQL fixture support |
| **simple_template** | Report generation | HTML report generation |
| **simple_csv** | Result export | CSV result format |
| **simple_http** | API health checks | HTTP-based health checks |
| **simple_datetime** | Timing metrics | Test duration tracking |

## Integration Patterns

### simple_docker Integration

**Purpose:** Container lifecycle management for test environments

**Usage:**
```eiffel
class TESTRUN_ENGINE

feature -- Environment Management

    provision_environment (a_env: TESTRUN_ENVIRONMENT): BOOLEAN
            -- Provision all services in test environment.
        local
            l_network: detachable DOCKER_NETWORK
        do
            Result := True

            -- Create isolated network for this test run
            l_network := docker_client.create_network (a_env.network_name, "bridge")
            if attached l_network then
                a_env.set_network_id (l_network.id)

                -- Start services in dependency order
                across a_env.services_in_order as svc loop
                    if not start_service (svc, l_network.id) then
                        Result := False
                    end
                end

                -- Wait for all services to be healthy
                if Result then
                    Result := wait_for_healthy (a_env)
                end
            else
                Result := False
            end

            if not Result then
                cleanup_environment (a_env)
            end
        end

    start_service (a_service: TESTRUN_SERVICE; a_network_id: STRING): BOOLEAN
            -- Start a single test service.
        local
            l_spec: CONTAINER_SPEC
        do
            l_spec := a_service.to_container_spec
            l_spec.set_network_mode (a_network_id)

            if attached docker_client.run_container (l_spec) as c then
                a_service.set_container_id (c.id)
                Result := True
            end
        end

    execute_tests (a_env: TESTRUN_ENVIRONMENT): TESTRUN_RESULT
            -- Execute test command in environment.
        local
            l_output: detachable STRING
        do
            create Result.make (a_env.name)

            -- Execute test command in the test container
            if attached a_env.test_container_id as cid then
                l_output := docker_client.exec_in_container (
                    cid,
                    a_env.test_command_array
                )

                if attached l_output as out then
                    Result := parser.parse_output (out, a_env.output_format)
                end
            end
        end

    cleanup_environment (a_env: TESTRUN_ENVIRONMENT)
            -- Remove all resources created for test environment.
        do
            -- Remove containers (force remove running)
            across a_env.container_ids as cid loop
                docker_client.remove_container (cid, True).do_nothing
            end

            -- Remove network
            if attached a_env.network_id as nid then
                docker_client.remove_network (nid).do_nothing
            end

            -- Remove volumes (if created)
            across a_env.volume_names as vname loop
                docker_client.remove_volume (vname, True).do_nothing
            end
        end

feature {NONE} -- Implementation

    docker_client: DOCKER_CLIENT

    parser: TESTRUN_PARSER

end
```

**Data flow:** TESTRUN_ENVIRONMENT -> DOCKER_CLIENT -> Containers/Networks -> Test execution -> Cleanup

### simple_testing Integration

**Purpose:** Parse test results from simple_testing framework

**Usage:**
```eiffel
class TESTRUN_PARSER

feature -- Parsing

    parse_simple_testing_output (a_output: STRING): TESTRUN_RESULT
            -- Parse output from simple_testing test runner.
        local
            l_lines: LIST [STRING]
            l_test_name: STRING
            l_status: INTEGER
        do
            create Result.make ("simple_testing")
            l_lines := a_output.split ('%N')

            across l_lines as line loop
                if line.starts_with ("PASS: ") then
                    l_test_name := line.substring (7, line.count)
                    Result.add_passed (l_test_name)
                elseif line.starts_with ("FAIL: ") then
                    l_test_name := line.substring (7, line.count)
                    Result.add_failed (l_test_name)
                elseif line.starts_with ("SKIP: ") then
                    l_test_name := line.substring (7, line.count)
                    Result.add_skipped (l_test_name)
                end
            end

            -- Extract summary line
            if a_output.has_substring ("Total:") then
                parse_summary_line (a_output, Result)
            end
        end

    parse_junit_xml (a_xml: STRING): TESTRUN_RESULT
            -- Parse JUnit XML format.
        local
            l_json: SIMPLE_JSON
        do
            create Result.make ("junit")
            -- Parse XML using simple_xml or regex extraction
            -- ...implementation...
        end

feature -- Output Generation

    to_junit_xml (a_result: TESTRUN_RESULT): STRING
            -- Generate JUnit XML from results.
        do
            create Result.make (500)
            Result.append ("<?xml version=%"1.0%" encoding=%"UTF-8%"?>%N")
            Result.append ("<testsuite name=%"")
            Result.append (a_result.suite_name)
            Result.append ("%" tests=%"")
            Result.append (a_result.total_count.out)
            Result.append ("%" failures=%"")
            Result.append (a_result.failed_count.out)
            Result.append ("%" time=%"")
            Result.append (a_result.duration_seconds.out)
            Result.append ("%">%N")

            across a_result.test_cases as tc loop
                Result.append ("  <testcase name=%"")
                Result.append (tc.name)
                Result.append ("%" time=%"")
                Result.append (tc.duration.out)
                Result.append ("%">")
                if tc.failed then
                    Result.append ("<failure message=%"")
                    Result.append (tc.failure_message)
                    Result.append ("%"/>")
                end
                Result.append ("</testcase>%N")
            end

            Result.append ("</testsuite>%N")
        end

end
```

### simple_sql Integration

**Purpose:** Load database fixtures

**Usage:**
```eiffel
class TESTRUN_FIXTURE

feature -- Fixture Loading

    load_sql_fixture (a_fixture_path: STRING; a_container_id: STRING; a_db_info: DB_CONNECTION_INFO)
            -- Load SQL fixture file into database container.
        local
            l_sql: STRING
            l_cmd: ARRAY [STRING]
        do
            -- Read fixture file
            l_sql := file_read (a_fixture_path)

            -- Execute via psql/mysql in container
            if a_db_info.is_postgres then
                l_cmd := <<"psql", "-U", a_db_info.user, "-d", a_db_info.database, "-c", l_sql>>
            else
                l_cmd := <<"mysql", "-u", a_db_info.user, "-p" + a_db_info.password, a_db_info.database, "-e", l_sql>>
            end

            docker_client.exec_in_container (a_container_id, l_cmd).do_nothing
        end

    load_fixtures_in_order (a_fixtures: LIST [STRING]; a_container_id: STRING; a_db_info: DB_CONNECTION_INFO)
            -- Load multiple fixtures in order.
        do
            across a_fixtures as fixture loop
                load_sql_fixture (fixture, a_container_id, a_db_info)
            end
        end

feature -- Fixture Export

    export_database (a_container_id: STRING; a_db_info: DB_CONNECTION_INFO; a_output_path: STRING)
            -- Export database to fixture file.
        local
            l_cmd: ARRAY [STRING]
            l_output: detachable STRING
        do
            if a_db_info.is_postgres then
                l_cmd := <<"pg_dump", "-U", a_db_info.user, "-d", a_db_info.database>>
            else
                l_cmd := <<"mysqldump", "-u", a_db_info.user, "-p" + a_db_info.password, a_db_info.database>>
            end

            l_output := docker_client.exec_in_container (a_container_id, l_cmd)
            if attached l_output as dump then
                file_write (a_output_path, dump)
            end
        end

end
```

### simple_yaml Integration

**Purpose:** Parse testrun.yaml environment definitions

**Usage:**
```eiffel
class TESTRUN_ENVIRONMENT

feature -- Creation

    make_from_yaml (a_path: STRING)
            -- Create environment from YAML file.
        local
            l_yaml: SIMPLE_YAML
            l_doc: YAML_DOCUMENT
        do
            create l_yaml
            l_doc := l_yaml.parse_file (a_path)

            name := l_doc.string_at ("name")
            version := l_doc.string_at ("version")

            -- Parse services
            if attached l_doc.map_at ("services") as svc_map then
                across svc_map.keys as k loop
                    services.extend (parse_service (k, svc_map.map_at (k)))
                end
            end

            -- Parse test configuration
            if attached l_doc.map_at ("tests") as test_map then
                test_command := test_map.string_at ("command")
                test_timeout := test_map.integer_at ("timeout")
                output_format := test_map.string_at ("output_format")
            end

            -- Parse fixtures
            if attached l_doc.map_at ("fixtures") as fix_map then
                fixtures_directory := fix_map.string_at ("directory")
                fixtures_auto_load := fix_map.boolean_at ("auto_load")
                if attached fix_map.sequence_at ("order") as order_seq then
                    across order_seq as item loop
                        fixtures_order.extend (item.as_string)
                    end
                end
            end
        end

end
```

## Dependency Graph

```
ephemeral_test_runner
    |
    +-- simple_docker (required)
    |       +-- simple_ipc
    |       +-- simple_json
    |       +-- simple_file
    |       +-- simple_logger
    |
    +-- simple_json (required)
    |
    +-- simple_yaml (required)
    |
    +-- simple_cli (required)
    |
    +-- simple_file (required)
    |
    +-- simple_testing (required)
    |
    +-- simple_config (required)
    |
    +-- simple_sql (optional, fixtures)
    |
    +-- simple_template (optional, reports)
    |
    +-- simple_http (optional, health checks)
    |
    +-- simple_datetime (optional, timing)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        name="ephemeral_test_runner"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <target name="ephemeral_test_runner">
        <root class="TESTRUN_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true"
                        invariant="true" loop="true" supplier_precondition="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="testrun"/>
        <setting name="dead_code_removal" value="feature"/>

        <capability>
            <concurrency support="none"/>
            <void_safety support="all"/>
        </capability>

        <!-- Required simple_* dependencies -->
        <library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL/simple_config/simple_config.ecf"/>

        <!-- Optional dependencies -->
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>

        <!-- ISE dependencies -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>
    </target>

    <!-- CLI executable -->
    <target name="testrun_cli" extends="ephemeral_test_runner">
        <root class="TESTRUN_CLI" feature="make"/>
    </target>

    <!-- Test target -->
    <target name="testrun_tests" extends="ephemeral_test_runner">
        <root class="TEST_APP" feature="make"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
