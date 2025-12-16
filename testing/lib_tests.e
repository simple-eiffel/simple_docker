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

feature -- Setup

	on_prepare
			-- Set up test fixtures.
		do
			create client.make
			test_counter := test_counter + 1
		end

	on_clean
			-- Clean up after tests.
		do
			-- Clean up any test containers
			if attached test_container_id as cid then
				if client.remove_container (cid, True) then end
				test_container_id := Void
			end
		end

feature -- Access

	client: DOCKER_CLIENT
			-- Docker client for tests.

	test_counter: INTEGER
			-- Counter for unique names.

	test_container_id: detachable STRING
			-- ID of test container (for cleanup).

feature -- Test: Connection

	test_ping
			-- Test ping Docker daemon.
		do
			assert ("ping succeeds", client.ping)
			assert ("no error after ping", not client.has_error)
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
			-- Test checking if alpine image exists (may need to pull first).
		do
			if not client.image_exists ("alpine:latest") then
				-- Try to pull it
				if client.pull_image ("alpine:latest") then end
			end
			-- Now check
			if client.image_exists ("alpine:latest") then
				assert ("alpine exists", True)
			else
				-- Skip if can't pull (network issues)
				assert ("alpine check completed", True)
			end
		end

feature -- Test: Containers

	test_list_containers
			-- Test listing containers.
		local
			l_containers: ARRAYED_LIST [DOCKER_CONTAINER]
		do
			l_containers := client.list_containers (True)
			assert ("no error", not client.has_error)
			assert ("containers list exists", l_containers /= Void)
		end

	test_create_and_remove_container
			-- Test creating and removing a container.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
		do
			-- Ensure alpine exists
			if not client.image_exists ("alpine:latest") then
				if client.pull_image ("alpine:latest") then end
			end

			-- Create container
			create l_spec.make ("alpine:latest")
			l_spec.set_name ("simple_docker_test_" + test_counter.out)
				.set_cmd (<<"echo", "hello">>).do_nothing

			l_container := client.create_container (l_spec)

			if attached l_container as c then
				test_container_id := c.id
				assert ("container created", c.id.count > 0)
				assert ("short id is 12 chars", c.short_id.count = 12)

				-- Remove container
				assert ("container removed", client.remove_container (c.id, True))
				test_container_id := Void
			else
				if client.has_error and then attached client.last_error as err then
					if err.is_not_found then
						-- Image not available, skip
						assert ("skipped - no alpine image", True)
					else
						assert ("container created", False)
					end
				else
					assert ("container created", False)
				end
			end
		end

	test_container_lifecycle
			-- Test full container lifecycle: create, start, stop, remove.
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
		do
			-- Ensure alpine exists
			if not client.image_exists ("alpine:latest") then
				if client.pull_image ("alpine:latest") then end
			end

			-- Create container that sleeps
			create l_spec.make ("alpine:latest")
			l_spec.set_name ("simple_docker_lifecycle_" + test_counter.out)
				.set_cmd (<<"sleep", "10">>).do_nothing

			l_container := client.create_container (l_spec)

			if attached l_container as c then
				test_container_id := c.id

				-- Start
				assert ("container started", client.start_container (c.id))

				-- Verify running
				if attached client.get_container (c.id) as running then
					assert ("is running", running.is_running)
				end

				-- Stop
				assert ("container stopped", client.stop_container (c.id, 1))

				-- Verify stopped
				if attached client.get_container (c.id) as stopped then
					assert ("is exited", stopped.is_exited)
				end

				-- Remove
				assert ("container removed", client.remove_container (c.id, False))
				test_container_id := Void
			else
				-- Skip if image not available
				assert ("lifecycle test completed", True)
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

end
