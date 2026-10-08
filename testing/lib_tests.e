note
	description: "[
		Tests for SIMPLE_DOCKER library.

		PREREQUISITES:
		- Docker Desktop must be running
		- Tests connect to local Docker daemon via named pipe

		Tests are organized by category:
		- Connection tests (ping, version)
		- Image tests (list, exists)
		- Container tests (create, start, stop, remove)
		- Spec tests (fluent API, JSON generation)
		- State tests (state machine helpers)
	]"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE
		redefine
			on_prepare,
			on_clean
		end

feature {NONE} -- Fixtures

	fixtures: CONTAINER_FIXTURES
		once
			create Result
		end

	setup_fixtures
			-- Initialize fixtures with current client.
		do
			fixtures.set_client (client)
		end

feature -- Setup

	on_prepare
			-- Set up test fixtures.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_retry_count: INTEGER
		do
			-- Reuse client to avoid IPC connection overhead
			if not attached shared_client then
				create l_env
				l_env.sleep (100_000_000) -- 100ms initial delay for Docker daemon
				shared_client := new_client
			end
			if attached shared_client as sc then
				client := sc
			else
				client := new_client
			end
			setup_fixtures
			test_counter := test_counter + 1
		rescue
			-- Retry on IPC connection failures
			l_retry_count := l_retry_count + 1
			if l_retry_count <= 3 then
				create l_env
				l_env.sleep (200_000_000) -- 200ms retry delay
				retry
			end
		end

	on_clean
			-- Clean up after a test: remove whatever it created and did not
			-- remove itself. The runner also calls this from its rescue path,
			-- so a test that fails part-way leaves nothing behind.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			if attached test_container_id as cid then
				if client.remove_container (cid, True) then end
				test_container_id := Void
			end
			if attached test_network_id as nid then
				if client.remove_network (nid) then end
				test_network_id := Void
			end
			if attached test_volume_name as vname then
				if client.remove_volume (vname, True) then end
				test_volume_name := Void
			end
			if attached active_quick as al_quick then
				al_quick.cleanup
				active_quick := Void
			end
			-- Small delay to allow IPC pipe to settle
			create l_env
			l_env.sleep (50_000_000) -- 50ms
		end

feature -- Daemon availability

	docker_available: BOOLEAN
			-- Does the Docker daemon answer a ping? Probed once per run;
			-- tests that need the daemon are skipped when it does not.
		once
			Result := daemon_answers_ping
		end

	docker_unavailable_reason: STRING
			-- Why daemon tests are skipped.
		once
			Result := "Docker daemon not reachable at \\.\pipe\" + endpoint_name
		end

	endpoint_name: STRING
			-- Named pipe the tests use: SIMPLE_DOCKER_TEST_ENDPOINT when set,
			-- else the Docker default.
		once
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SIMPLE_DOCKER_TEST_ENDPOINT") as al_name
				and then not al_name.is_empty
			then
				Result := al_name.to_string_8
			else
				Result := {DOCKER_CLIENT}.default_windows_endpoint
			end
		end

	new_client: DOCKER_CLIENT
			-- New client on `endpoint_name'.
		do
			if endpoint_name.same_string ({DOCKER_CLIENT}.default_windows_endpoint) then
				create Result.make
			else
				create Result.make_with_endpoint (endpoint_name)
			end
		end

feature {NONE} -- Daemon availability

	daemon_answers_ping: BOOLEAN
			-- Ping the daemon on a fresh client; False on any failure.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				Result := new_client.ping
			end
		rescue
			l_failed := True
			retry
		end

feature -- Access

	client: DOCKER_CLIENT
			-- Docker client for tests.

	shared_client: detachable DOCKER_CLIENT
			-- Shared client reused across all tests.

	test_counter: INTEGER
			-- Counter for unique names.

	test_container_id: detachable STRING
			-- ID of test container (for cleanup).

	test_network_id: detachable STRING
			-- ID of test network (for cleanup).

	test_volume_name: detachable STRING
			-- Name of test volume (for cleanup).

	active_quick: detachable SIMPLE_DOCKER_QUICK
			-- Quick facade whose containers `on_clean' removes.

	run_tag: STRING
			-- Random tag for this test run, part of every name the tests give
			-- to containers, networks and volumes, so a run never collides
			-- with a name left by an earlier run (HTTP 409 Conflict).
		local
			l_generator: UUID_GENERATOR
		once
			create l_generator
			Result := l_generator.generate_uuid.out.as_lower
			Result.prune_all ('-')
			Result.keep_head (8)
		ensure
			eight_chars: Result.count = 8
		end

	unique_test_name (a_kind: STRING): STRING
			-- Name for a `a_kind' resource of the current test, unique to this run.
		require
			kind_not_empty: not a_kind.is_empty
		do
			Result := "simple_docker_" + a_kind + "_" + run_tag + "_" + test_counter.out
		ensure
			has_run_tag: Result.has_substring (run_tag)
		end

	client_error_text: STRING
			-- Last client error, for assertion messages.
		do
			if attached client.last_error as e then
				Result := e.out
			else
				Result := "no error reported"
			end
		end

	ensure_alpine
			-- Make sure alpine:latest is present, pulling it if needed.
		do
			if not client.image_exists ("alpine:latest") then
				if client.pull_image ("alpine:latest") then end
			end
			assert ("alpine:latest available: " + client_error_text, client.image_exists ("alpine:latest"))
		end

	connection_in_step (a_id: STRING): BOOLEAN
			-- Does a plain request on the shared connection still get its own
			-- response (the container `a_id' inspected back)?
		do
			Result := attached client.get_container (a_id) as al_c and then al_c.id.same_string (a_id)
		end

