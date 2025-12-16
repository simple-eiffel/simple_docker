note
	description: "[
		Container configuration specification with fluent API.

		Builder pattern for constructing container create requests.
		Converts to JSON for Docker API.

		Usage:
			create spec.make ("nginx:alpine")
			spec.set_name ("my-nginx")
			    .add_port (80, 8080)
			    .add_env ("DEBUG", "true")
			    .add_volume ("/data", "/container/data")
			    .set_memory_limit (512 * 1024 * 1024)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CONTAINER_SPEC

create
	make

feature {NONE} -- Initialization

	make (a_image: STRING)
			-- Create spec for `a_image'.
		require
			image_not_empty: not a_image.is_empty
		do
			image := a_image
			create environment.make (10)
			create port_bindings.make (5)
			create volume_bindings.make (5)
			create labels.make (5)
			create cmd.make (5)
			create entrypoint.make (5)
		ensure
			image_set: image.same_string (a_image)
		end

feature -- Access

	image: STRING
			-- Docker image name (required).

	name: detachable STRING
			-- Container name (optional, Docker generates if not set).

	hostname: detachable STRING
			-- Container hostname.

	working_dir: detachable STRING
			-- Working directory inside container.

	user: detachable STRING
			-- User to run as (user:group).

	environment: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Environment variables.

	port_bindings: ARRAYED_LIST [TUPLE [container_port, host_port: INTEGER; protocol: STRING]]
			-- Port mappings (container -> host).

	volume_bindings: ARRAYED_LIST [TUPLE [host_path, container_path: STRING; read_only: BOOLEAN]]
			-- Volume mounts.

	labels: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Container labels.

	cmd: ARRAYED_LIST [STRING]
			-- Command to run (overrides image CMD).

	entrypoint: ARRAYED_LIST [STRING]
			-- Entrypoint (overrides image ENTRYPOINT).

	memory_limit: INTEGER_64
			-- Memory limit in bytes (0 = no limit).

	cpu_shares: INTEGER
			-- CPU shares (relative weight).

	restart_policy: detachable STRING
			-- Restart policy: no, always, on-failure, unless-stopped.

	network_mode: detachable STRING
			-- Network mode: bridge, host, none, container:<name>.

	auto_remove: BOOLEAN
			-- Remove container when it exits.

	tty: BOOLEAN
			-- Allocate pseudo-TTY.

	stdin_open: BOOLEAN
			-- Keep STDIN open.

feature -- Fluent Setters

	set_name (a_name: STRING): like Current
			-- Set container name.
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name
			Result := Current
		ensure
			name_set: attached name as n and then n.same_string (a_name)
			result_is_current: Result = Current
		end

	set_hostname (a_hostname: STRING): like Current
			-- Set container hostname.
		require
			hostname_not_empty: not a_hostname.is_empty
		do
			hostname := a_hostname
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_working_dir (a_dir: STRING): like Current
			-- Set working directory.
		require
			dir_not_empty: not a_dir.is_empty
		do
			working_dir := a_dir
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_user (a_user: STRING): like Current
			-- Set user (user:group format).
		require
			user_not_empty: not a_user.is_empty
		do
			user := a_user
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_env (a_key, a_value: STRING): like Current
			-- Add environment variable.
		require
			key_not_empty: not a_key.is_empty
		do
			environment.extend ([a_key, a_value])
			Result := Current
		ensure
			env_added: environment.count = old environment.count + 1
			result_is_current: Result = Current
		end

	add_port (a_container_port, a_host_port: INTEGER): like Current
			-- Add TCP port mapping.
		require
			valid_container_port: a_container_port > 0 and a_container_port <= 65535
			valid_host_port: a_host_port >= 0 and a_host_port <= 65535
		do
			port_bindings.extend ([a_container_port, a_host_port, "tcp"])
			Result := Current
		ensure
			port_added: port_bindings.count = old port_bindings.count + 1
			result_is_current: Result = Current
		end

	add_port_udp (a_container_port, a_host_port: INTEGER): like Current
			-- Add UDP port mapping.
		require
			valid_container_port: a_container_port > 0 and a_container_port <= 65535
			valid_host_port: a_host_port >= 0 and a_host_port <= 65535
		do
			port_bindings.extend ([a_container_port, a_host_port, "udp"])
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_volume (a_host_path, a_container_path: STRING): like Current
			-- Add volume mount (read-write).
		require
			host_path_not_empty: not a_host_path.is_empty
			container_path_not_empty: not a_container_path.is_empty
		do
			volume_bindings.extend ([a_host_path, a_container_path, False])
			Result := Current
		ensure
			volume_added: volume_bindings.count = old volume_bindings.count + 1
			result_is_current: Result = Current
		end

	add_volume_readonly (a_host_path, a_container_path: STRING): like Current
			-- Add read-only volume mount.
		require
			host_path_not_empty: not a_host_path.is_empty
			container_path_not_empty: not a_container_path.is_empty
		do
			volume_bindings.extend ([a_host_path, a_container_path, True])
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_label (a_key, a_value: STRING): like Current
			-- Add container label.
		require
			key_not_empty: not a_key.is_empty
		do
			labels.extend ([a_key, a_value])
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_cmd (a_cmd: ARRAY [STRING]): like Current
			-- Set command.
		require
			cmd_not_empty: not a_cmd.is_empty
		do
			cmd.wipe_out
			across a_cmd as c loop cmd.extend (c) end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_entrypoint (a_entrypoint: ARRAY [STRING]): like Current
			-- Set entrypoint.
		require
			entrypoint_not_empty: not a_entrypoint.is_empty
		do
			entrypoint.wipe_out
			across a_entrypoint as e loop entrypoint.extend (e) end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_memory_limit (a_bytes: INTEGER_64): like Current
			-- Set memory limit in bytes.
		require
			non_negative: a_bytes >= 0
		do
			memory_limit := a_bytes
			Result := Current
		ensure
			limit_set: memory_limit = a_bytes
			result_is_current: Result = Current
		end

	set_cpu_shares (a_shares: INTEGER): like Current
			-- Set CPU shares (relative weight, default 1024).
		require
			non_negative: a_shares >= 0
		do
			cpu_shares := a_shares
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_restart_policy (a_policy: STRING): like Current
			-- Set restart policy: no, always, on-failure, unless-stopped.
		require
			valid_policy: a_policy.same_string ("no") or else
				a_policy.same_string ("always") or else
				a_policy.same_string ("on-failure") or else
				a_policy.same_string ("unless-stopped")
		do
			restart_policy := a_policy
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_network_mode (a_mode: STRING): like Current
			-- Set network mode.
		require
			mode_not_empty: not a_mode.is_empty
		do
			network_mode := a_mode
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_auto_remove (a_value: BOOLEAN): like Current
			-- Set auto-remove on exit.
		do
			auto_remove := a_value
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_tty (a_value: BOOLEAN): like Current
			-- Set TTY allocation.
		do
			tty := a_value
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_stdin_open (a_value: BOOLEAN): like Current
			-- Set keep STDIN open.
		do
			stdin_open := a_value
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Conversion

	to_json: STRING
			-- Convert spec to JSON for Docker API.
		local
			l_json: SIMPLE_JSON_OBJECT
			l_host_config: SIMPLE_JSON_OBJECT
			l_env_array: SIMPLE_JSON_ARRAY
			l_exposed_ports: SIMPLE_JSON_OBJECT
			l_port_bindings_obj: SIMPLE_JSON_OBJECT
			l_binds: SIMPLE_JSON_ARRAY
			l_labels_obj: SIMPLE_JSON_OBJECT
			l_cmd_array: SIMPLE_JSON_ARRAY
			l_ep_array: SIMPLE_JSON_ARRAY
			l_port_key: STRING
			l_binding_array: SIMPLE_JSON_ARRAY
			l_binding_obj: SIMPLE_JSON_OBJECT
			l_restart_obj: SIMPLE_JSON_OBJECT
		do
			create l_json.make
			create l_host_config.make

			-- Required: Image
			l_json.put_string (image, "Image").do_nothing

			-- Optional: Hostname
			if attached hostname as h then
				l_json.put_string (h, "Hostname").do_nothing
			end

			-- Optional: User
			if attached user as u then
				l_json.put_string (u, "User").do_nothing
			end

			-- Optional: WorkingDir
			if attached working_dir as w then
				l_json.put_string (w, "WorkingDir").do_nothing
			end

			-- Optional: Tty
			if tty then
				l_json.put_boolean (True, "Tty").do_nothing
			end

			-- Optional: OpenStdin
			if stdin_open then
				l_json.put_boolean (True, "OpenStdin").do_nothing
			end

			-- Environment variables
			if not environment.is_empty then
				create l_env_array.make
				across environment as env loop
					l_env_array.add_string (env.key + "=" + env.value).do_nothing
				end
				l_json.put_array (l_env_array, "Env").do_nothing
			end

			-- Cmd
			if not cmd.is_empty then
				create l_cmd_array.make
				across cmd as c loop
					l_cmd_array.add_string (c).do_nothing
				end
				l_json.put_array (l_cmd_array, "Cmd").do_nothing
			end

			-- Entrypoint
			if not entrypoint.is_empty then
				create l_ep_array.make
				across entrypoint as e loop
					l_ep_array.add_string (e).do_nothing
				end
				l_json.put_array (l_ep_array, "Entrypoint").do_nothing
			end

			-- ExposedPorts
			if not port_bindings.is_empty then
				create l_exposed_ports.make
				across port_bindings as p loop
					l_port_key := p.container_port.out + "/" + p.protocol
					l_exposed_ports.put_object (create {SIMPLE_JSON_OBJECT}.make, l_port_key).do_nothing
				end
				l_json.put_object (l_exposed_ports, "ExposedPorts").do_nothing
			end

			-- Labels
			if not labels.is_empty then
				create l_labels_obj.make
				across labels as lbl loop
					l_labels_obj.put_string (lbl.value, lbl.key).do_nothing
				end
				l_json.put_object (l_labels_obj, "Labels").do_nothing
			end

			-- HostConfig
			-- Port bindings
			if not port_bindings.is_empty then
				create l_port_bindings_obj.make
				across port_bindings as p loop
					l_port_key := p.container_port.out + "/" + p.protocol
					create l_binding_array.make
					create l_binding_obj.make
					l_binding_obj.put_string (p.host_port.out, "HostPort").do_nothing
					l_binding_array.add_object (l_binding_obj).do_nothing
					l_port_bindings_obj.put_array (l_binding_array, l_port_key).do_nothing
				end
				l_host_config.put_object (l_port_bindings_obj, "PortBindings").do_nothing
			end

			-- Volume bindings
			if not volume_bindings.is_empty then
				create l_binds.make
				across volume_bindings as v loop
					if v.read_only then
						l_binds.add_string (v.host_path + ":" + v.container_path + ":ro").do_nothing
					else
						l_binds.add_string (v.host_path + ":" + v.container_path).do_nothing
					end
				end
				l_host_config.put_array (l_binds, "Binds").do_nothing
			end

			-- Memory limit
			if memory_limit > 0 then
				l_host_config.put_integer (memory_limit, "Memory").do_nothing
			end

			-- CPU shares
			if cpu_shares > 0 then
				l_host_config.put_integer (cpu_shares, "CpuShares").do_nothing
			end

			-- Restart policy
			if attached restart_policy as rp then
				create l_restart_obj.make
				l_restart_obj.put_string (rp, "Name").do_nothing
				l_host_config.put_object (l_restart_obj, "RestartPolicy").do_nothing
			end

			-- Network mode
			if attached network_mode as nm then
				l_host_config.put_string (nm, "NetworkMode").do_nothing
			end

			-- Auto remove
			if auto_remove then
				l_host_config.put_boolean (True, "AutoRemove").do_nothing
			end

			l_json.put_object (l_host_config, "HostConfig").do_nothing

			Result := l_json.as_json
		ensure
			result_not_empty: not Result.is_empty
		end

invariant
	image_not_empty: not image.is_empty
	environment_exists: environment /= Void
	port_bindings_exists: port_bindings /= Void
	volume_bindings_exists: volume_bindings /= Void

end
