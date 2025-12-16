note
	description: "[
		Zero-configuration Docker facade for beginners.

		This class provides one-liner operations for common Docker tasks.
		No Docker knowledge required - sensible defaults handle everything.

		For full control, use DOCKER_CLIENT directly.

		Quick Start Examples:
			create docker.make

			-- Run a web server (serves files on port 8080)
			docker.web_server ("C:\my_website", 8080)

			-- Run a database (Postgres on port 5432)
			docker.postgres ("mypassword")

			-- Run a script and get output
			print (docker.run_script ("echo hello && date"))

			-- Run Redis cache
			docker.redis

		All containers are tracked and can be stopped/cleaned up:
			docker.stop_all
			docker.cleanup
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_DOCKER_QUICK

create
	make

feature {NONE} -- Initialization

	make
			-- Create quick Docker facade.
		do
			create client.make
			create managed_containers.make (10)
			create managed_names.make (10)
		ensure
			client_exists: client /= Void
			containers_tracked: managed_containers /= Void
		end

feature -- Status

	is_available: BOOLEAN
			-- Is Docker running and accessible?
		do
			Result := client.ping
		end

	last_error_message: STRING
			-- Human-readable error from last operation.
		do
			if attached client.last_error as e then
				Result := e.message
			else
				Result := ""
			end
		ensure
			result_exists: Result /= Void
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := client.has_error
		end