feature -- Test: Connection

	test_ping
			-- Test ping Docker daemon.
		do
			assert_true ("ping succeeds", client.ping)
			assert_false ("no error after ping", client.has_error)
		end

	test_version
			-- Test get version info.
		do
			if attached client.version as v then
				assert ("has Version key", v.has_key ("Version"))
				assert ("has ApiVersion key", v.has_key ("ApiVersion"))
				assert ("no error", not client.has_error)
			else
				assert ("version returned (requires Docker Desktop)", False)
			end
		end

	test_info
			-- Test get system info.
		do
			if attached client.info as i then
				assert ("has Containers key", i.has_key ("Containers"))
				assert ("has Images key", i.has_key ("Images"))
				assert ("no error", not client.has_error)
			else
				assert ("info returned (requires Docker Desktop)", False)
			end
		end

feature -- Test: Images

	test_list_images
			-- Test listing images.
		local
			l_images: ARRAYED_LIST [DOCKER_IMAGE]
		do
			l_images := client.list_images
			assert ("no error", not client.has_error)
			assert ("images list exists", l_images /= Void)
			-- Note: May be empty if no images pulled
		end

	test_image_exists_alpine
			-- alpine:latest is present, or can be pulled.
		do
			if not client.image_exists ("alpine:latest") then
				if client.pull_image ("alpine:latest") then end
			end
			assert ("alpine exists: " + client_error_text, client.image_exists ("alpine:latest"))
		end

	test_build_dockerfile_builder_generates_valid_output
			-- Test DOCKERFILE_BUILDER produces valid Dockerfile content (P3).
			-- This tests the builder API without actually calling Docker build,
			-- which would require streaming response handling.
		local
			l_builder: DOCKERFILE_BUILDER
			l_dockerfile: STRING
		do
			-- Create a simple Dockerfile using the builder
			create l_builder.make ("alpine:latest")
			l_builder.run ("echo 'test'")
				.copy_files ("src", "/app")
				.workdir ("/app")
				.cmd (<<"./start.sh">>).do_nothing

			l_dockerfile := l_builder.to_string

			-- Verify the output contains expected directives
			assert ("has FROM", l_dockerfile.has_substring ("FROM alpine:latest"))
			assert ("has RUN", l_dockerfile.has_substring ("RUN echo"))
			assert ("has COPY", l_dockerfile.has_substring ("COPY src /app"))
			assert ("has WORKDIR", l_dockerfile.has_substring ("WORKDIR /app"))
			assert ("has CMD", l_dockerfile.has_substring ("CMD"))
		end

feature -- Test: Containers

	test_list_containers
			-- Test listing containers.
		local
			l_containers: ARRAYED_LIST [DOCKER_CONTAINER]
		do
			l_containers := client.list_containers (True)
			assert_false ("no error", client.has_error)
			assert_attached ("containers list exists", l_containers)
		end

	test_create_and_remove_container
			-- Test creating and removing a container.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("test"))
				.set_cmd (<<"echo", "hello">>).do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container id", c.id.count > 0)
				assert ("short id is 12 chars", c.short_id.count = 12)
				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

	test_container_lifecycle
			-- Test full container lifecycle: create, start, stop, remove.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("lifecycle"))
				.set_cmd (<<"sleep", "10">>).do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))
				assert ("is running", attached client.get_container (c.id) as running and then running.is_running)
				assert ("container stopped", client.stop_container (c.id, 1))
				assert ("is exited", attached client.get_container (c.id) as stopped and then stopped.is_exited)
				assert ("container removed", client.remove_container (c.id, False))
				test_container_id := Void
			end
		end

feature -- Test: Container Spec

	test_spec_basic
			-- Test basic spec creation.
		local
			l_spec: CONTAINER_SPEC
		do
			create l_spec.make ("nginx:alpine")
			assert ("image set", l_spec.image.same_string ("nginx:alpine"))
			assert ("no name initially", l_spec.name = Void)
		end

	test_spec_fluent_api
			-- Test fluent API chaining.
		local
			l_spec: CONTAINER_SPEC
		do
			create l_spec.make ("nginx:alpine")
			l_spec.set_name ("my-nginx")
				.add_port (80, 8080)
				.add_env ("DEBUG", "true")
				.set_memory_limit (512 * 1024 * 1024).do_nothing

			assert ("name set", attached l_spec.name as n and then n.same_string ("my-nginx"))
			assert ("port added", l_spec.port_bindings.count = 1)
			assert ("env added", l_spec.environment.count = 1)
			assert ("memory set", l_spec.memory_limit = 512 * 1024 * 1024)
		end

	test_spec_to_json
			-- Test JSON generation.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("alpine:latest")
			l_spec.set_name ("test-container")
				.add_env ("FOO", "bar")
				.add_port (80, 8080).do_nothing

			l_json := l_spec.to_json
			assert ("json not empty", not l_json.is_empty)
			assert ("has Image", l_json.has_substring ("alpine:latest"))
			assert ("has Env", l_json.has_substring ("FOO=bar"))
		end

