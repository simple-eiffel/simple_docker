note
	description: "[
		Docker container representation.

		Represents a container with its metadata and state.
		Populated from Docker API responses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_CONTAINER

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_from_json

feature {NONE} -- Initialization

	make (a_id: STRING)
			-- Create container with `a_id'.
		require
			id_not_void: a_id /= Void
			id_not_empty: not a_id.is_empty
		do
			id := a_id
			short_id := a_id.substring (1, (12).min (a_id.count))
			state := (create {CONTAINER_STATE}).created
			create names.make (1)
			create labels.make (5)
			create ports.make (5)
		ensure
			id_set: id.same_string (a_id)
			short_id_valid: short_id.count <= 12
			short_id_prefix: a_id.starts_with (short_id)
			names_empty: names.is_empty
			labels_empty: labels.is_empty
			ports_empty: ports.is_empty
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create container from JSON response.
		require
			json_not_void: a_json /= Void
		local
			l_id: detachable STRING_32
			l_names: detachable SIMPLE_JSON_ARRAY
			l_labels: detachable SIMPLE_JSON_OBJECT
			l_ports: detachable SIMPLE_JSON_ARRAY
			l_state_obj: detachable SIMPLE_JSON_OBJECT
			i: INTEGER
		do
			create names.make (1)
			create labels.make (5)
			create ports.make (5)

			-- ID
			l_id := a_json.string_item ("Id")
			if l_id = Void then
				l_id := a_json.string_item ("ID")
			end
			if attached l_id as lid then
				id := lid.to_string_8
				short_id := id.substring (1, (12).min (id.count))
			else
				id := ""
				short_id := ""
			end

			-- Names
			l_names := a_json.array_item ("Names")
			if attached l_names as ln then
				from i := 1 until i > ln.count loop
					if attached ln.string_item (i) as s then
						names.extend (s.to_string_8)
					end
					i := i + 1
				end
			end

			-- Image
			if attached a_json.string_item ("Image") as img then
				image := img.to_string_8
			else
				image := ""
			end

			-- ImageID
			if attached a_json.string_item ("ImageID") as iid then
				image_id := iid.to_string_8
			end

			-- Command
			if attached a_json.string_item ("Command") as cmd then
				command := cmd.to_string_8
			end

			-- Created (Unix timestamp)
			created_timestamp := a_json.integer_item ("Created")

			-- State
			if attached a_json.string_item ("State") as s then
				state := s.to_string_8
			else
				-- Check for nested State object
				l_state_obj := a_json.object_item ("State")
				if attached l_state_obj as so then
					if attached so.string_item ("Status") as st then
						state := st.to_string_8
					end
					exit_code := so.integer_item ("ExitCode").to_integer
				end
			end
			if state = Void then
				state := (create {CONTAINER_STATE}).created
			end

			-- Status (human-readable)
			if attached a_json.string_item ("Status") as st then
				status := st.to_string_8
			end

			-- Labels
			l_labels := a_json.object_item ("Labels")
			if attached l_labels as ll then
				across ll.keys as k loop
					if attached ll.string_item (k) as v then
						labels.extend ([k.to_string_8, v.to_string_8])
					end
				end
			end

			-- Ports
			l_ports := a_json.array_item ("Ports")
			if attached l_ports as lp then
				from i := 1 until i > lp.count loop
					if attached lp.object_item (i) as po then
						parse_port (po)
					end
					i := i + 1
				end
			end

			-- NetworkSettings
			if attached a_json.object_item ("NetworkSettings") as ns then
				if attached ns.object_item ("Networks") as networks then
					across networks.keys as nk loop
						if attached networks.object_item (nk) as net_obj then
							if attached net_obj.string_item ("IPAddress") as ip then
								ip_address := ip.to_string_8
							end
						end
					end
				end
			end
		end

feature -- Access

	id: STRING
			-- Full container ID (64 hex chars).

	short_id: STRING
			-- Short container ID (12 chars).

	names: ARRAYED_LIST [STRING]
			-- Container names (including leading /).

	image: detachable STRING assign set_image
			-- Image name.

feature -- Element change

	set_image (a_image: detachable STRING)
			-- Set `image' to `a_image'.
		do
			image := a_image
		ensure
			image_set: image = a_image
		end

	image_id: detachable STRING
			-- Image ID.

	command: detachable STRING
			-- Command being run.

	created_timestamp: INTEGER_64
			-- Unix timestamp of creation.

	state: detachable STRING
			-- Container state (created, running, paused, exited, dead).

	status: detachable STRING
			-- Human-readable status.

	exit_code: INTEGER
			-- Exit code (if exited).

	labels: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Container labels.

	ports: ARRAYED_LIST [TUPLE [private_port, public_port: INTEGER; protocol, ip: STRING]]
			-- Port mappings.

	ip_address: detachable STRING
			-- Container IP address.

