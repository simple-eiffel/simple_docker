note
	description: "Three-tier fixture hierarchy for simple_docker container tests"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	CONTAINER_FIXTURES

inherit
	TEST_SET_BASE

feature -- Initialization

	set_client (a_client: DOCKER_CLIENT)
			-- Set the Docker client for fixture operations.
		do
			client := a_client
		end

feature -- Tier 1: Spec Creation

	alpine_spec_echo: CONTAINER_SPEC
			-- Simple Alpine container that echoes and exits.
		once
			create Result.make ("alpine:latest")
			Result := Result.set_name ("simple_docker_test_echo")
			Result := Result.set_cmd (<<"echo", "hello">>)
		ensure
			spec_created: Result /= Void
			has_image: Result.image.same_string ("alpine:latest")
		end

	alpine_spec_sleep: CONTAINER_SPEC
			-- Alpine container that sleeps (for lifecycle tests).
		once
			create Result.make ("alpine:latest")
			Result := Result.set_name ("simple_docker_test_sleep")
			Result := Result.set_cmd (<<"sleep", "30">>)
		ensure
			spec_created: Result /= Void
			sleep_cmd_set: Result /= Void
		end

	nginx_spec: CONTAINER_SPEC
			-- Nginx container specification.
		once
			create Result.make ("nginx:alpine")
			Result := Result.set_name ("simple_docker_test_nginx")
		ensure
			spec_created: Result /= Void
			has_nginx_image: Result.image.same_string ("nginx:alpine")
		end

feature -- Tier 2: Created Containers

	echo_container: detachable DOCKER_CONTAINER
			-- Container created from echo spec (requires client to be set).
		do
			if not attached l_echo_container_cache then
				if attached client as c then
					l_echo_container_cache := c.create_container (alpine_spec_echo)
				end
			end
			Result := l_echo_container_cache
		ensure
			container_created: attached Result or not attached client
		end

	sleep_container: detachable DOCKER_CONTAINER
			-- Running container that sleeps.
		local
			l_spec: CONTAINER_SPEC
		do
			if not attached l_sleep_container_cache then
				if attached client as c then
					create l_spec.make ("alpine:latest")
					l_spec := l_spec.set_name ("simple_docker_fixture_sleep")
					l_spec := l_spec.set_cmd (<<"sleep", "30">>)
					l_sleep_container_cache := c.create_container (l_spec)
					if attached l_sleep_container_cache as container then
						if c.start_container (container.id) then
							-- Container started
						end
					end
				end
			end
			Result := l_sleep_container_cache
		ensure
			container_created: attached Result or not attached client
		end

feature -- Tier 3: Container State Verification

	verify_container_exists (a_container_id: STRING): BOOLEAN
			-- Check if container with given ID exists and is accessible.
		do
			if attached client as c then
				Result := c.image_exists (a_container_id)
			end
		end

	cleanup_container (a_container_id: STRING)
			-- Remove container and all associated resources.
		do
			if attached client as c then
				-- Try to stop container (harmless if already stopped)
				if c.stop_container (a_container_id, 1) then
					-- Stopped successfully
				end
				-- Remove container and all associated resources
				if c.remove_container (a_container_id, True) then
					-- Removed successfully
				end
			end
		end

feature {NONE} -- Implementation

	client: detachable DOCKER_CLIENT
			-- Docker client reference for operations.

	l_echo_container_cache: detachable DOCKER_CONTAINER
			-- Cached echo container instance.

	l_sleep_container_cache: detachable DOCKER_CONTAINER
			-- Cached sleep container instance.

end