feature -- Test: Container State

	test_state_constants
			-- Test state constants.
		local
			l_state: CONTAINER_STATE
		do
			create l_state
			assert ("created is valid", l_state.is_valid_state (l_state.created))
			assert ("running is valid", l_state.is_valid_state (l_state.running))
			assert ("exited is valid", l_state.is_valid_state (l_state.exited))
			assert ("invalid not valid", not l_state.is_valid_state ("invalid"))
		end

	test_state_transitions
			-- Test state transition queries.
		local
			l_state: CONTAINER_STATE
		do
			create l_state
			assert ("can start from created", l_state.can_start (l_state.created))
			assert ("can start from exited", l_state.can_start (l_state.exited))
			assert ("cannot start from running", not l_state.can_start (l_state.running))

			assert ("can stop from running", l_state.can_stop (l_state.running))
			assert ("cannot stop from exited", not l_state.can_stop (l_state.exited))

			assert ("can remove from exited", l_state.can_remove (l_state.exited))
			assert ("cannot remove from running", not l_state.can_remove (l_state.running))
		end

feature -- Test: Docker Error

	test_error_creation
			-- Test error creation.
		local
			l_error: DOCKER_ERROR
		do
			create l_error.make (404, "Container not found")
			assert ("code is 404", l_error.status_code = 404)
			assert ("is not found", l_error.is_not_found)
			assert ("not retryable", not l_error.is_retryable)
		end

	test_error_connection
			-- Test connection error.
		local
			l_error: DOCKER_ERROR
		do
			create l_error.make_connection_error ("Cannot connect")
			assert ("is connection error", l_error.is_connection_error)
			assert ("is retryable", l_error.is_retryable)
		end

feature -- Test: Dockerfile Builder (P2)

	test_dockerfile_basic
			-- Test basic Dockerfile generation.
		local
			l_builder: DOCKERFILE_BUILDER
			l_content: STRING
		do
			create l_builder.make ("alpine:latest")
			l_builder.run ("apk add --no-cache curl").do_nothing
			l_builder.cmd_shell ("echo hello").do_nothing

			l_content := l_builder.to_string
			assert ("has FROM", l_content.has_substring ("FROM alpine:latest"))
			assert ("has RUN", l_content.has_substring ("RUN apk add --no-cache curl"))
			assert ("has CMD", l_content.has_substring ("CMD echo hello"))
		end

	test_dockerfile_fluent_api
			-- Test fluent API for Dockerfile.
		local
			l_builder: DOCKERFILE_BUILDER
			l_content: STRING
		do
			create l_builder.make ("node:18-alpine")
			l_builder
				.workdir ("/app")
				.copy_files ("package.json", ".")
				.run ("npm install")
				.copy_files (".", ".")
				.expose (3000)
				.cmd (<<"node", "index.js">>)
				.do_nothing

			l_content := l_builder.to_string
			assert ("has FROM", l_content.has_substring ("FROM node:18-alpine"))
			assert ("has WORKDIR", l_content.has_substring ("WORKDIR /app"))
			assert ("has EXPOSE", l_content.has_substring ("EXPOSE 3000"))
		end

	test_dockerfile_multistage
			-- Test multi-stage build.
		local
			l_builder: DOCKERFILE_BUILDER
			l_content: STRING
		do
			create l_builder.make ("golang:1.21")
			l_builder
				.from_image_as ("golang:1.21", "builder")
				.workdir ("/src")
				.copy_files (".", ".")
				.run ("go build -o app")
				.from_image ("alpine:latest")
				.copy_from ("builder", "/src/app", "/app")
				.cmd (<<"/app">>)
				.do_nothing

			l_content := l_builder.to_string
			assert ("has builder stage", l_content.has_substring ("AS builder"))
			assert ("has COPY --from", l_content.has_substring ("COPY --from=builder"))
		end

	test_dockerfile_labels_and_args
			-- Test labels and build args.
		local
			l_builder: DOCKERFILE_BUILDER
			l_content: STRING
		do
			create l_builder.make ("alpine")
			l_builder
				.label ("maintainer", "test@example.com")
				.label ("version", "1.0")
				.arg ("BUILD_DATE")
				.arg_default ("APP_VERSION", "1.0.0")
				.env ("APP_ENV", "production")
				.do_nothing

			l_content := l_builder.to_string
			assert ("has LABEL", l_content.has_substring ("LABEL"))
			assert ("has ARG", l_content.has_substring ("ARG BUILD_DATE"))
			assert ("has ARG with default", l_content.has_substring ("ARG APP_VERSION=1.0.0"))
			assert ("has ENV", l_content.has_substring ("ENV APP_ENV=production"))
		end

