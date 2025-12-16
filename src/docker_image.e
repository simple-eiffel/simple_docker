note
	description: "[
		Docker image representation.

		Represents an image with its metadata.
		Populated from Docker API responses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_IMAGE

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
			-- Create image with `a_id'.
		require
			id_not_void: a_id /= Void
			id_not_empty: not a_id.is_empty
		do
			id := a_id
			if a_id.count >= 12 then
				short_id := a_id.substring (1, 12)
			else
				short_id := a_id
			end
			create repo_tags.make (3)
			create repo_digests.make (1)
			create labels.make (5)
		ensure
			id_set: id.same_string (a_id)
			short_id_valid: short_id.count <= 12
			short_id_from_id: a_id.starts_with (short_id)
			repo_tags_empty: repo_tags.is_empty
			labels_empty: labels.is_empty
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create image from JSON response.
		require
			json_not_void: a_json /= Void
		local
			l_id: detachable STRING_32
			l_tags: detachable SIMPLE_JSON_ARRAY
			l_digests: detachable SIMPLE_JSON_ARRAY
			l_labels: detachable SIMPLE_JSON_OBJECT
			i: INTEGER
		do
			create repo_tags.make (3)
			create repo_digests.make (1)
			create labels.make (5)

			-- ID (may have sha256: prefix)
			l_id := a_json.string_item ("Id")
			if l_id = Void then
				l_id := a_json.string_item ("ID")
			end
			if attached l_id as lid then
				if lid.starts_with ("sha256:") then
					id := lid.substring (8, lid.count).to_string_8
				else
					id := lid.to_string_8
				end
				if id.count >= 12 then
					short_id := id.substring (1, 12)
				else
					short_id := id
				end
			else
				id := ""
				short_id := ""
			end

			-- RepoTags
			l_tags := a_json.array_item ("RepoTags")
			if attached l_tags as lt then
				from i := 1 until i > lt.count loop
					if attached lt.string_item (i) as s then
						repo_tags.extend (s.to_string_8)
					end
					i := i + 1
				end
			end

			-- RepoDigests
			l_digests := a_json.array_item ("RepoDigests")
			if attached l_digests as ld then
				from i := 1 until i > ld.count loop
					if attached ld.string_item (i) as s then
						repo_digests.extend (s.to_string_8)
					end
					i := i + 1
				end
			end

			-- ParentId
			if attached a_json.string_item ("ParentId") as pid then
				parent_id := pid.to_string_8
			end

			-- Created (Unix timestamp)
			created_timestamp := a_json.integer_item ("Created")

			-- Size
			size := a_json.integer_item ("Size")

			-- VirtualSize
			virtual_size := a_json.integer_item ("VirtualSize")

			-- SharedSize
			shared_size := a_json.integer_item ("SharedSize")

			-- Containers
			containers := a_json.integer_item ("Containers").to_integer

			-- Labels
			l_labels := a_json.object_item ("Labels")
			if attached l_labels as ll then
				across ll.keys as k loop
					if attached ll.string_item (k) as v then
						labels.extend ([k.to_string_8, v.to_string_8])
					end
				end
			end
		end

feature -- Access

	id: STRING
			-- Full image ID (64 hex chars, without sha256: prefix).

	short_id: STRING
			-- Short image ID (12 chars).

	repo_tags: ARRAYED_LIST [STRING]
			-- Repository tags (e.g., "nginx:latest", "nginx:1.25").

	repo_digests: ARRAYED_LIST [STRING]
			-- Repository digests.

	parent_id: detachable STRING
			-- Parent image ID.

	created_timestamp: INTEGER_64
			-- Unix timestamp of creation.

	size: INTEGER_64
			-- Image size in bytes.

	virtual_size: INTEGER_64
			-- Virtual size in bytes.

	shared_size: INTEGER_64
			-- Shared size in bytes.

	containers: INTEGER
			-- Number of containers using this image.

	labels: ARRAYED_LIST [TUPLE [key, value: STRING]]
			-- Image labels.

feature -- Queries

	primary_tag: detachable STRING
			-- Primary tag (first in repo_tags list).
		do
			if not repo_tags.is_empty then
				Result := repo_tags.first
			end
		end

	repository: detachable STRING
			-- Repository name (without tag).
		local
			l_tag: detachable STRING
			l_colon: INTEGER
		do
			l_tag := primary_tag
			if attached l_tag as t then
				l_colon := t.last_index_of (':', t.count)
				if l_colon > 0 then
					Result := t.substring (1, l_colon - 1)
				else
					Result := t
				end
			end
		end

	tag: detachable STRING
			-- Tag part of primary tag.
		local
			l_tag: detachable STRING
			l_colon: INTEGER
		do
			l_tag := primary_tag
			if attached l_tag as t then
				l_colon := t.last_index_of (':', t.count)
				if l_colon > 0 and l_colon < t.count then
					Result := t.substring (l_colon + 1, t.count)
				end
			end
		end

	has_tag (a_tag: STRING): BOOLEAN
			-- Does image have `a_tag'?
		require
			tag_not_void: a_tag /= Void
			tag_not_empty: not a_tag.is_empty
		do
			across repo_tags as t loop
				if t.same_string (a_tag) or else t.ends_with (":" + a_tag) then
					Result := True
				end
			end
		ensure
			found_in_tags: Result implies (across repo_tags as t some
				t.same_string (a_tag) or else t.ends_with (":" + a_tag) end)
		end

	matches (a_reference: STRING): BOOLEAN
			-- Does image match `a_reference' (name:tag or ID)?
		require
			reference_not_void: a_reference /= Void
			reference_not_empty: not a_reference.is_empty
		do
			-- Check against ID
			if id.starts_with (a_reference) or else short_id.same_string (a_reference) then
				Result := True
			else
				-- Check against repo tags
				across repo_tags as t loop
					if t.same_string (a_reference) then
						Result := True
					end
				end
			end
		ensure
			id_match_detected: id.starts_with (a_reference) implies Result
			short_id_match_detected: short_id.same_string (a_reference) implies Result
		end

	size_mb: REAL_64
			-- Size in megabytes.
		do
			Result := size / (1024.0 * 1024.0)
		ensure
			non_negative: Result >= 0
			consistent_with_size: size >= 0 implies Result >= 0
		end

feature -- Output

	out: STRING
			-- String representation.
		do
			create Result.make (100)
			Result.append (short_id)
			if attached primary_tag as pt then
				Result.append (" ")
				Result.append (pt)
			end
			Result.append (" (")
			Result.append (size_mb.truncated_to_integer.out)
			Result.append (" MB)")
		end

invariant
	id_exists: id /= Void
	short_id_exists: short_id /= Void
	short_id_length_valid: short_id.count <= 12
	short_id_consistency: (not id.is_empty and id.count >= short_id.count) implies id.starts_with (short_id)
	repo_tags_exists: repo_tags /= Void
	repo_digests_exists: repo_digests /= Void
	labels_exists: labels /= Void
	-- Note: size values can be -1 in Docker API for "unknown", so we don't enforce non_negative
	non_negative_containers: containers >= -1

end
