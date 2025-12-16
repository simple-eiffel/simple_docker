note
	description: "[
		Docker network representation.

		Represents a Docker network with its configuration and connected containers.
		Populated from Docker API responses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_NETWORK

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
			-- Create network with `a_id'.
		require
			id_not_void: a_id /= Void
			id_not_empty: not a_id.is_empty
		do
			id := a_id
			short_id := a_id.substring (1, (12).min (a_id.count))
			name := ""
			driver := "bridge"
			scope := "local"
			create containers.make (5)
			create labels.make (5)
			create options.make (5)
		ensure
			id_set: id.same_string (a_id)
			short_id_valid: short_id.count <= 12
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create network from JSON response.
		require
			json_not_void: a_json /= Void
		local
			l_containers_obj: detachable SIMPLE_JSON_OBJECT
			l_labels_obj: detachable SIMPLE_JSON_OBJECT
			l_options_obj: detachable SIMPLE_JSON_OBJECT
			l_ipam_obj: detachable SIMPLE_JSON_OBJECT
			l_ipam_config: detachable SIMPLE_JSON_ARRAY
		do
			create containers.make (5)
			create labels.make (5)
			create options.make (5)

			-- ID
			if attached a_json.string_item ("Id") as lid then
				id := lid.to_string_8
				short_id := id.substring (1, (12).min (id.count))
			else
				id := ""
				short_id := ""
			end

			-- Name
			if attached a_json.string_item ("Name") as n then
				name := n.to_string_8
			else
				name := ""
			end

			-- Driver
			if attached a_json.string_item ("Driver") as d then
				driver := d.to_string_8
			else
				driver := "bridge"
			end

			-- Scope
			if attached a_json.string_item ("Scope") as s then
				scope := s.to_string_8
			else
				scope := "local"
			end

			-- Created
			if attached a_json.string_item ("Created") as c then
				created := c.to_string_8
			end

			-- EnableIPv6
			enable_ipv6 := a_json.boolean_item ("EnableIPv6")

			-- Internal
			is_internal := a_json.boolean_item ("Internal")

			-- Attachable
			is_attachable := a_json.boolean_item ("Attachable")

			-- Ingress
			is_ingress := a_json.boolean_item ("Ingress")

			-- IPAM
			l_ipam_obj := a_json.object_item ("IPAM")
			if attached l_ipam_obj as ipam then
				if attached ipam.string_item ("Driver") as ipam_driver then
					ipam_driver_name := ipam_driver.to_string_8
				end
				l_ipam_config := ipam.array_item ("Config")
				if attached l_ipam_config as config and then config.count > 0 then
					if attached config.object_item (1) as first_config then
						if attached first_config.string_item ("Subnet") as subnet then
							ipam_subnet := subnet.to_string_8
						end
						if attached first_config.string_item ("Gateway") as gateway then
							ipam_gateway := gateway.to_string_8
						end
					end
				end
			end

			-- Containers
			l_containers_obj := a_json.object_item ("Containers")
			if attached l_containers_obj as cont_obj then
				across cont_obj.keys as k loop
					if attached cont_obj.object_item (k) as cont_info then
						if attached cont_info.string_item ("Name") as cont_name then
							containers.extend ([k.to_string_8, cont_name.to_string_8])
						end
					end
				end
			end

			-- Labels
			l_labels_obj := a_json.object_item ("Labels")
			if attached l_labels_obj as lbl_obj then
				across lbl_obj.keys as k loop
					if attached lbl_obj.string_item (k) as v then
						labels.extend ([k.to_string_8, v.to_string_8])
					end
				end
			end

			-- Options
			l_options_obj := a_json.object_item ("Options")
			if attached l_options_obj as opt_obj then
				across opt_obj.keys as k loop
					if attached opt_obj.string_item (k) as v then
						options.extend ([k.to_string_8, v.to_string_8])
					end
				end
			end
		end

feature -- Access

	id: STRING
			-- Full network ID.

	short_id: STRING
			-- Short network ID (12 chars).

	name: STRING
			-- Network name.

	driver: STRING
			-- Network driver (bridge, host, overlay, macvlan, none).

	scope: STRING
			-- Network scope (local, global, swarm).

	created: detachable STRING
			-- Creation timestamp.

	enable_ipv6: BOOLEAN
			-- Is IPv6 enabled?

	is_internal: BOOLEAN
			-- Is this an internal network (no external access)?

	is_attachable: BOOLEAN
			-- Can containers be attached manually?

	is_ingress: BOOLEAN
			-- Is this the ingress network for swarm?

feature -- IPAM

	ipam_driver_name: detachable STRING
			-- IPAM driver name.

	ipam_subnet: detachable STRING
			-- IPAM subnet (e.g., "172.17.0.0/16").

	ipam_gateway: detachable STRING
			-- IPAM gateway (e.g., "172.17.0.1").

feature -- Containers

	containers: ARRAYED_LIST [TUPLE [id, name: STRING]]
			-- Containers connected to this network.

	container_count: INTEGER
			-- Number of connected containers.
		do
			Result := containers.count
		ensure
			result_non_negative: Result >= 0
		end

	has_container (a_id_or_name: STRING): BOOLEAN
			-- Is container with ID or name connected?
		require
			id_or_name_not_void: a_id_or_name /= Void
			id_or_name_not_empty: not a_id_or_name.is_empty
		do
			across containers as c loop
				if c.id.same_string (a_id_or_name) or c.name.same_string (a_id_or_name) then
					Result := True
				end
			end
		end

feature -- Labels and Options

	labels: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Network labels.

	options: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Network driver options.

	has_label (a_key: STRING): BOOLEAN
			-- Does network have label with key?
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			across labels as l loop
				if l.key.same_string (a_key) then
					Result := True
				end
			end
		end

	label_value (a_key: STRING): detachable STRING
			-- Get label value by key.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			across labels as l loop
				if l.key.same_string (a_key) then
					Result := l.value
				end
			end
		end

feature -- Queries

	is_bridge: BOOLEAN
			-- Is this a bridge network?
		do
			Result := driver.same_string ("bridge")
		ensure
			definition: Result = driver.same_string ("bridge")
		end

	is_host: BOOLEAN
			-- Is this the host network?
		do
			Result := driver.same_string ("host")
		ensure
			definition: Result = driver.same_string ("host")
		end

	is_overlay: BOOLEAN
			-- Is this an overlay network?
		do
			Result := driver.same_string ("overlay")
		ensure
			definition: Result = driver.same_string ("overlay")
		end

	is_none: BOOLEAN
			-- Is this the none network?
		do
			Result := driver.same_string ("none") or name.same_string ("none")
		end

	is_default: BOOLEAN
			-- Is this a default Docker network?
		do
			Result := name.same_string ("bridge") or
					  name.same_string ("host") or
					  name.same_string ("none")
		ensure
			definition: Result = (name.same_string ("bridge") or
								  name.same_string ("host") or
								  name.same_string ("none"))
		end

	matches (a_ref: STRING): BOOLEAN
			-- Does network match by ID, short ID, or name?
		require
			ref_not_void: a_ref /= Void
			ref_not_empty: not a_ref.is_empty
		do
			Result := id.same_string (a_ref) or
					  short_id.same_string (a_ref) or
					  name.same_string (a_ref) or
					  id.starts_with (a_ref)
		end

feature -- Output

	out: STRING
			-- String representation.
		do
			create Result.make (100)
			Result.append (short_id)
			Result.append (" ")
			Result.append (name)
			Result.append (" (")
			Result.append (driver)
			Result.append (") [")
			Result.append (container_count.out)
			Result.append (" containers]")
		end

invariant
	id_exists: id /= Void
	short_id_exists: short_id /= Void
	short_id_length_valid: short_id.count <= 12
	short_id_consistency: (not id.is_empty and id.count >= short_id.count) implies id.starts_with (short_id)
	name_exists: name /= Void
	driver_exists: driver /= Void
	driver_not_empty: not driver.is_empty
	scope_exists: scope /= Void
	scope_not_empty: not scope.is_empty
	containers_exist: containers /= Void
	labels_exist: labels /= Void
	options_exist: options /= Void
	container_count_consistent: container_count = containers.count

end