feature -- Test: Docker Network (P2)

	test_network_creation
			-- Test DOCKER_NETWORK creation.
		local
			l_network: DOCKER_NETWORK
		do
			create l_network.make ("abc123def456789012345678901234567890123456789012345678901234")
			assert ("id set", l_network.id.count > 0)
			assert ("short_id is 12 chars", l_network.short_id.count = 12)
			assert ("default driver is bridge", l_network.driver.same_string ("bridge"))
		end

	test_network_queries
			-- Test DOCKER_NETWORK query methods.
		local
			l_network: DOCKER_NETWORK
		do
			create l_network.make ("abc123456789")
			l_network.driver.copy ("bridge")
			l_network.name.copy ("my-network")

			assert ("is bridge", l_network.is_bridge)
			assert ("not host", not l_network.is_host)
			assert ("not default", not l_network.is_default)
			assert ("matches by name", l_network.matches ("my-network"))
		end

	test_list_networks
			-- Test listing networks.
		local
			l_networks: ARRAYED_LIST [DOCKER_NETWORK]
		do
			l_networks := client.list_networks
			assert ("no error", not client.has_error)
			assert ("networks list exists", l_networks /= Void)
			-- Default Docker has at least bridge, host, none
		end

feature -- Test: Docker Volume (P2)

	test_volume_creation
			-- Test DOCKER_VOLUME creation.
		local
			l_volume: DOCKER_VOLUME
		do
			create l_volume.make ("my-data-volume")
			assert ("name set", l_volume.name.same_string ("my-data-volume"))
			assert ("default driver is local", l_volume.driver.same_string ("local"))
			assert ("is local", l_volume.is_local)
		end

	test_volume_anonymous_detection
			-- Test anonymous volume detection.
		local
			l_anon, l_named: DOCKER_VOLUME
		do
			-- 64-char hex name = anonymous volume
			create l_anon.make ("abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789")
			assert ("is anonymous", l_anon.is_anonymous)

			create l_named.make ("my-volume")
			assert ("not anonymous", not l_named.is_anonymous)
		end

	test_list_volumes
			-- Test listing volumes.
		local
			l_volumes: ARRAYED_LIST [DOCKER_VOLUME]
		do
			l_volumes := client.list_volumes
			assert ("no error", not client.has_error)
			assert ("volumes list exists", l_volumes /= Void)
		end

feature -- Test: Exec Operations (P2)

	test_exec_in_container
			-- Test executing command in container.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_output: detachable STRING
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("exec_test"))
				.set_cmd (<<"sleep", "30">>).do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))
				l_output := client.exec_in_container (c.id, <<"echo", "hello from exec">>)
				assert ("exec output returned: " + client_error_text, attached l_output)
				if attached l_output as al_output then
					-- Output carries stream frame headers; check the text itself
					assert ("exec output has the echoed text", al_output.has_substring ("hello from exec"))
				end
				if client.stop_container (c.id, 1) then end
				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

feature -- Test: Network Operations (P2)

	test_create_and_remove_network
			-- Test network create/remove cycle.
		local
			l_network: detachable DOCKER_NETWORK
			l_name: STRING
		do
			l_name := unique_test_name ("test_net")
			l_network := client.create_network (l_name, "bridge")
			assert ("network created: " + client_error_text, attached l_network)
			if attached l_network as n then
				test_network_id := n.id
				assert ("network id", n.id.count > 0)
				assert ("network found", attached client.get_network (l_name) as fetched and then fetched.name.same_string (l_name))
				assert ("network removed", client.remove_network (n.id))
				test_network_id := Void
			end
		end

feature -- Test: Volume Operations (P2)

	test_create_and_remove_volume
			-- Test volume create/remove cycle.
		local
			l_volume: detachable DOCKER_VOLUME
			l_name: STRING
		do
			l_name := unique_test_name ("test_vol")
			l_volume := client.create_volume (l_name)
			assert ("volume created: " + client_error_text, attached l_volume)
			if attached l_volume as v then
				test_volume_name := l_name
				assert ("volume name", v.name.same_string (l_name))
				assert ("driver is local", v.is_local)
				assert ("volume found", attached client.get_volume (l_name) as fetched and then fetched.name.same_string (l_name))
				assert ("volume removed", client.remove_volume (l_name, False))
				test_volume_name := Void
			end
		end

