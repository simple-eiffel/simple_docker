note
	description: "[
		Docker Engine API client.

		Main facade for Docker operations. Communicates with Docker daemon
		via named pipe (Windows) or Unix socket (Linux/macOS).

		Usage:
			create client.make
			if client.is_connected then
				containers := client.list_containers (True)
				images := client.list_images

				-- Create and run a container
				create spec.make ("nginx:alpine")
				spec.set_name ("my-nginx").add_port (80, 8080)
				container := client.create_container (spec)
				client.start_container (container.id)
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_CLIENT

create
	make,
	make_with_endpoint

feature {NONE} -- Initialization

	make
			-- Create client with default Docker endpoint.
			-- Uses rescue/retry for transient IPC connection failures.
		local
			l_retry_count: INTEGER
			l_env: EXECUTION_ENVIRONMENT
		do
			if {PLATFORM}.is_windows then
				endpoint := default_windows_endpoint
			else
				endpoint := default_unix_endpoint
			end
			api_version := default_api_version
			create connection.make_client (endpoint)
			buffer_size := default_buffer_size
			create logger.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			logger.add_context ("component", "docker_client")
		ensure
			endpoint_set: not endpoint.is_empty
			api_version_set: not api_version.is_empty
			connection_exists: connection /= Void
			logger_exists: logger /= Void
		rescue
			-- Retry on IPC connection failures
			l_retry_count := l_retry_count + 1
			if l_retry_count <= default_retry_count then
				-- Delay before retry
				create l_env
				l_env.sleep (default_retry_delay_ms * 1_000_000)
				retry
			end
		end

	make_with_endpoint (a_endpoint: STRING)
			-- Create client with custom `a_endpoint'.
			-- Uses rescue/retry for transient IPC connection failures.
		require
			endpoint_not_empty: not a_endpoint.is_empty
		local
			l_retry_count: INTEGER
			l_env: EXECUTION_ENVIRONMENT
		do
			endpoint := a_endpoint
			api_version := default_api_version
			create connection.make_client (a_endpoint)
			buffer_size := default_buffer_size
			create logger.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			logger.add_context ("component", "docker_client")
			logger.add_context ("endpoint", a_endpoint)
		ensure
			endpoint_set: endpoint.same_string (a_endpoint)
			api_version_set: not api_version.is_empty
			connection_exists: connection /= Void
			logger_exists: logger /= Void
		rescue
			-- Retry on IPC connection failures
			l_retry_count := l_retry_count + 1
			if l_retry_count <= default_retry_count then
				-- Delay before retry
				create l_env
				l_env.sleep (default_retry_delay_ms * 1_000_000)
				retry
			end
		end

feature -- Constants

	default_windows_endpoint: STRING = "docker_engine"
			-- Default Windows named pipe name (\\.\pipe\docker_engine).

	default_unix_endpoint: STRING = "/var/run/docker.sock"
			-- Default Unix socket path.

	default_api_version: STRING = "1.41"
			-- Default Docker API version.

	default_buffer_size: INTEGER = 65536
			-- Default read buffer size.

	default_retry_count: INTEGER = 3
			-- Default number of retries for IPC operations.

	default_retry_delay_ms: INTEGER = 100
			-- Default delay between retries in milliseconds.

feature -- Access

	endpoint: STRING
			-- Docker daemon endpoint.

	api_version: STRING
			-- Docker API version being used.

	buffer_size: INTEGER
			-- Read buffer size.

	last_error: detachable DOCKER_ERROR
			-- Error from last failed operation.

	logger: SIMPLE_LOGGER
			-- Logger for diagnostic output.

feature -- Status

	is_connected: BOOLEAN
			-- Is client connected to Docker daemon?
		do
			Result := connection.is_valid
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Connection

	ping: BOOLEAN
			-- Ping Docker daemon. Returns True if responsive.
		local
			l_response: STRING
		do
			last_error := Void
			logger.debug_log ("Sending ping request")
			-- Note: /_ping is a special endpoint that doesn't use API version prefix
			l_response := do_raw_request ("GET", "/_ping", Void)
			logger.debug_log ("Ping response length: " + l_response.count.out)
			if not has_error then
				l_response.left_adjust
				l_response.right_adjust
				Result := l_response.same_string ("OK") or else l_response.starts_with ("OK")
				if Result then
					logger.debug_log ("Docker daemon is responsive")
				else
					logger.warn ("Unexpected ping response: " + l_response)
				end
			else
				if attached last_error as e then
					logger.error ("Ping failed: " + e.out)
				end
			end
		ensure
			error_implies_false: has_error implies not Result
		end

	version: detachable SIMPLE_JSON_OBJECT
			-- Get Docker version information.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			logger.debug_log ("Requesting Docker version")
			l_response := do_request ("GET", "/version", Void)
			logger.debug_log ("Version response length: " + l_response.count.out)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					Result := v.as_object
					logger.debug_log ("Version info retrieved successfully")
				else
					logger.error ("Failed to parse version JSON response")
				end
			end
		ensure
			error_or_result: not has_error implies (Result /= Void or else True)
		end

	info: detachable SIMPLE_JSON_OBJECT
			-- Get Docker system information.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			logger.debug_log ("Requesting Docker system info")
			l_response := do_request ("GET", "/info", Void)
			logger.debug_log ("Info response length: " + l_response.count.out)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					Result := v.as_object
					logger.debug_log ("System info retrieved successfully")
				else
					logger.error ("Failed to parse info JSON response")
				end
			end
		ensure
			error_or_result: not has_error implies (Result /= Void or else True)
		end

feature -- Container Operations

	list_containers (a_all: BOOLEAN): ARRAYED_LIST [DOCKER_CONTAINER]
			-- List containers. If `a_all', include stopped containers.
		local
			l_path: STRING
			l_response: STRING
			l_json: SIMPLE_JSON
			l_array: SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			last_error := Void
			create Result.make (20)

			l_path := "/containers/json"
			if a_all then
				l_path.append ("?all=true")
			end

			l_response := do_request ("GET", l_path, Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_array then
					l_array := v.as_array
					from i := 1 until i > l_array.count loop
						if attached l_array.object_item (i) as obj then
							Result.extend (create {DOCKER_CONTAINER}.make_from_json (obj))
						end
						i := i + 1
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

	get_container (a_id: STRING): detachable DOCKER_CONTAINER
			-- Get container by ID or name.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			l_response := do_request ("GET", "/containers/" + a_id + "/json", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					create Result.make_from_json (v.as_object)
				end
			end
		end

	create_container (a_spec: CONTAINER_SPEC): detachable DOCKER_CONTAINER
			-- Create a new container from spec.
		require
			spec_not_void: a_spec /= Void
		local
			l_path: STRING
			l_body: STRING
			l_response: STRING
			l_json: SIMPLE_JSON
			l_id: detachable STRING_32
		do
			last_error := Void

			l_path := "/containers/create"
			if attached a_spec.name as n then
				l_path.append ("?name=" + n)
			end

			l_body := a_spec.to_json
			l_response := do_request ("POST", l_path, l_body)

			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					l_id := v.as_object.string_item ("Id")
					if attached l_id as lid then
						create Result.make (lid.to_string_8)
						if attached a_spec.name as n then
							Result.names.extend ("/" + n)
						end
						Result.image := a_spec.image
					end
				end
			end
		end

	start_container (a_id: STRING): BOOLEAN
			-- Start a stopped container.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("POST", "/containers/" + a_id + "/start", Void)
			Result := not has_error
		end

	stop_container (a_id: STRING; a_timeout: INTEGER): BOOLEAN
			-- Stop a running container with timeout in seconds.
		require
			id_not_empty: not a_id.is_empty
			non_negative_timeout: a_timeout >= 0
		local
			l_path: STRING
			l_response: STRING
		do
			last_error := Void
			l_path := "/containers/" + a_id + "/stop"
			if a_timeout > 0 then
				l_path.append ("?t=" + a_timeout.out)
			end
			l_response := do_request ("POST", l_path, Void)
			Result := not has_error
		end

	restart_container (a_id: STRING; a_timeout: INTEGER): BOOLEAN
			-- Restart a container.
		require
			id_not_empty: not a_id.is_empty
			non_negative_timeout: a_timeout >= 0
		local
			l_path: STRING
			l_response: STRING
		do
			last_error := Void
			l_path := "/containers/" + a_id + "/restart"
			if a_timeout > 0 then
				l_path.append ("?t=" + a_timeout.out)
			end
			l_response := do_request ("POST", l_path, Void)
			Result := not has_error
		end

	kill_container (a_id: STRING): BOOLEAN
			-- Kill a running container.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("POST", "/containers/" + a_id + "/kill", Void)
			Result := not has_error
		end

	pause_container (a_id: STRING): BOOLEAN
			-- Pause a running container.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("POST", "/containers/" + a_id + "/pause", Void)
			Result := not has_error
		end

	unpause_container (a_id: STRING): BOOLEAN
			-- Unpause a paused container.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("POST", "/containers/" + a_id + "/unpause", Void)
			Result := not has_error
		end

	remove_container (a_id: STRING; a_force: BOOLEAN): BOOLEAN
			-- Remove a container. If `a_force', remove even if running.
		require
			id_not_empty: not a_id.is_empty
		local
			l_path: STRING
			l_response: STRING
		do
			last_error := Void
			l_path := "/containers/" + a_id
			if a_force then
				l_path.append ("?force=true")
			end
			l_response := do_request ("DELETE", l_path, Void)
			Result := not has_error
		end

	container_logs (a_id: STRING; a_stdout, a_stderr: BOOLEAN; a_tail: INTEGER): detachable STRING
			-- Get container logs.
		require
			id_not_empty: not a_id.is_empty
		local
			l_path: STRING
		do
			last_error := Void
			l_path := "/containers/" + a_id + "/logs?"
			l_path.append ("stdout=" + a_stdout.out.as_lower)
			l_path.append ("&stderr=" + a_stderr.out.as_lower)
			if a_tail > 0 then
				l_path.append ("&tail=" + a_tail.out)
			end
			Result := do_request ("GET", l_path, Void)
			if has_error then
				Result := Void
			end
		end

	wait_container (a_id: STRING): INTEGER
			-- Wait for container to exit. Returns exit code.
		require
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			Result := -1
			l_response := do_request ("POST", "/containers/" + a_id + "/wait", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					Result := v.as_object.integer_item ("StatusCode").to_integer
				end
			end
		end

feature -- Image Operations

	list_images: ARRAYED_LIST [DOCKER_IMAGE]
			-- List all images.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
			l_array: SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			last_error := Void
			create Result.make (50)

			l_response := do_request ("GET", "/images/json", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_array then
					l_array := v.as_array
					from i := 1 until i > l_array.count loop
						if attached l_array.object_item (i) as obj then
							Result.extend (create {DOCKER_IMAGE}.make_from_json (obj))
						end
						i := i + 1
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

	get_image (a_name: STRING): detachable DOCKER_IMAGE
			-- Get image by name or ID.
		require
			name_not_empty: not a_name.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			l_response := do_request ("GET", "/images/" + a_name + "/json", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					create Result.make_from_json (v.as_object)
				end
			end
		end

	image_exists (a_name: STRING): BOOLEAN
			-- Does image `a_name' exist locally?
		require
			name_not_empty: not a_name.is_empty
		do
			last_error := Void
			Result := get_image (a_name) /= Void and not has_error
		end

	pull_image (a_name: STRING): BOOLEAN
			-- Pull image from registry.
		require
			name_not_empty: not a_name.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("POST", "/images/create?fromImage=" + a_name, Void)
			Result := not has_error
		end

	remove_image (a_name: STRING; a_force: BOOLEAN): BOOLEAN
			-- Remove an image.
		require
			name_not_empty: not a_name.is_empty
		local
			l_path: STRING
			l_response: STRING
		do
			last_error := Void
			l_path := "/images/" + a_name
			if a_force then
				l_path.append ("?force=true")
			end
			l_response := do_request ("DELETE", l_path, Void)
			Result := not has_error
		end

	build_image (a_context_path: STRING; a_tag: STRING): BOOLEAN
			-- Build image from Dockerfile in `a_context_path' directory.
			-- Tags the resulting image as `a_tag'.
			-- Requires Dockerfile in the context directory.
		require
			context_path_not_empty: not a_context_path.is_empty
			tag_not_empty: not a_tag.is_empty
		local
			l_archive: SIMPLE_ARCHIVE
			l_tar_path: STRING
			l_tar_data: STRING
			l_file: RAW_FILE
			l_response: STRING
			l_uuid: UUID
			l_uuid_gen: UUID_GENERATOR
		do
			last_error := Void

			-- Generate unique temp tar file name
			create l_uuid_gen
			l_uuid := l_uuid_gen.generate_uuid
			l_tar_path := a_context_path + "/.docker_build_" + l_uuid.out + ".tar"

			-- Create tar archive from context directory
			create l_archive.make
			l_archive.create_archive_from_directory (l_tar_path, a_context_path)

			if attached l_archive.last_error as archive_err then
				-- Archive creation failed
				create last_error.make (500, "Failed to create build context: " + archive_err)
				logger.error ("Failed to create build context tar: " + archive_err)
			else
				-- Read tar file as binary
				create l_file.make_open_read (l_tar_path)
				if l_file.exists and then l_file.is_readable then
					create l_tar_data.make (l_file.count)
					l_file.read_stream (l_file.count)
					l_tar_data := l_file.last_string
					l_file.close

					-- Send build request
					l_response := do_binary_request ("/build?t=" + a_tag, l_tar_data, "application/x-tar")
					Result := not has_error

					-- Log build output for debugging
					if not l_response.is_empty then
						logger.debug_log ("Build response: " + l_response.substring (1, l_response.count.min (500)))
					end
				else
					create last_error.make (500, "Cannot read build context tar file")
					logger.error ("Cannot read tar file: " + l_tar_path)
				end

				-- Clean up temp tar file
				create l_file.make_with_name (l_tar_path)
				if l_file.exists then
					l_file.delete
				end
			end
		end

	build_image_from_dockerfile (a_dockerfile: STRING; a_tag: STRING): BOOLEAN
			-- Build image from a Dockerfile string.
			-- Creates a minimal context with just the Dockerfile.
		require
			dockerfile_not_empty: not a_dockerfile.is_empty
			tag_not_empty: not a_tag.is_empty
		local
			l_temp_dir: DIRECTORY
			l_temp_path: STRING
			l_dockerfile_path: STRING
			l_file: PLAIN_TEXT_FILE
			l_uuid: UUID
			l_uuid_gen: UUID_GENERATOR
			l_env: EXECUTION_ENVIRONMENT
			l_temp_base: detachable STRING
		do
			last_error := Void

			-- Get temp directory from environment
			create l_env
			l_temp_base := l_env.get ("TEMP")
			if l_temp_base = Void then
				l_temp_base := l_env.get ("TMP")
			end
			if l_temp_base = Void then
				l_temp_base := "/tmp"
			end

			-- Create temp directory for build context
			create l_uuid_gen
			l_uuid := l_uuid_gen.generate_uuid
			l_temp_path := l_temp_base + "/docker_build_" + l_uuid.out

			create l_temp_dir.make (l_temp_path)
			l_temp_dir.create_dir

			if l_temp_dir.exists then
				-- Write Dockerfile to temp directory
				l_dockerfile_path := l_temp_path + "/Dockerfile"
				create l_file.make_create_read_write (l_dockerfile_path)
				l_file.put_string (a_dockerfile)
				l_file.close

				-- Build using the temp context
				Result := build_image (l_temp_path, a_tag)

				-- Clean up temp directory
				create l_file.make_with_name (l_dockerfile_path)
				if l_file.exists then
					l_file.delete
				end
				l_temp_dir.delete
			else
				create last_error.make (500, "Failed to create temp build directory")
				logger.error ("Cannot create temp directory: " + l_temp_path)
			end
		end

feature -- Convenience

	run_container (a_spec: CONTAINER_SPEC): detachable DOCKER_CONTAINER
			-- Create and start a container in one call.
		require
			spec_not_void: a_spec /= Void
		do
			Result := create_container (a_spec)
			if attached Result as c and not has_error then
				if not start_container (c.id) then
					Result := Void
				end
			end
		end

feature -- Network Operations

	list_networks: ARRAYED_LIST [DOCKER_NETWORK]
			-- List all networks.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
			l_array: SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			last_error := Void
			create Result.make (10)

			l_response := do_request ("GET", "/networks", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_array then
					l_array := v.as_array
					from i := 1 until i > l_array.count loop
						if attached l_array.object_item (i) as obj then
							Result.extend (create {DOCKER_NETWORK}.make_from_json (obj))
						end
						i := i + 1
					end
				end
			end
		ensure
			result_exists: Result /= Void
			all_networks_valid: across Result as n all n.id /= Void and n.driver /= Void end
		end

	get_network (a_id: STRING): detachable DOCKER_NETWORK
			-- Get network by ID or name.
		require
			id_not_void: a_id /= Void
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			l_response := do_request ("GET", "/networks/" + a_id, Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					create Result.make_from_json (v.as_object)
				end
			end
		ensure
			result_matches_id: attached Result implies Result.matches (a_id)
			result_or_error: Result /= Void xor has_error
		end

	create_network (a_name: STRING; a_driver: STRING): detachable DOCKER_NETWORK
			-- Create a new network with name and driver.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
			driver_not_void: a_driver /= Void
			driver_not_empty: not a_driver.is_empty
		local
			l_body: STRING
			l_response: STRING
			l_json: SIMPLE_JSON
			l_id: detachable STRING_32
		do
			last_error := Void

			-- Build JSON body
			create l_body.make (100)
			l_body.append ("{%"Name%":%"")
			l_body.append (a_name)
			l_body.append ("%",%"Driver%":%"")
			l_body.append (a_driver)
			l_body.append ("%"}")

			l_response := do_request ("POST", "/networks/create", l_body)

			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					l_id := v.as_object.string_item ("Id")
					if attached l_id as lid then
						create Result.make (lid.to_string_8)
						Result.name.copy (a_name)
						Result.driver.copy (a_driver)
					end
				end
			end
		ensure
			result_matches_name: attached Result implies Result.name.same_string (a_name)
			result_matches_driver: attached Result implies Result.driver.same_string (a_driver)
			result_or_error: Result /= Void xor has_error
		end

	remove_network (a_id: STRING): BOOLEAN
			-- Remove a network by ID or name.
		require
			id_not_void: a_id /= Void
			id_not_empty: not a_id.is_empty
		local
			l_response: STRING
		do
			last_error := Void
			l_response := do_request ("DELETE", "/networks/" + a_id, Void)
			Result := not has_error
		ensure
			result_consistent: Result = not has_error
		end

	connect_container_to_network (a_network_id, a_container_id: STRING): BOOLEAN
			-- Connect container to network.
		require
			network_id_not_void: a_network_id /= Void
			network_id_not_empty: not a_network_id.is_empty
			container_id_not_void: a_container_id /= Void
			container_id_not_empty: not a_container_id.is_empty
		local
			l_body: STRING
			l_response: STRING
		do
			last_error := Void

			create l_body.make (100)
			l_body.append ("{%"Container%":%"")
			l_body.append (a_container_id)
			l_body.append ("%"}")

			l_response := do_request ("POST", "/networks/" + a_network_id + "/connect", l_body)
			Result := not has_error
		ensure
			result_consistent: Result = not has_error
		end

	disconnect_container_from_network (a_network_id, a_container_id: STRING; a_force: BOOLEAN): BOOLEAN
			-- Disconnect container from network.
		require
			network_id_not_void: a_network_id /= Void
			network_id_not_empty: not a_network_id.is_empty
			container_id_not_void: a_container_id /= Void
			container_id_not_empty: not a_container_id.is_empty
		local
			l_body: STRING
			l_response: STRING
		do
			last_error := Void

			create l_body.make (100)
			l_body.append ("{%"Container%":%"")
			l_body.append (a_container_id)
			l_body.append ("%",%"Force%":")
			if a_force then
				l_body.append ("true")
			else
				l_body.append ("false")
			end
			l_body.append ("}")

			l_response := do_request ("POST", "/networks/" + a_network_id + "/disconnect", l_body)
			Result := not has_error
		ensure
			result_consistent: Result = not has_error
		end

	prune_networks: INTEGER
			-- Remove all unused networks. Returns count of removed networks.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
			l_deleted: detachable SIMPLE_JSON_ARRAY
		do
			last_error := Void
			l_response := do_request ("POST", "/networks/prune", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					l_deleted := v.as_object.array_item ("NetworksDeleted")
					if attached l_deleted as arr then
						Result := arr.count
					end
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Volume Operations

	list_volumes: ARRAYED_LIST [DOCKER_VOLUME]
			-- List all volumes.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
			l_volumes: detachable SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			last_error := Void
			create Result.make (20)

			l_response := do_request ("GET", "/volumes", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					-- Volumes API returns {"Volumes": [...], "Warnings": [...]}
					l_volumes := v.as_object.array_item ("Volumes")
					if attached l_volumes as arr then
						from i := 1 until i > arr.count loop
							if attached arr.object_item (i) as obj then
								Result.extend (create {DOCKER_VOLUME}.make_from_json (obj))
							end
							i := i + 1
						end
					end
				end
			end
		ensure
			result_exists: Result /= Void
			all_volumes_valid: across Result as v all v.name /= Void and v.driver /= Void end
		end

	get_volume (a_name: STRING): detachable DOCKER_VOLUME
			-- Get volume by name.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			l_response := do_request ("GET", "/volumes/" + a_name, Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					create Result.make_from_json (v.as_object)
				end
			end
		ensure
			result_matches_name: attached Result implies Result.name.same_string (a_name)
			result_or_error: Result /= Void xor has_error
		end

	create_volume (a_name: STRING): detachable DOCKER_VOLUME
			-- Create a new volume with default driver.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
		do
			Result := create_volume_with_driver (a_name, "local")
		ensure
			result_has_local_driver: attached Result implies Result.driver.same_string ("local")
			result_matches_name: attached Result implies Result.name.same_string (a_name)
			result_or_error: Result /= Void xor has_error
		end

	create_volume_with_driver (a_name, a_driver: STRING): detachable DOCKER_VOLUME
			-- Create a new volume with specific driver.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
			driver_not_void: a_driver /= Void
			driver_not_empty: not a_driver.is_empty
		local
			l_body: STRING
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void

			create l_body.make (100)
			l_body.append ("{%"Name%":%"")
			l_body.append (a_name)
			l_body.append ("%",%"Driver%":%"")
			l_body.append (a_driver)
			l_body.append ("%"}")

			l_response := do_request ("POST", "/volumes/create", l_body)

			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					create Result.make_from_json (v.as_object)
				end
			end
		ensure
			result_matches_name: attached Result implies Result.name.same_string (a_name)
			result_matches_driver: attached Result implies Result.driver.same_string (a_driver)
			result_or_error: Result /= Void xor has_error
		end

	remove_volume (a_name: STRING; a_force: BOOLEAN): BOOLEAN
			-- Remove a volume. If `a_force', remove even if in use.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
		local
			l_path: STRING
			l_response: STRING
		do
			last_error := Void
			l_path := "/volumes/" + a_name
			if a_force then
				l_path.append ("?force=true")
			end
			l_response := do_request ("DELETE", l_path, Void)
			Result := not has_error
		ensure
			result_consistent: Result = not has_error
		end

	prune_volumes: INTEGER
			-- Remove all unused volumes. Returns count of removed volumes.
		local
			l_response: STRING
			l_json: SIMPLE_JSON
			l_deleted: detachable SIMPLE_JSON_ARRAY
		do
			last_error := Void
			l_response := do_request ("POST", "/volumes/prune", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					l_deleted := v.as_object.array_item ("VolumesDeleted")
					if attached l_deleted as arr then
						Result := arr.count
					end
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Exec Operations

	exec_in_container (a_container_id: STRING; a_command: ARRAY [STRING]): detachable STRING
			-- Execute command in running container. Returns output.
		require
			container_id_not_void: a_container_id /= Void
			container_id_not_empty: not a_container_id.is_empty
			command_not_void: a_command /= Void
			command_not_empty: a_command.count > 0
			all_commands_valid: across a_command as c all c /= Void end
		local
			l_exec_id: detachable STRING
		do
			l_exec_id := create_exec (a_container_id, a_command, True, True)
			if attached l_exec_id as eid then
				Result := start_exec (eid)
			end
		ensure
			result_or_error: Result /= Void xor has_error
		end

	create_exec (a_container_id: STRING; a_command: ARRAY [STRING];
			a_attach_stdout, a_attach_stderr: BOOLEAN): detachable STRING
			-- Create exec instance. Returns exec ID.
		require
			container_id_not_void: a_container_id /= Void
			container_id_not_empty: not a_container_id.is_empty
			command_not_void: a_command /= Void
			command_not_empty: a_command.count > 0
			all_commands_valid: across a_command as c all c /= Void end
		local
			l_body: STRING
			l_response: STRING
			l_json: SIMPLE_JSON
			i: INTEGER
		do
			last_error := Void

			-- Build JSON body
			create l_body.make (200)
			l_body.append ("{%"AttachStdin%":false")
			l_body.append (",%"AttachStdout%":")
			if a_attach_stdout then
				l_body.append ("true")
			else
				l_body.append ("false")
			end
			l_body.append (",%"AttachStderr%":")
			if a_attach_stderr then
				l_body.append ("true")
			else
				l_body.append ("false")
			end
			l_body.append (",%"Tty%":false")
			l_body.append (",%"Cmd%":[")
			from i := a_command.lower until i > a_command.upper loop
				if i > a_command.lower then
					l_body.append (",")
				end
				l_body.append ("%"")
				l_body.append (escape_json_string (a_command [i]))
				l_body.append ("%"")
				i := i + 1
			end
			l_body.append ("]}")

			l_response := do_request ("POST", "/containers/" + a_container_id + "/exec", l_body)

			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					if attached v.as_object.string_item ("Id") as eid then
						Result := eid.to_string_8
					end
				end
			end
		ensure
			result_is_exec_id: attached Result implies not Result.is_empty
			result_or_error: Result /= Void xor has_error
		end

	start_exec (a_exec_id: STRING): detachable STRING
			-- Start exec instance and return output.
		require
			exec_id_not_void: a_exec_id /= Void
			exec_id_not_empty: not a_exec_id.is_empty
		local
			l_body: STRING
			l_response: STRING
		do
			last_error := Void

			l_body := "{%"Detach%":false,%"Tty%":false}"
			l_response := do_request ("POST", "/exec/" + a_exec_id + "/start", l_body)

			if not has_error then
				Result := l_response
			end
		ensure
			result_or_error: Result /= Void xor has_error
		end

	inspect_exec (a_exec_id: STRING): detachable SIMPLE_JSON_OBJECT
			-- Get exec instance details including exit code.
		require
			exec_id_not_void: a_exec_id /= Void
			exec_id_not_empty: not a_exec_id.is_empty
		local
			l_response: STRING
			l_json: SIMPLE_JSON
		do
			last_error := Void
			l_response := do_request ("GET", "/exec/" + a_exec_id + "/json", Void)
			if not has_error and then not l_response.is_empty then
				create l_json
				if attached l_json.parse (l_response) as v and then v.is_object then
					Result := v.as_object
				end
			end
		ensure
			result_or_error: Result /= Void xor has_error
		end

feature {NONE} -- Implementation

	connection: SIMPLE_IPC
			-- IPC connection to Docker daemon.

	do_request (a_method, a_path: STRING; a_body: detachable STRING): STRING
			-- Execute HTTP request over IPC with API version prefix. Returns response body.
		require
			method_valid: a_method.same_string ("GET") or else
				a_method.same_string ("POST") or else
				a_method.same_string ("PUT") or else
				a_method.same_string ("DELETE")
			path_not_empty: not a_path.is_empty
		do
			Result := execute_request (a_method, build_request (a_method, a_path, a_body))
		ensure
			result_exists: Result /= Void
		end

	do_raw_request (a_method, a_path: STRING; a_body: detachable STRING): STRING
			-- Execute HTTP request over IPC WITHOUT API version prefix.
			-- Use for special endpoints like /_ping that don't need versioning.
		require
			method_valid: a_method.same_string ("GET") or else
				a_method.same_string ("POST") or else
				a_method.same_string ("PUT") or else
				a_method.same_string ("DELETE")
			path_not_empty: not a_path.is_empty
		do
			Result := execute_request (a_method, build_raw_request (a_method, a_path, a_body))
		ensure
			result_exists: Result /= Void
		end

	do_binary_request (a_path: STRING; a_body: STRING; a_content_type: STRING): STRING
			-- Execute POST request with binary body and custom content type.
			-- Used for Docker build (tar archives) and other binary uploads.
		require
			path_not_empty: not a_path.is_empty
			body_not_empty: not a_body.is_empty
			content_type_not_empty: not a_content_type.is_empty
		local
			l_request: STRING
			l_full_path: STRING
		do
			l_full_path := "/v" + api_version + a_path
			l_request := build_binary_request (l_full_path, a_body, a_content_type)
			Result := execute_request ("POST", l_request)
		ensure
			result_exists: Result /= Void
		end

	build_binary_request (a_path: STRING; a_body: STRING; a_content_type: STRING): STRING
			-- Build HTTP/1.1 POST request with binary body.
		require
			path_not_empty: not a_path.is_empty
			body_not_empty: not a_body.is_empty
			content_type_not_empty: not a_content_type.is_empty
		do
			create Result.make (a_body.count + 500)
			Result.append ("POST ")
			Result.append (a_path)
			Result.append (" HTTP/1.1%R%N")
			Result.append ("Host: localhost%R%N")
			Result.append ("Content-Type: ")
			Result.append (a_content_type)
			Result.append ("%R%N")
			Result.append ("Content-Length: ")
			Result.append_integer (a_body.count)
			Result.append ("%R%N")
			Result.append ("Connection: keep-alive%R%N")
			Result.append ("%R%N")
			Result.append (a_body)
		ensure
			result_not_empty: not Result.is_empty
			has_http_version: Result.has_substring ("HTTP/1.1")
		end

	execute_request (a_method, a_request: STRING): STRING
			-- Execute prepared HTTP request and parse response.
			-- Uses rescue/retry for transient IPC failures.
		require
			request_not_empty: not a_request.is_empty
		local
			l_response, l_chunk: STRING
			l_status: INTEGER
			l_body_start: INTEGER
			l_is_chunked: BOOLEAN
			l_read_more: BOOLEAN
			l_max_reads: INTEGER
			l_retry_count: INTEGER
			l_env: EXECUTION_ENVIRONMENT
			l_failed: BOOLEAN
		do
			create Result.make_empty

			if l_failed then
				-- Came here from rescue after max retries
				create last_error.make_connection_error ("IPC operation failed after " + default_retry_count.out + " retries")
				logger.error ("IPC operation failed after " + default_retry_count.out + " retries")
			elseif not connection.is_valid then
				create last_error.make_connection_error ("Not connected to Docker daemon")
				logger.error ("Not connected to Docker daemon")
			else
				logger.debug_log ("Sending " + a_method + " request")

				-- Send request
				connection.write_string (a_request)

				-- Read initial response (headers + possibly partial body)
				l_response := connection.read_string (buffer_size)
				logger.debug_log ("Initial response length: " + l_response.count.out)

				-- Parse status and find body start
				l_status := parse_status (l_response)
				logger.debug_log ("HTTP status: " + l_status.out)

				l_body_start := l_response.substring_index ("%R%N%R%N", 1)
				l_is_chunked := l_response.has_substring ("Transfer-Encoding: chunked")

				-- If we have headers but no body yet, and it's chunked, keep reading
				if l_body_start > 0 and l_is_chunked then
					-- Keep reading until we get the terminating chunk (0\r\n\r\n)
					l_max_reads := 100 -- Prevent infinite loop
					from
						l_read_more := not l_response.has_substring ("%R%N0%R%N")
					until
						not l_read_more or l_max_reads <= 0
					loop
						l_chunk := connection.read_string (buffer_size)
						if l_chunk.count > 0 then
							l_response.append (l_chunk)
							logger.debug_log ("Read additional chunk, total now: " + l_response.count.out)
							l_read_more := not l_response.has_substring ("%R%N0%R%N")
						else
							l_read_more := False
						end
						l_max_reads := l_max_reads - 1
					end
				end

				-- Extract body
				if l_body_start > 0 then
					if l_body_start + 4 <= l_response.count then
						Result := l_response.substring (l_body_start + 4, l_response.count)
						logger.debug_log ("Raw body length: " + Result.count.out)
					else
						logger.debug_log ("Body start past response end, empty body")
					end

					-- Handle chunked transfer encoding
					if l_is_chunked and Result.count > 0 then
						Result := decode_chunked (Result)
						logger.debug_log ("Decoded chunked body length: " + Result.count.out)
					end
				else
					logger.warn ("No body separator found in response")
				end

				if l_status >= 400 then
					create last_error.make_from_response (l_status, Result)
					logger.error ("Request failed with status " + l_status.out)
				end
			end
		ensure
			result_exists: Result /= Void
		rescue
			-- Retry on IPC failures (transient connection issues)
			l_retry_count := l_retry_count + 1
			if l_retry_count <= default_retry_count then
				logger.warn ("IPC operation failed, retry " + l_retry_count.out + " of " + default_retry_count.out)
				-- Delay before retry
				create l_env
				l_env.sleep (default_retry_delay_ms * 1_000_000) -- Convert ms to nanoseconds
				-- Reconnect IPC
				create connection.make_client (endpoint)
				retry
			else
				l_failed := True
				retry
			end
		end

	build_request (a_method, a_path: STRING; a_body: detachable STRING): STRING
			-- Build HTTP/1.1 request string with API version prefix.
		require
			method_not_empty: not a_method.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_full_path: STRING
		do
			l_full_path := "/v" + api_version + a_path
			Result := build_http_request (a_method, l_full_path, a_body)
		ensure
			result_not_empty: not Result.is_empty
			has_http_version: Result.has_substring ("HTTP/1.1")
		end

	build_raw_request (a_method, a_path: STRING; a_body: detachable STRING): STRING
			-- Build HTTP/1.1 request string WITHOUT version prefix.
			-- For special endpoints like /_ping.
		require
			method_not_empty: not a_method.is_empty
			path_not_empty: not a_path.is_empty
		do
			Result := build_http_request (a_method, a_path, a_body)
		ensure
			result_not_empty: not Result.is_empty
			has_http_version: Result.has_substring ("HTTP/1.1")
		end

	build_http_request (a_method, a_path: STRING; a_body: detachable STRING): STRING
			-- Build HTTP/1.1 request string with given path.
		require
			method_not_empty: not a_method.is_empty
			path_not_empty: not a_path.is_empty
		do
			create Result.make (500)
			Result.append (a_method)
			Result.append (" ")
			Result.append (a_path)
			Result.append (" HTTP/1.1%R%N")
			Result.append ("Host: localhost%R%N")
			Result.append ("Accept: application/json%R%N")

			if attached a_body as body then
				Result.append ("Content-Type: application/json%R%N")
				Result.append ("Content-Length: ")
				Result.append_integer (body.count)
				Result.append ("%R%N")
			end

			Result.append ("Connection: keep-alive%R%N")
			Result.append ("%R%N")

			if attached a_body as body then
				Result.append (body)
			end
		ensure
			result_not_empty: not Result.is_empty
			has_method: Result.starts_with (a_method)
			has_http_version: Result.has_substring ("HTTP/1.1")
		end

	parse_status (a_response: STRING): INTEGER
			-- Extract HTTP status code from response.
		local
			l_space1, l_space2: INTEGER
			l_status_str: STRING
		do
			-- Format: HTTP/1.1 200 OK
			l_space1 := a_response.index_of (' ', 1)
			if l_space1 > 0 then
				l_space2 := a_response.index_of (' ', l_space1 + 1)
				if l_space2 > l_space1 then
					l_status_str := a_response.substring (l_space1 + 1, l_space2 - 1)
					if l_status_str.is_integer then
						Result := l_status_str.to_integer
					end
				end
			end
		end

	decode_chunked (a_data: STRING): STRING
			-- Decode chunked transfer encoding.
		local
			l_pos, l_chunk_size, l_newline: INTEGER
			l_size_str: STRING
		do
			create Result.make (a_data.count)
			l_pos := 1

			from
			until
				l_pos >= a_data.count
			loop
				-- Find chunk size line
				l_newline := a_data.substring_index ("%R%N", l_pos)
				if l_newline > l_pos then
					l_size_str := a_data.substring (l_pos, l_newline - 1)
					-- Parse hex chunk size
					l_chunk_size := hex_to_integer (l_size_str)
					if l_chunk_size = 0 then
						-- End of chunks
						l_pos := a_data.count + 1
					else
						-- Extract chunk data
						l_pos := l_newline + 2
						if l_pos + l_chunk_size <= a_data.count then
							Result.append (a_data.substring (l_pos, l_pos + l_chunk_size - 1))
						end
						l_pos := l_pos + l_chunk_size + 2 -- Skip chunk data + CRLF
					end
				else
					l_pos := a_data.count + 1
				end
			end
		end

	hex_to_integer (a_hex: STRING): INTEGER
			-- Convert hex string to integer.
		local
			i: INTEGER
			c: CHARACTER
			v: INTEGER
		do
			from i := 1 until i > a_hex.count loop
				c := a_hex.item (i).as_lower
				if c >= '0' and c <= '9' then
					v := c.code - ('0').code
				elseif c >= 'a' and c <= 'f' then
					v := c.code - ('a').code + 10
				else
					v := 0
				end
				Result := Result * 16 + v
				i := i + 1
			end
		end

	string_to_hex (a_str: STRING): STRING
			-- Convert string to hex representation for debugging.
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_str.count * 3)
			from i := 1 until i > a_str.count loop
				c := a_str.item (i)
				Result.append (c.code.to_hex_string.substring (7, 8))
				Result.append (" ")
				i := i + 1
			end
		ensure
			result_exists: Result /= Void
		end

	escape_json_string (a_str: STRING): STRING
			-- Escape special characters in string for JSON.
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_str.count + 10)
			from i := 1 until i > a_str.count loop
				c := a_str.item (i)
				inspect c
				when '\' then
					Result.append ("\\")
				when '"' then
					Result.append ("\%"")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		ensure
			result_exists: Result /= Void
		end

invariant
	endpoint_exists: endpoint /= Void
	endpoint_not_empty: not endpoint.is_empty
	api_version_exists: api_version /= Void
	api_version_not_empty: not api_version.is_empty
	connection_exists: connection /= Void
	logger_exists: logger /= Void
	positive_buffer_size: buffer_size > 0

end
