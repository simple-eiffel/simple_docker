note
	description: "System-level test fixture for simple_docker - manages Docker daemon connection and image availability"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_TEST_SYSTEM

feature -- System Initialization

	on_prepare_test_system
			-- Prepare test system: connect to Docker and ensure base images available.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_retry_count: INTEGER
		do
			-- Reuse client to avoid IPC connection overhead
			if not attached shared_client then
				create l_env
				l_env.sleep (100_000_000) -- 100ms initial delay for Docker daemon
				create shared_client.make
				ensure_alpine_available
			end
		rescue
			-- Retry on IPC connection failures
			l_retry_count := l_retry_count + 1
			if l_retry_count <= 3 then
				create l_env
				l_env.sleep (200_000_000) -- 200ms retry delay
				retry
			end
		end

	on_clean_test_system
			-- Clean up test system: disconnect from Docker.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			-- Small delay to allow IPC pipe to settle
			create l_env
			l_env.sleep (50_000_000) -- 50ms
		end

	is_initialized: BOOLEAN
			-- Check if Docker connection is established and ready.
		do
			Result := attached shared_client and then attached shared_client.ping
		end

feature -- Shared Resources

	shared_client: detachable DOCKER_CLIENT
			-- Shared Docker client reused across all tests to minimize IPC overhead.

feature {NONE} -- Implementation

	ensure_alpine_available
			-- Ensure alpine:latest image is available for tests.
		do
			if attached shared_client as sc then
				if not sc.image_exists ("alpine:latest") then
					if sc.pull_image ("alpine:latest") then
						-- Image pulled successfully
					end
				end
			end
		end

end