feature -- Test: Cookbook Verification (dogfooding)
	-- These tests verify that every feature claimed in cookbook.html actually works.
	-- USAF principle: "7 different ways, 7 different times"

	test_cookbook_spec_add_port
			-- Verify CONTAINER_SPEC.add_port from Recipe 1, 2.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("nginx:alpine")
			l_spec.add_port (80, 8080).do_nothing
			l_spec.add_port (443, 8443).do_nothing

			l_json := l_spec.to_json
			assert ("port mapping in JSON", l_json.has_substring ("8080"))
			assert ("has ExposedPorts", l_json.has_substring ("ExposedPorts"))
		end

	test_cookbook_spec_add_volume
			-- Verify CONTAINER_SPEC.add_volume from Recipe 1, 2.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("nginx:alpine")
			l_spec.add_volume ("/host/path", "/container/path").do_nothing

			l_json := l_spec.to_json
			assert ("volume in JSON", l_json.has_substring ("/host/path"))
			assert ("has Binds", l_json.has_substring ("Binds"))
		end

	test_cookbook_spec_restart_policy
			-- Verify CONTAINER_SPEC.set_restart_policy from Recipe 1, 2.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("nginx:alpine")
			l_spec.set_restart_policy ("unless-stopped").do_nothing

			l_json := l_spec.to_json
			assert ("restart policy in JSON", l_json.has_substring ("unless-stopped"))
			assert ("has RestartPolicy", l_json.has_substring ("RestartPolicy"))
		end

	test_cookbook_spec_hostname
			-- Verify CONTAINER_SPEC.set_hostname from Recipe 2.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("postgres:16-alpine")
			l_spec.set_hostname ("postgres-server").do_nothing

			l_json := l_spec.to_json
			assert ("hostname in JSON", l_json.has_substring ("postgres-server"))
			assert ("has Hostname key", l_json.has_substring ("Hostname"))
		end

	test_cookbook_spec_memory_limit
			-- Verify CONTAINER_SPEC.set_memory_limit from Recipe 2.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("postgres:16-alpine")
			l_spec.set_memory_limit (1024 * 1024 * 1024).do_nothing -- 1 GB

			l_json := l_spec.to_json
			assert ("has Memory", l_json.has_substring ("Memory"))
			-- Memory value should be 1073741824
			assert ("memory value present", l_json.has_substring ("1073741824"))
		end

	test_cookbook_spec_auto_remove
			-- Verify CONTAINER_SPEC.set_auto_remove from Recipe 3.
		local
			l_spec: CONTAINER_SPEC
			l_json: STRING
		do
			create l_spec.make ("alpine:latest")
			l_spec.set_auto_remove (True).do_nothing

			l_json := l_spec.to_json
			assert ("has AutoRemove", l_json.has_substring ("AutoRemove"))
			assert ("auto_remove true", l_json.has_substring ("true"))
		end

	test_cookbook_container_exit_code
			-- Verify DOCKER_CONTAINER.exit_code from Recipe 5.
		local
			l_container: DOCKER_CONTAINER
			l_parser: SIMPLE_JSON
			l_json_str: STRING
		do
			-- Create container from JSON with exit code
			l_json_str := "{%"Id%":%"abc123def456%",%"State%":{%"Status%":%"exited%",%"ExitCode%":42}}"

			create l_parser
			if attached l_parser.parse (l_json_str) as p and then p.is_object then
				create l_container.make_from_json (p.as_object)
				assert ("exit code is 42", l_container.exit_code = 42)
				assert ("has_exited_successfully false", not l_container.has_exited_successfully)
			else
				assert ("JSON parsed", False)
			end
		end

	test_cookbook_container_is_dead
			-- Verify DOCKER_CONTAINER.is_dead from Recipe 5.
		local
			l_container: DOCKER_CONTAINER
			l_parser: SIMPLE_JSON
			l_json_str: STRING
		do
			-- Create container from JSON with dead state
			l_json_str := "{%"Id%":%"abc123def456%",%"State%":{%"Status%":%"dead%"}}"

			create l_parser
			if attached l_parser.parse (l_json_str) as p and then p.is_object then
				create l_container.make_from_json (p.as_object)
				assert ("is_dead true", l_container.is_dead)
				assert ("not running", not l_container.is_running)
			else
				assert ("JSON parsed", False)
			end
		end

	test_cookbook_image_primary_tag
			-- Verify DOCKER_IMAGE.primary_tag from Recipe 6.
		local
			l_image: DOCKER_IMAGE
			l_parser: SIMPLE_JSON
			l_json_str: STRING
		do
			-- Image with tags
			l_json_str := "{%"Id%":%"sha256:abc123%",%"RepoTags%":[%"nginx:latest%",%"nginx:1.25%"]}"

			create l_parser
			if attached l_parser.parse (l_json_str) as p and then p.is_object then
				create l_image.make_from_json (p.as_object)
				if attached l_image.primary_tag as pt then
					assert ("primary_tag is first", pt.same_string ("nginx:latest"))
				else
					assert ("has primary tag", False)
				end
			else
				assert ("JSON parsed for image", False)
			end

			-- Dangling image (no tags)
			l_json_str := "{%"Id%":%"sha256:def456%",%"RepoTags%":[]}"

			create l_parser
			if attached l_parser.parse (l_json_str) as p2 and then p2.is_object then
				create l_image.make_from_json (p2.as_object)
				if attached l_image.primary_tag as pt2 then
					assert ("dangling has none tag", pt2.has_substring ("<none>"))
				else
					-- No tag is also valid for dangling images
					assert ("no primary tag", True)
				end
			else
				assert ("JSON parsed for dangling", False)
			end
		end

	test_cookbook_error_is_retryable
			-- Verify DOCKER_ERROR.is_retryable from Recipe 7.
		local
			l_connection_err, l_not_found_err, l_unavailable_err: DOCKER_ERROR
		do
			-- Connection errors are retryable
			create l_connection_err.make_connection_error ("Connection refused")
			assert ("connection error retryable", l_connection_err.is_retryable)

			-- 404 Not Found is NOT retryable
			create l_not_found_err.make (404, "Not Found")
			assert ("404 not retryable", not l_not_found_err.is_retryable)

			-- 503 Service Unavailable IS retryable (transient)
			create l_unavailable_err.make (503, "Service Unavailable")
			assert ("503 is retryable", l_unavailable_err.is_retryable)
		end