feature -- Web Servers (one-liners)

	web_server (a_folder: STRING; a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run Nginx serving files from `a_folder' on `a_port'.
			-- Example: docker.web_server ("C:\my_site", 8080)
		require
			folder_not_empty: not a_folder.is_empty
			valid_port: a_port > 0 and a_port < 65536
		do
			Result := web_server_nginx (a_folder, a_port)
		end

	web_server_nginx (a_folder: STRING; a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run Nginx web server.
		require
			folder_not_empty: not a_folder.is_empty
			valid_port: a_port > 0 and a_port < 65536
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("nginx:alpine")
			l_name := unique_name ("nginx")

			create l_spec.make ("nginx:alpine")
			l_spec.set_name (l_name)
				.add_port (80, a_port)
				.add_volume (a_folder, "/usr/share/nginx/html")
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	web_server_apache (a_folder: STRING; a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run Apache (httpd) web server.
		require
			folder_not_empty: not a_folder.is_empty
			valid_port: a_port > 0 and a_port < 65536
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("httpd:alpine")
			l_name := unique_name ("apache")

			create l_spec.make ("httpd:alpine")
			l_spec.set_name (l_name)
				.add_port (80, a_port)
				.add_volume (a_folder, "/usr/local/apache2/htdocs")
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

feature -- Databases (one-liners)

	postgres (a_password: STRING): detachable DOCKER_CONTAINER
			-- Run PostgreSQL on port 5432.
			-- Connection: postgresql://postgres:password@localhost:5432/postgres
		require
			password_not_empty: not a_password.is_empty
		do
			Result := postgres_on_port (a_password, 5432)
		end

	postgres_on_port (a_password: STRING; a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run PostgreSQL on custom port.
		require
			password_not_empty: not a_password.is_empty
			valid_port: a_port > 0 and a_port < 65536
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("postgres:16-alpine")
			l_name := unique_name ("postgres")

			create l_spec.make ("postgres:16-alpine")
			l_spec.set_name (l_name)
				.add_port (5432, a_port)
				.add_env ("POSTGRES_PASSWORD", a_password)
				.set_restart_policy ("unless-stopped")
				.set_memory_limit (512 * 1024 * 1024) -- 512 MB
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	mysql (a_password: STRING): detachable DOCKER_CONTAINER
			-- Run MySQL on port 3306.
			-- Connection: mysql://root:password@localhost:3306
		require
			password_not_empty: not a_password.is_empty
		do
			Result := mysql_on_port (a_password, 3306)
		end

	mysql_on_port (a_password: STRING; a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run MySQL on custom port.
		require
			password_not_empty: not a_password.is_empty
			valid_port: a_port > 0 and a_port < 65536
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("mysql:8")
			l_name := unique_name ("mysql")

			create l_spec.make ("mysql:8")
			l_spec.set_name (l_name)
				.add_port (3306, a_port)
				.add_env ("MYSQL_ROOT_PASSWORD", a_password)
				.set_restart_policy ("unless-stopped")
				.set_memory_limit (512 * 1024 * 1024)
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	mariadb (a_password: STRING): detachable DOCKER_CONTAINER
			-- Run MariaDB on port 3306.
		require
			password_not_empty: not a_password.is_empty
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("mariadb:11")
			l_name := unique_name ("mariadb")

			create l_spec.make ("mariadb:11")
			l_spec.set_name (l_name)
				.add_port (3306, 3306)
				.add_env ("MARIADB_ROOT_PASSWORD", a_password)
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	mongodb: detachable DOCKER_CONTAINER
			-- Run MongoDB on port 27017 (no auth by default).
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("mongo:7")
			l_name := unique_name ("mongodb")

			create l_spec.make ("mongo:7")
			l_spec.set_name (l_name)
				.add_port (27017, 27017)
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

feature -- Cache & Message Queues (one-liners)

	redis: detachable DOCKER_CONTAINER
			-- Run Redis on port 6379.
		do
			Result := redis_on_port (6379)
		end

	redis_on_port (a_port: INTEGER): detachable DOCKER_CONTAINER
			-- Run Redis on custom port.
		require
			valid_port: a_port > 0 and a_port < 65536
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("redis:alpine")
			l_name := unique_name ("redis")

			create l_spec.make ("redis:alpine")
			l_spec.set_name (l_name)
				.add_port (6379, a_port)
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	memcached: detachable DOCKER_CONTAINER
			-- Run Memcached on port 11211.
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("memcached:alpine")
			l_name := unique_name ("memcached")

			create l_spec.make ("memcached:alpine")
			l_spec.set_name (l_name)
				.add_port (11211, 11211)
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

	rabbitmq: detachable DOCKER_CONTAINER
			-- Run RabbitMQ on ports 5672 (AMQP) and 15672 (management UI).
			-- Management UI: http://localhost:15672 (guest/guest)
		local
			l_spec: CONTAINER_SPEC
			l_name: STRING
		do
			ensure_image ("rabbitmq:3-management-alpine")
			l_name := unique_name ("rabbitmq")

			create l_spec.make ("rabbitmq:3-management-alpine")
			l_spec.set_name (l_name)
				.add_port (5672, 5672)
				.add_port (15672, 15672)
				.set_restart_policy ("unless-stopped")
				.do_nothing

			Result := run_and_track (l_spec, l_name)
		end

feature -- Script Execution (one-liners)

	run_script (a_script: STRING): STRING
			-- Run shell script in Alpine container, return output.
			-- Container is automatically removed after execution.
			-- Example: docker.run_script ("echo hello && date")
		require
			script_not_empty: not a_script.is_empty
		do
			Result := run_script_in_image ("alpine:latest", a_script)
		ensure
			result_exists: Result /= Void
		end

	run_script_in_image (a_image: STRING; a_script: STRING): STRING
			-- Run script in specified image.
		require
			image_not_empty: not a_image.is_empty
			script_not_empty: not a_script.is_empty
		local
			l_spec: CONTAINER_SPEC
			l_container: detachable DOCKER_CONTAINER
			l_exit_code: INTEGER
		do
			Result := ""
			ensure_image (a_image)

			create l_spec.make (a_image)
			l_spec.set_cmd (<<"sh", "-c", a_script>>)
				.set_auto_remove (True)
				.do_nothing

			l_container := client.create_container (l_spec)

			if attached l_container as c then
				if client.start_container (c.id) then
					l_exit_code := client.wait_container (c.id)
					if attached client.container_logs (c.id, True, True, 10000) as logs then
						Result := strip_docker_stream_headers (logs)
					end
					if l_exit_code /= 0 then
						Result := "[Exit code: " + l_exit_code.out + "]%N" + Result
					end
				end
				-- Auto-remove handles cleanup
			end
		ensure
			result_exists: Result /= Void
		end

	run_python (a_script: STRING): STRING
			-- Run Python script, return output.
		require
			script_not_empty: not a_script.is_empty
		do
			Result := run_script_in_image ("python:3-alpine", "python -c %"" + a_script + "%"")
		end

feature -- Container Management

	stop_all
			-- Stop all containers started by this facade.
		do
			across managed_containers as cid loop
				client.stop_container (cid, 5).do_nothing
			end
		end

	cleanup
			-- Stop and remove all containers started by this facade.
		do
			across managed_containers as cid loop
				client.remove_container (cid, True).do_nothing
			end
			managed_containers.wipe_out
			managed_names.wipe_out
		end

	container_count: INTEGER
			-- Number of containers managed by this facade.
		do
			Result := managed_containers.count
		end

feature -- Advanced Access

	client: DOCKER_CLIENT
			-- Access underlying client for advanced operations.

feature {NONE} -- Implementation

	managed_containers: ARRAYED_LIST [STRING]
			-- IDs of containers started by this facade.

	managed_names: ARRAYED_LIST [STRING]
			-- Names of containers started by this facade.

	name_counter: INTEGER
			-- Counter for unique names.

	ensure_image (a_image: STRING)
			-- Pull image if not present locally.
		require
			image_not_empty: not a_image.is_empty
		do
			if not client.image_exists (a_image) then
				client.pull_image (a_image).do_nothing
			end
		end

	unique_name (a_prefix: STRING): STRING
			-- Generate unique container name.
		do
			name_counter := name_counter + 1
			Result := "quick_" + a_prefix + "_" + name_counter.out
		ensure
			not_empty: not Result.is_empty
		end

	run_and_track (a_spec: CONTAINER_SPEC; a_name: STRING): detachable DOCKER_CONTAINER
			-- Run container and add to tracking.
		require
			spec_not_void: a_spec /= Void
		do
			Result := client.run_container (a_spec)
			if attached Result as c then
				managed_containers.extend (c.id)
				managed_names.extend (a_name)
			end
		end

	strip_docker_stream_headers (a_data: STRING): STRING
			-- Remove Docker multiplexed stream headers from output.
			-- Each frame has 8-byte header: [type][0][0][0][size-big-endian]
		local
			l_pos, l_size: INTEGER
		do
			create Result.make (a_data.count)
			from
				l_pos := 1
			until
				l_pos + 7 > a_data.count
			loop
				-- Read size from bytes 5-8 (big-endian)
				l_size := (a_data.item (l_pos + 4).code |<< 24) +
				          (a_data.item (l_pos + 5).code |<< 16) +
				          (a_data.item (l_pos + 6).code |<< 8) +
				           a_data.item (l_pos + 7).code

				if l_size > 0 and then l_pos + 7 + l_size <= a_data.count then
					Result.append (a_data.substring (l_pos + 8, l_pos + 7 + l_size))
				end
				l_pos := l_pos + 8 + l_size
			end

			-- If no headers found, return original (non-TTY mode)
			if Result.is_empty and not a_data.is_empty then
				Result := a_data.twin
			end
		ensure
			result_exists: Result /= Void
		end

invariant
	client_exists: client /= Void
	containers_tracked: managed_containers /= Void
	names_tracked: managed_names /= Void

end
