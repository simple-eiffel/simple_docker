note
	description: "[
		Docker volume representation.

		Represents a Docker volume with its driver and mount information.
		Populated from Docker API responses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_VOLUME

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_from_json

feature {NONE} -- Initialization

	make (a_name: STRING)
			-- Create volume with `a_name'.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
		do
			name := a_name
			driver := "local"
			scope := "local"
			create labels.make (5)
			create options.make (5)
		ensure
			name_set: name.same_string (a_name)
			driver_default: driver.same_string ("local")
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create volume from JSON response.
		require
			json_not_void: a_json /= Void
		local
			l_labels_obj: detachable SIMPLE_JSON_OBJECT
			l_options_obj: detachable SIMPLE_JSON_OBJECT
			l_usage_obj: detachable SIMPLE_JSON_OBJECT
		do
			create labels.make (5)
			create options.make (5)

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
				driver := "local"
			end

			-- Mountpoint
			if attached a_json.string_item ("Mountpoint") as mp then
				mountpoint := mp.to_string_8
			end

			-- Scope
			if attached a_json.string_item ("Scope") as s then
				scope := s.to_string_8
			else
				scope := "local"
			end

			-- CreatedAt
			if attached a_json.string_item ("CreatedAt") as c then
				created_at := c.to_string_8
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

			-- UsageData (if available)
			l_usage_obj := a_json.object_item ("UsageData")
			if attached l_usage_obj as usage then
				size := usage.integer_item ("Size")
				ref_count := usage.integer_item ("RefCount").to_integer
			end
		end

feature -- Access

	name: STRING
			-- Volume name.

	driver: STRING
			-- Volume driver (local, nfs, etc.).

	mountpoint: detachable STRING
			-- Path where volume is mounted on host.

	scope: STRING
			-- Volume scope (local, global).

	created_at: detachable STRING
			-- Creation timestamp.

feature -- Usage

	size: INTEGER_64
			-- Size in bytes (if available, -1 if unknown).

	ref_count: INTEGER
			-- Number of containers using this volume.

feature -- Labels and Options

	labels: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Volume labels.

	options: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Volume driver options.

	has_label (a_key: STRING): BOOLEAN
			-- Does volume have label with key?
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

	has_option (a_key: STRING): BOOLEAN
			-- Does volume have driver option with key?
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			across options as o loop
				if o.key.same_string (a_key) then
					Result := True
				end
			end
		end

	option_value (a_key: STRING): detachable STRING
			-- Get driver option value by key.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			across options as o loop
				if o.key.same_string (a_key) then
					Result := o.value
				end
			end
		end

feature -- Queries

	is_local: BOOLEAN
			-- Is this a local volume?
		do
			Result := driver.same_string ("local")
		ensure
			definition: Result = driver.same_string ("local")
		end

	is_in_use: BOOLEAN
			-- Is volume in use by any container?
		do
			Result := ref_count > 0
		ensure
			definition: Result = (ref_count > 0)
		end

	is_anonymous: BOOLEAN
			-- Is this an anonymous volume (64-char hex name)?
		do
			Result := name.count = 64 and then is_hex_string (name)
		end

	size_mb: REAL_64
			-- Size in megabytes.
		do
			if size > 0 then
				Result := size / (1024 * 1024)
			end
		ensure
			non_negative: Result >= 0
		end

	size_gb: REAL_64
			-- Size in gigabytes.
		do
			if size > 0 then
				Result := size / (1024 * 1024 * 1024)
			end
		ensure
			non_negative: Result >= 0
		end

	matches (a_ref: STRING): BOOLEAN
			-- Does volume match by name?
		require
			ref_not_void: a_ref /= Void
			ref_not_empty: not a_ref.is_empty
		do
			Result := name.same_string (a_ref) or name.starts_with (a_ref)
		end

feature -- Output

	out: STRING
			-- String representation.
		do
			create Result.make (100)
			if is_anonymous then
				Result.append (name.substring (1, 12))
				Result.append ("...")
			else
				Result.append (name)
			end
			Result.append (" (")
			Result.append (driver)
			Result.append (")")
			if size > 0 then
				Result.append (" ")
				if size_gb >= 1 then
					Result.append (size_gb.truncated_to_real.out)
					Result.append (" GB")
				else
					Result.append (size_mb.truncated_to_real.out)
					Result.append (" MB")
				end
			end
			if ref_count > 0 then
				Result.append (" [")
				Result.append (ref_count.out)
				Result.append (" refs]")
			end
		end

feature {NONE} -- Implementation

	is_hex_string (a_string: STRING): BOOLEAN
			-- Is string only hexadecimal characters?
		local
			i: INTEGER
			c: CHARACTER
		do
			Result := True
			from i := 1 until i > a_string.count or not Result loop
				c := a_string [i].as_lower
				Result := (c >= 'a' and c <= 'f') or (c >= '0' and c <= '9')
				i := i + 1
			end
		end

invariant
	name_exists: name /= Void
	driver_exists: driver /= Void
	driver_not_empty: not driver.is_empty
	scope_exists: scope /= Void
	scope_not_empty: not scope.is_empty
	labels_exist: labels /= Void
	options_exist: options /= Void
	ref_count_non_negative: ref_count >= 0
	size_non_negative: size >= 0 or size = -1
	is_in_use_consistent: is_in_use = (ref_count > 0)
	is_local_consistent: is_local = driver.same_string ("local")
	anonymous_name_length: is_anonymous implies name.count = 64

end
