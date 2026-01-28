# Container Compliance Auditor - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_docker** | Container/image inspection | COMPLY_SCANNER - all inspection operations |
| **simple_json** | Policy definitions, scan results | COMPLY_POLICY, COMPLY_SCAN_RESULT |
| **simple_yaml** | Policy files, configuration | COMPLY_POLICY_ENGINE loading |
| **simple_file** | Report output, evidence storage | COMPLY_REPORT, evidence management |
| **simple_cli** | Command-line interface | COMPLY_CLI argument parsing |
| **simple_hash** | Image fingerprinting | Baseline comparison, cache keys |
| **simple_template** | Report template rendering | COMPLY_REPORT PDF/HTML generation |
| **simple_config** | User settings | Global config, API keys |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_csv** | Audit export format | CSV report generation |
| **simple_http** | Registry API, webhook notifications | Enterprise tier features |
| **simple_sql** | Scan history storage | Business/Enterprise tier |
| **simple_encryption** | Sensitive finding handling | Storing credentials findings |
| **simple_datetime** | Timestamp handling | Audit trail, scheduling |

## Integration Patterns

### simple_docker Integration

**Purpose:** Container and image inspection for compliance checking

**Usage:**
```eiffel
class COMPLY_SCANNER

feature -- Scanning

    scan_image (a_image: STRING): COMPLY_SCAN_RESULT
            -- Scan Docker image for compliance.
        local
            l_image: detachable DOCKER_IMAGE
            l_inspection: detachable SIMPLE_JSON_OBJECT
        do
            create Result.make (a_image)

            -- Get image metadata
            l_image := docker_client.get_image (a_image)
            if attached l_image as img then
                Result.set_image_info (img)

                -- Inspect image configuration
                l_inspection := inspect_image_config (a_image)
                if attached l_inspection as insp then
                    run_checks (Result, insp)
                end
            else
                Result.add_error ("Image not found: " + a_image)
            end
        end

    scan_container (a_container_id: STRING): COMPLY_SCAN_RESULT
            -- Scan running container for compliance.
        local
            l_container: detachable DOCKER_CONTAINER
        do
            create Result.make (a_container_id)

            l_container := docker_client.get_container (a_container_id)
            if attached l_container as c then
                Result.set_container_info (c)

                -- Check runtime configuration
                check_runtime_user (Result, c)
                check_privileged_mode (Result, c)
                check_resource_limits (Result, c)
                check_network_mode (Result, c)
                check_volume_mounts (Result, c)
            else
                Result.add_error ("Container not found: " + a_container_id)
            end
        end

feature {NONE} -- Checks

    check_runtime_user (a_result: COMPLY_SCAN_RESULT; a_container: DOCKER_CONTAINER)
            -- Check if container runs as non-root.
        do
            -- Uses exec_in_container to check actual running user
            if attached docker_client.exec_in_container (a_container.id, <<"id", "-u">>) as uid then
                if uid.to_integer = 0 then
                    a_result.add_finding (create {COMPLY_FINDING}.make_critical (
                        "CIS-4.1",
                        "Container running as root user",
                        "UID: " + uid,
                        "Set USER directive in Dockerfile or use --user flag"
                    ))
                end
            end
        end

feature {NONE} -- Implementation

    docker_client: DOCKER_CLIENT

end
```

**Data flow:** Target -> DOCKER_CLIENT inspection -> JSON config -> Policy checks -> Findings

### simple_json Integration

**Purpose:** Policy definitions and scan result serialization

**Usage:**
```eiffel
class COMPLY_SCAN_RESULT

feature -- Serialization

    to_json: SIMPLE_JSON_OBJECT
            -- Convert scan result to JSON.
        local
            l_findings_array: SIMPLE_JSON_ARRAY
        do
            create Result.make
            Result.put_string (target, "target")
            Result.put_string (scan_timestamp.out, "timestamp")
            Result.put_integer (pass_count, "pass_count")
            Result.put_integer (fail_count, "fail_count")
            Result.put_string (overall_status.out, "status")

            -- Findings array
            create l_findings_array.make
            across findings as f loop
                l_findings_array.extend (f.to_json)
            end
            Result.put_array (l_findings_array, "findings")

            -- Metadata
            Result.put_string (framework_name, "framework")
            Result.put_string (policy_version, "policy_version")
        end

    from_json (a_json: SIMPLE_JSON_OBJECT)
            -- Restore scan result from JSON.
        do
            target := a_json.string_item ("target").to_string_8
            scan_timestamp := parse_timestamp (a_json.string_item ("timestamp"))
            pass_count := a_json.integer_item ("pass_count").to_integer
            fail_count := a_json.integer_item ("fail_count").to_integer

            if attached a_json.array_item ("findings") as arr then
                across 1 |..| arr.count as i loop
                    if attached arr.object_item (i) as obj then
                        findings.extend (create {COMPLY_FINDING}.from_json (obj))
                    end
                end
            end
        end

end
```

### simple_yaml Integration

**Purpose:** Load compliance policies from YAML files