feature -- Test: Log Stream Options (P3 - Happy Path)

	test_log_stream_options_defaults
			-- Test LOG_STREAM_OPTIONS default values.
		local
			l_options: LOG_STREAM_OPTIONS
		do
			create l_options.make
			assert ("stdout enabled by default", l_options.stdout)
			assert ("stderr enabled by default", l_options.stderr)
			assert ("timestamps disabled by default", not l_options.timestamps)
			assert ("follow enabled by default", l_options.follow)
			assert ("tail is 0 (all)", l_options.tail = 0)
			assert ("timeout is 0 (infinite)", l_options.timeout_ms = 0)
			assert ("options valid", l_options.is_valid)
		end

	test_log_stream_options_fluent_api
			-- Test LOG_STREAM_OPTIONS fluent builder pattern.
		local
			l_options: LOG_STREAM_OPTIONS
		do
			create l_options.make
			l_options
				.set_stdout (True)
				.set_stderr (False)
				.set_timestamps (True)
				.set_follow (False)
				.set_tail (100)
				.set_timeout_ms (5000)
				.do_nothing

			assert ("stdout set", l_options.stdout)
			assert ("stderr disabled", not l_options.stderr)
			assert ("timestamps enabled", l_options.timestamps)
			assert ("follow disabled", not l_options.follow)
			assert ("tail is 100", l_options.tail = 100)
			assert ("timeout is 5000", l_options.timeout_ms = 5000)
			assert ("still valid (stdout enabled)", l_options.is_valid)
		end

	test_log_stream_options_to_query_string
			-- Test LOG_STREAM_OPTIONS query string generation.
		local
			l_options: LOG_STREAM_OPTIONS
			l_query: STRING
		do
			create l_options.make
			l_options
				.set_stdout (True)
				.set_stderr (True)
				.set_timestamps (True)
				.set_follow (True)
				.set_tail (50)
				.do_nothing

			l_query := l_options.to_query_string

			assert ("has stdout=true", l_query.has_substring ("stdout=true"))
			assert ("has stderr=true", l_query.has_substring ("stderr=true"))
			assert ("has timestamps=true", l_query.has_substring ("timestamps=true"))
			assert ("has follow=true", l_query.has_substring ("follow=true"))
			assert ("has tail=50", l_query.has_substring ("tail=50"))
		end

	test_log_stream_options_no_tail_in_query
			-- Test that tail=0 is not included in query string.
		local
			l_options: LOG_STREAM_OPTIONS
			l_query: STRING
		do
			create l_options.make  -- tail=0 by default
			l_query := l_options.to_query_string

			assert ("no tail param when 0", not l_query.has_substring ("tail="))
		end

	test_stream_container_logs_happy_path
			-- Follow the logs of a running container: all three lines arrive in
			-- order, the stream ends when the container exits, and the shared
			-- connection still answers its own requests afterwards.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_options: LOG_STREAM_OPTIONS
			l_log_lines: ARRAYED_LIST [STRING]
			l_callback: FUNCTION [TUPLE [STRING, INTEGER], BOOLEAN]
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("stream_test"))
				.set_cmd (<<"sh", "-c", "echo 'line1' && echo 'line2' && echo 'line3' && sleep 1">>)
				.do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))

				create l_options.make
				l_options.set_follow (True).set_timeout_ms (10_000).do_nothing
				create l_log_lines.make (10)
				l_callback := agent (a_line: STRING; a_type: INTEGER; a_lines: ARRAYED_LIST [STRING]): BOOLEAN
					do
						a_lines.extend (a_line)
						Result := True  -- Continue streaming
					end (?, ?, l_log_lines)

				client.stream_container_logs (c.id, l_options, l_callback)

				assert ("no error: " + client_error_text, not client.has_error)
				assert ("three lines, got " + l_log_lines.count.out, l_log_lines.count = 3)
				assert ("line1 first", l_log_lines.count = 3 and then l_log_lines.i_th (1).same_string ("line1"))
				assert ("line2 second", l_log_lines.count = 3 and then l_log_lines.i_th (2).same_string ("line2"))
				assert ("line3 third", l_log_lines.count = 3 and then l_log_lines.i_th (3).same_string ("line3"))
				assert ("shared connection in step", connection_in_step (c.id))

				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