feature -- Queries

	name: detachable STRING
			-- Primary container name (without leading /).
		do
			if not names.is_empty then
				Result := names.first
				if Result.starts_with ("/") then
					Result := Result.substring (2, Result.count)
				end
			end
		end

	is_running: BOOLEAN
			-- Is container running?
		do
			Result := attached state as s and then s.same_string ((create {CONTAINER_STATE}).running)
		ensure
			running_state_check: Result implies (attached state as s and then s.same_string ("running"))
			exclusive_with_exited: Result implies not is_exited
		end

	is_paused: BOOLEAN
			-- Is container paused?
		do
			Result := attached state as s and then s.same_string ((create {CONTAINER_STATE}).paused)
		ensure
			paused_state_check: Result implies (attached state as s and then s.same_string ("paused"))
		end

	is_exited: BOOLEAN
			-- Has container exited?
		do
			Result := attached state as s and then s.same_string ((create {CONTAINER_STATE}).exited)
		ensure
			exited_state_check: Result implies (attached state as s and then s.same_string ("exited"))
			exclusive_with_running: Result implies not is_running
		end

	is_dead: BOOLEAN
			-- Is container dead?
		do
			Result := attached state as s and then s.same_string ((create {CONTAINER_STATE}).dead)
		ensure
			dead_state_check: Result implies (attached state as s and then s.same_string ("dead"))
		end

	can_start: BOOLEAN
			-- Can this container be started?
		local
			l_states: CONTAINER_STATE
		do
			create l_states
			Result := attached state as s and then l_states.can_start (s)
		ensure
			running_cannot_start: is_running implies not Result
		end

	can_stop: BOOLEAN
			-- Can this container be stopped?
		local
			l_states: CONTAINER_STATE
		do
			create l_states
			Result := attached state as s and then l_states.can_stop (s)
		ensure
			running_can_stop: is_running implies Result
			exited_cannot_stop: is_exited implies not Result
		end

	has_exited_successfully: BOOLEAN
			-- Did container exit with code 0?
		do
			Result := is_exited and then exit_code = 0
		ensure
			success_implies_exited: Result implies is_exited
			success_implies_zero_exit: Result implies exit_code = 0
		end

feature -- Output

	out: STRING
			-- String representation.
		do
			create Result.make (100)
			Result.append (short_id)
			if attached name as n then
				Result.append (" (")
				Result.append (n)
				Result.append (")")
			end
			Result.append (" ")
			if attached image as img then
				Result.append (img)
			end
			Result.append (" [")
			if attached state as s then
				Result.append (s)
			end
			Result.append ("]")
		end

feature {NONE} -- Implementation

	parse_port (a_port: SIMPLE_JSON_OBJECT)
			-- Parse port object and add to ports list.
		local
			l_private, l_public: INTEGER
			l_protocol, l_ip: STRING
		do
			l_private := a_port.integer_item ("PrivatePort").to_integer
			l_public := a_port.integer_item ("PublicPort").to_integer
			if attached a_port.string_item ("Type") as t then
				l_protocol := t.to_string_8
			else
				l_protocol := "tcp"
			end
			if attached a_port.string_item ("IP") as i then
				l_ip := i.to_string_8
			else
				l_ip := ""
			end
			if l_private > 0 then
				ports.extend ([l_private, l_public, l_protocol, l_ip])
			end
		end

invariant
	id_exists: id /= Void
	short_id_exists: short_id /= Void
	short_id_length_valid: short_id.count <= 12
	short_id_consistency: (not id.is_empty and id.count >= short_id.count) implies id.starts_with (short_id)
	names_exists: names /= Void
	labels_exists: labels /= Void
	ports_exists: ports /= Void

end