**Usage:**
```eiffel
class COMPLY_POLICY_ENGINE

feature -- Policy Loading

    load_policy_file (a_path: STRING): COMPLY_POLICY
            -- Load policy from YAML file.
        local
            l_yaml: SIMPLE_YAML
            l_doc: YAML_DOCUMENT
        do
            create l_yaml
            l_doc := l_yaml.parse_file (a_path)

            create Result.make
            Result.set_name (l_doc.string_at ("name"))
            Result.set_framework (l_doc.string_at ("framework"))
            Result.set_version (l_doc.string_at ("version"))

            -- Load rules
            if attached l_doc.sequence_at ("rules") as rules_seq then
                across rules_seq as rule_node loop
                    Result.add_rule (parse_rule (rule_node.as_map))
                end
            end
        end

    load_framework (a_framework: STRING): COMPLY_POLICY
            -- Load built-in framework policy.
        do
            inspect a_framework
            when "cis" then
                Result := load_cis_docker_policy
            when "pci-dss" then
                Result := load_pci_dss_policy
            when "hipaa" then
                Result := load_hipaa_policy
            when "soc2" then
                Result := load_soc2_policy
            else
                create Result.make_empty
            end
        end

end
```

### simple_hash Integration

**Purpose:** Image fingerprinting for baseline comparison

**Usage:**
```eiffel
class COMPLY_BASELINE

feature -- Fingerprinting

    create_fingerprint (a_image: STRING): STRING
            -- Generate content fingerprint for image.
        local
            l_hasher: SIMPLE_HASH
            l_config: STRING
        do
            create l_hasher.make_sha256

            -- Hash image configuration
            if attached get_image_config (a_image) as cfg then
                l_hasher.update (cfg.to_string)
            end

            -- Hash layer digests
            across get_layer_digests (a_image) as digest loop
                l_hasher.update (digest)
            end

            Result := l_hasher.final_hex
        end

    compare_to_baseline (a_current: STRING; a_baseline: COMPLY_BASELINE): ARRAYED_LIST [COMPLY_DIFF]
            -- Compare current image to baseline, return differences.
        local
            l_current_fingerprint: STRING
        do
            create Result.make (10)
            l_current_fingerprint := create_fingerprint (a_current)

            if not l_current_fingerprint.same_string (a_baseline.fingerprint) then
                -- Detailed comparison
                compare_layers (a_current, a_baseline, Result)
                compare_config (a_current, a_baseline, Result)
                compare_env_vars (a_current, a_baseline, Result)
            end
        end

end
```

### simple_template Integration

**Purpose:** Generate formatted compliance reports

**Usage:**
```eiffel
class COMPLY_REPORT

feature -- Report Generation

    generate_html_report (a_result: COMPLY_SCAN_RESULT): STRING
            -- Generate HTML compliance report.
        local
            l_template: SIMPLE_TEMPLATE
            l_context: TEMPLATE_CONTEXT
        do
            create l_template.make_from_file (html_report_template_path)

            create l_context.make
            l_context.put_string (a_result.target, "target")
            l_context.put_string (a_result.scan_timestamp.out, "scan_date")
            l_context.put_integer (a_result.pass_count, "pass_count")
            l_context.put_integer (a_result.fail_count, "fail_count")
            l_context.put_string (severity_badge (a_result.highest_severity), "severity_badge")
            l_context.put_list (findings_to_list (a_result.findings), "findings")

            Result := l_template.render (l_context)
        end

    generate_executive_summary (a_results: LIST [COMPLY_SCAN_RESULT]): STRING
            -- Generate executive summary across multiple scans.
        local
            l_template: SIMPLE_TEMPLATE
            l_context: TEMPLATE_CONTEXT
        do
            create l_template.make_from_file (executive_summary_template_path)

            create l_context.make
            l_context.put_integer (a_results.count, "total_scans")
            l_context.put_integer (count_critical (a_results), "critical_findings")
            l_context.put_integer (count_compliant (a_results), "compliant_count")
            l_context.put_real (compliance_percentage (a_results), "compliance_pct")

            Result := l_template.render (l_context)
        end

end
```

## Dependency Graph

```
container_compliance_auditor
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
    +-- simple_hash (required)
    |
    +-- simple_template (required)
    |
    +-- simple_config (required)
    |
    +-- simple_csv (optional, export)
    |
    +-- simple_http (optional, Enterprise)
    |
    +-- simple_sql (optional, Business+)
    |
    +-- simple_datetime (optional)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        name="container_compliance_auditor"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <target name="container_compliance_auditor">
        <root class="COMPLY_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true"
                        invariant="true" loop="true" supplier_precondition="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="comply"/>
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
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL/simple_config/simple_config.ecf"/>

        <!-- Optional dependencies -->
        <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>

        <!-- ISE dependencies -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>
        <cluster name="policies" location=".\policies\" recursive="true"/>
    </target>

    <!-- CLI executable -->
    <target name="comply_cli" extends="container_compliance_auditor">
        <root class="COMPLY_CLI" feature="make"/>
    </target>

    <!-- Test target -->
    <target name="comply_tests" extends="container_compliance_auditor">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