feature -- Test: Log Stream Edge Cases (P3)

	test_log_stream_options_invalid
			-- Test LOG_STREAM_OPTIONS with neither stdout nor stderr.
		local
			l_options: LOG_STREAM_OPTIONS
		do
			create l_options.make
			l_options
				.set_stdout (False)
				.set_stderr (False)
				.do_nothing

			assert ("options invalid", not l_options.is_valid)
		end

	test_stream_logs_nonexistent_container
			-- Streaming logs of a container that does not exist reports
			-- not-found and never calls the callback.
		local
			l_options: LOG_STREAM_OPTIONS
			l_called: CELL [BOOLEAN]
			l_callback: FUNCTION [TUPLE [STRING, INTEGER], BOOLEAN]
		do
			create l_options.make
			l_options.set_follow (False).set_timeout_ms (5_000).do_nothing

			create l_called.put (False)
			l_callback := agent (a_line: STRING; a_type: INTEGER; a_called: CELL [BOOLEAN]): BOOLEAN
				do
					a_called.put (True)
					Result := True
				end (?, ?, l_called)

			client.stream_container_logs ("simple_docker_nonexistent_" + run_tag, l_options, l_callback)

			assert ("error reported", client.has_error)
			assert ("error is not-found: " + client_error_text, attached client.last_error as e and then e.is_not_found)
			assert ("callback never called", not l_called.item)
		end

	test_stream_logs_callback_stops_streaming
			-- A callback returning False stops the stream at once: of ten
			-- lines, exactly three are delivered.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_options: LOG_STREAM_OPTIONS
			l_count: CELL [INTEGER]
			l_callback: FUNCTION [TUPLE [STRING, INTEGER], BOOLEAN]
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("stop_test"))
				.set_cmd (<<"sh", "-c", "for i in 1 2 3 4 5 6 7 8 9 10; do echo line$i; done && sleep 1">>)
				.do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))

				create l_options.make
				l_options.set_follow (True).set_timeout_ms (10_000).do_nothing

				create l_count.put (0)
				l_callback := agent (a_line: STRING; a_type: INTEGER; a_count: CELL [INTEGER]): BOOLEAN
					do
						a_count.put (a_count.item + 1)
						Result := a_count.item < 3  -- Stop after 3 lines
					end (?, ?, l_count)

				client.stream_container_logs (c.id, l_options, l_callback)

				assert ("no error: " + client_error_text, not client.has_error)
				assert ("stopped after three lines, got " + l_count.item.out, l_count.item = 3)
				assert ("shared connection in step", connection_in_step (c.id))

				if client.stop_container (c.id, 1) then end
				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

	test_stream_logs_stopped_container
			-- Logs of an exited container can be read without following.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_options: LOG_STREAM_OPTIONS
			l_log_lines: ARRAYED_LIST [STRING]
			l_callback: FUNCTION [TUPLE [STRING, INTEGER], BOOLEAN]
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("stopped_test"))
				.set_cmd (<<"echo", "stopped container output">>)
				.do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))
				assert ("container exited 0", client.wait_container (c.id) = 0)

				create l_options.make
				l_options.set_follow (False).set_timeout_ms (5_000).do_nothing
				create l_log_lines.make (10)
				l_callback := agent (a_line: STRING; a_type: INTEGER; a_lines: ARRAYED_LIST [STRING]): BOOLEAN
					do
						a_lines.extend (a_line)
						Result := True
					end (?, ?, l_log_lines)

				client.stream_container_logs (c.id, l_options, l_callback)

				assert ("no error for stopped container: " + client_error_text, not client.has_error)
				assert ("one line, got " + l_log_lines.count.out, l_log_lines.count = 1)
				assert ("the echoed line", l_log_lines.count = 1 and then l_log_lines.first.same_string ("stopped container output"))
				assert ("shared connection in step", connection_in_step (c.id))

				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

	test_stream_logs_timeout_behavior
			-- Following a silent container ends cleanly after the timeout.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_options: LOG_STREAM_OPTIONS
			l_count: CELL [INTEGER]
			l_callback: FUNCTION [TUPLE [STRING, INTEGER], BOOLEAN]
		do
			ensure_alpine
			create l_spec.make ("alpine:latest")
			l_spec.set_name (unique_test_name ("timeout_test"))
				.set_cmd (<<"sleep", "60">>)
				.do_nothing

			l_container := client.create_container (l_spec)
			assert ("container created: " + client_error_text, attached l_container)
			if attached l_container as c then
				test_container_id := c.id
				assert ("container started", client.start_container (c.id))

				create l_options.make
				l_options.set_follow (True).set_timeout_ms (500).do_nothing
				create l_count.put (0)
				l_callback := agent (a_line: STRING; a_type: INTEGER; a_count: CELL [INTEGER]): BOOLEAN
					do
						a_count.put (a_count.item + 1)
						Result := True
					end (?, ?, l_count)

				-- This should time out after ~500ms of silence
				client.stream_container_logs (c.id, l_options, l_callback)

				assert ("streaming timed out cleanly: " + client_error_text, not client.has_error)
				assert ("no lines from a silent container", l_count.item = 0)
				assert ("shared connection in step", connection_in_step (c.id))

				if client.stop_container (c.id, 1) then end
				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			end
		end

feature -- Test: SIMPLE_DOCKER_QUICK (Happy Path)

	test_quick_is_available
			-- Test SIMPLE_DOCKER_QUICK availability check.
		local
			l_quick: SIMPLE_DOCKER_QUICK
		do
			create l_quick.make
			-- Docker should be running for tests
			assert ("docker is available", l_quick.is_available)
			assert ("no initial error", not l_quick.has_error)
			assert ("empty error message", l_quick.last_error_message.is_empty)
		end

	test_quick_run_script
			-- run_script returns the script's output and leaves no container.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_output: STRING
		do
			create l_quick.make
			l_output := l_quick.run_script ("echo 'Hello from Quick!'")
			assert ("no error: " + l_quick.last_error_message, not l_quick.has_error)
			assert ("output not empty", not l_output.is_empty)
			assert ("contains hello", l_output.has_substring ("Hello from Quick!"))
			assert ("no containers tracked", l_quick.container_count = 0)
		end

	test_quick_redis
			-- Test starting Redis cache.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_container: detachable DOCKER_CONTAINER
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_quick.make
			active_quick := l_quick
			l_container := l_quick.redis
			assert ("redis started: " + l_quick.last_error_message, attached l_container)
			if attached l_container as c then
				assert ("redis id", c.id.count > 0)
				assert ("container tracked", l_quick.container_count = 1)

				-- Cleanup and wait for Docker state to settle
				l_quick.cleanup
				create l_env
				l_env.sleep (5_000_000_000) -- 5 second delay for Docker daemon cleanup
				assert ("cleaned up", l_quick.container_count = 0)
			end
			active_quick := Void
		end

	test_quick_postgres
			-- Test starting PostgreSQL database.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_container: detachable DOCKER_CONTAINER
		do
			create l_quick.make
			active_quick := l_quick
			l_container := l_quick.postgres ("testpassword123")
			assert ("postgres started: " + l_quick.last_error_message, attached l_container)
			if attached l_container as c then
				assert ("postgres id", c.id.count > 0)
				assert ("container tracked", l_quick.container_count = 1)
				l_quick.cleanup
				assert ("cleaned up", l_quick.container_count = 0)
			end
			active_quick := Void
		end

	test_quick_cleanup
			-- Test cleanup removes all tracked containers.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_ignore: detachable DOCKER_CONTAINER
		do
			create l_quick.make
			active_quick := l_quick
			l_ignore := l_quick.redis
			assert ("first redis started: " + l_quick.last_error_message, attached l_ignore)
			l_ignore := l_quick.redis_on_port (6380)
			assert ("second redis started: " + l_quick.last_error_message, attached l_ignore)
			assert ("two containers running", l_quick.container_count = 2)

			l_quick.cleanup
			assert ("all cleaned up", l_quick.container_count = 0)
			active_quick := Void
		end

feature -- Test: SIMPLE_DOCKER_QUICK (Edge Cases)

	test_quick_client_access
			-- Test access to underlying client.
		local
			l_quick: SIMPLE_DOCKER_QUICK
		do
			create l_quick.make
			assert ("client accessible", l_quick.client /= Void)
			assert ("client works", l_quick.client.ping)
		end

	test_quick_empty_script
			-- A script that prints nothing gives empty output and no error.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_output: STRING
		do
			create l_quick.make
			l_output := l_quick.run_script ("true")  -- Does nothing, exits 0
			assert ("no error: " + l_quick.last_error_message, not l_quick.has_error)
			assert ("empty output", l_output.is_empty)
		end

	test_quick_failing_script
			-- A failing script's output reports its exit code.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_output: STRING
		do
			create l_quick.make
			l_output := l_quick.run_script ("exit 42")
			assert ("no error: " + l_quick.last_error_message, not l_quick.has_error)
			assert ("reports exit code 42, got: " + l_output, l_output.has_substring ("[Exit code: 42]"))
		end

	test_quick_stop_all
			-- Test stop_all stops containers without removing.
		local
			l_quick: SIMPLE_DOCKER_QUICK
			l_container: detachable DOCKER_CONTAINER
		do
			create l_quick.make
			active_quick := l_quick
			l_container := l_quick.redis
			assert ("redis started: " + l_quick.last_error_message, attached l_container)
			if attached l_container as c then
				l_quick.stop_all
				-- Containers still tracked (not removed)
				assert ("still tracked after stop", l_quick.container_count = 1)
				assert ("stopped", attached client.get_container (c.id) as al_c and then not al_c.is_running)
				l_quick.cleanup
				assert ("cleaned up", l_quick.container_count = 0)
			end
			active_quick := Void
		end

end
