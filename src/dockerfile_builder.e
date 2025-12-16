note
	description: "[
		Fluent builder for Dockerfile generation.

		Generates valid Dockerfile content with proper instruction ordering
		and syntax. Supports multi-stage builds.

		Example:
			create builder.make ("alpine:latest")
			builder.run ("apk add --no-cache curl")
				.workdir ("/app")
				.copy_files (".", ".")
				.expose (8080)
				.cmd (<<"./myapp">>)

			dockerfile_content := builder.to_string
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKERFILE_BUILDER

create
	make,
	make_multi_stage

feature {NONE} -- Initialization

	make (a_base_image: STRING)
			-- Create builder with base image.
		require
			image_not_void: a_base_image /= Void
			image_not_empty: not a_base_image.is_empty
		do
			base_image := a_base_image
			create instructions.make (20)
			create stages.make (1)
			current_stage := 0
		ensure
			base_image_set: base_image.same_string (a_base_image)
			instructions_empty: instructions.is_empty
		end

	make_multi_stage
			-- Create builder for multi-stage build (no initial FROM).
		do
			base_image := ""
			create instructions.make (20)
			create stages.make (3)
			current_stage := -1
			is_multi_stage := True
		ensure
			multi_stage_mode: is_multi_stage
		end

feature -- Access

	base_image: STRING
			-- Base image for FROM instruction.

	instructions: ARRAYED_LIST [STRING]
			-- Dockerfile instructions for current stage.

	stages: ARRAYED_LIST [TUPLE [name: detachable STRING; image: STRING; instructions: ARRAYED_LIST [STRING]]]
			-- Build stages for multi-stage builds.

	current_stage: INTEGER
			-- Current stage index (-1 if no stage started).

	is_multi_stage: BOOLEAN
			-- Is this a multi-stage build?

feature -- FROM instruction

	from_image (a_image: STRING): like Current
			-- Add FROM instruction (starts new stage in multi-stage build).
		require
			image_not_void: a_image /= Void
			image_not_empty: not a_image.is_empty
		do
			if is_multi_stage then
				save_current_stage
				current_stage := current_stage + 1
				base_image := a_image
				create instructions.make (20)
			else
				base_image := a_image
			end
			Result := Current
		ensure
			result_is_current: Result = Current
			image_set: base_image.same_string (a_image)
		end

	from_image_as (a_image: STRING; a_stage_name: STRING): like Current
			-- Add FROM instruction with stage name for multi-stage build.
			-- Automatically enables multi-stage mode if not already enabled.
		require
			image_not_void: a_image /= Void
			image_not_empty: not a_image.is_empty
			stage_name_not_void: a_stage_name /= Void
			stage_name_not_empty: not a_stage_name.is_empty
		do
			-- Auto-enable multi-stage mode when using named stages
			if not is_multi_stage then
				is_multi_stage := True
				current_stage := -1
			end
			save_current_stage
			current_stage := current_stage + 1
			base_image := a_image
			stage_name := a_stage_name
			create instructions.make (20)
			Result := Current
		ensure
			result_is_current: Result = Current
			image_set: base_image.same_string (a_image)
			stage_name_set: attached stage_name as sn and then sn.same_string (a_stage_name)
			multi_stage_enabled: is_multi_stage
		end

feature -- RUN instruction

	run (a_command: STRING): like Current
			-- Add RUN instruction with shell form.
		require
			command_not_void: a_command /= Void
			command_not_empty: not a_command.is_empty
		do
			instructions.extend ("RUN " + a_command)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	run_exec (a_args: ARRAY [STRING]): like Current
			-- Add RUN instruction with exec form.
		require
			args_not_void: a_args /= Void
			args_not_empty: not a_args.is_empty
		do
			instructions.extend ("RUN " + array_to_json (a_args))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	run_multi (a_commands: ARRAY [STRING]): like Current
			-- Add RUN instruction with multiple commands joined by &&.
		require
			commands_not_void: a_commands /= Void
			commands_not_empty: not a_commands.is_empty
		local
			l_cmd: STRING
			i: INTEGER
		do
			create l_cmd.make (200)
			l_cmd.append ("RUN ")
			from i := a_commands.lower until i > a_commands.upper loop
				if i > a_commands.lower then
					l_cmd.append (" && %N    ")
				end
				l_cmd.append (a_commands [i])
				i := i + 1
			end
			instructions.extend (l_cmd)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- COPY instruction

	copy_files (a_src, a_dest: STRING): like Current
			-- Add COPY instruction.
		require
			src_not_void: a_src /= Void
			src_not_empty: not a_src.is_empty
			dest_not_void: a_dest /= Void
			dest_not_empty: not a_dest.is_empty
		do
			instructions.extend ("COPY " + a_src + " " + a_dest)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	copy_from (a_stage: STRING; a_src, a_dest: STRING): like Current
			-- Add COPY --from instruction for multi-stage build.
		require
			stage_not_void: a_stage /= Void
			stage_not_empty: not a_stage.is_empty
			src_not_void: a_src /= Void
			src_not_empty: not a_src.is_empty
			dest_not_void: a_dest /= Void
			dest_not_empty: not a_dest.is_empty
		do
			instructions.extend ("COPY --from=" + a_stage + " " + a_src + " " + a_dest)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	copy_chown (a_src, a_dest, a_user: STRING): like Current
			-- Add COPY instruction with --chown.
		require
			src_not_void: a_src /= Void
			src_not_empty: not a_src.is_empty
			dest_not_void: a_dest /= Void
			dest_not_empty: not a_dest.is_empty
			user_not_void: a_user /= Void
			user_not_empty: not a_user.is_empty
		do
			instructions.extend ("COPY --chown=" + a_user + " " + a_src + " " + a_dest)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- ADD instruction

	add (a_src, a_dest: STRING): like Current
			-- Add ADD instruction.
		require
			src_not_void: a_src /= Void
			src_not_empty: not a_src.is_empty
			dest_not_void: a_dest /= Void
			dest_not_empty: not a_dest.is_empty
		do
			instructions.extend ("ADD " + a_src + " " + a_dest)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- WORKDIR instruction

	workdir (a_dir: STRING): like Current
			-- Add WORKDIR instruction.
		require
			dir_not_void: a_dir /= Void
			dir_not_empty: not a_dir.is_empty
		do
			instructions.extend ("WORKDIR " + a_dir)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- ENV instruction

	env (a_key, a_value: STRING): like Current
			-- Add ENV instruction.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
			value_not_void: a_value /= Void
		do
			instructions.extend ("ENV " + a_key + "=" + escape_value (a_value))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	env_multi (a_vars: ARRAY [TUPLE [key, value: STRING]]): like Current
			-- Add ENV instruction with multiple variables.
		require
			vars_not_void: a_vars /= Void
			vars_not_empty: not a_vars.is_empty
		local
			l_env: STRING
			i: INTEGER
		do
			create l_env.make (100)
			l_env.append ("ENV ")
			from i := a_vars.lower until i > a_vars.upper loop
				if i > a_vars.lower then
					l_env.append (" %N    ")
				end
				l_env.append (a_vars [i].key)
				l_env.append ("=")
				l_env.append (escape_value (a_vars [i].value))
				i := i + 1
			end
			instructions.extend (l_env)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- EXPOSE instruction

	expose (a_port: INTEGER): like Current
			-- Add EXPOSE instruction for TCP port.
		require
			port_valid: a_port > 0 and a_port <= 65535
		do
			instructions.extend ("EXPOSE " + a_port.out)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	expose_udp (a_port: INTEGER): like Current
			-- Add EXPOSE instruction for UDP port.
		require
			port_valid: a_port > 0 and a_port <= 65535
		do
			instructions.extend ("EXPOSE " + a_port.out + "/udp")
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	expose_range (a_start, a_end: INTEGER): like Current
			-- Add EXPOSE instruction for port range.
		require
			start_valid: a_start > 0 and a_start <= 65535
			end_valid: a_end > 0 and a_end <= 65535
			range_valid: a_start <= a_end
		do
			instructions.extend ("EXPOSE " + a_start.out + "-" + a_end.out)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- CMD instruction

	cmd (a_args: ARRAY [STRING]): like Current
			-- Add CMD instruction with exec form.
		require
			args_not_void: a_args /= Void
			args_not_empty: not a_args.is_empty
		do
			instructions.extend ("CMD " + array_to_json (a_args))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	cmd_shell (a_command: STRING): like Current
			-- Add CMD instruction with shell form.
		require
			command_not_void: a_command /= Void
			command_not_empty: not a_command.is_empty
		do
			instructions.extend ("CMD " + a_command)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- ENTRYPOINT instruction

	entrypoint (a_args: ARRAY [STRING]): like Current
			-- Add ENTRYPOINT instruction with exec form.
		require
			args_not_void: a_args /= Void
			args_not_empty: not a_args.is_empty
		do
			instructions.extend ("ENTRYPOINT " + array_to_json (a_args))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	entrypoint_shell (a_command: STRING): like Current
			-- Add ENTRYPOINT instruction with shell form.
		require
			command_not_void: a_command /= Void
			command_not_empty: not a_command.is_empty
		do
			instructions.extend ("ENTRYPOINT " + a_command)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- LABEL instruction

	label (a_key, a_value: STRING): like Current
			-- Add LABEL instruction.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
			value_not_void: a_value /= Void
		do
			instructions.extend ("LABEL " + a_key + "=" + escape_value (a_value))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	label_multi (a_labels: ARRAY [TUPLE [key, value: STRING]]): like Current
			-- Add LABEL instruction with multiple labels.
		require
			labels_not_void: a_labels /= Void
			labels_not_empty: not a_labels.is_empty
		local
			l_label: STRING
			i: INTEGER
		do
			create l_label.make (100)
			l_label.append ("LABEL ")
			from i := a_labels.lower until i > a_labels.upper loop
				if i > a_labels.lower then
					l_label.append (" %N      ")
				end
				l_label.append (a_labels [i].key)
				l_label.append ("=")
				l_label.append (escape_value (a_labels [i].value))
				i := i + 1
			end
			instructions.extend (l_label)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- ARG instruction

	arg (a_name: STRING): like Current
			-- Add ARG instruction without default value.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
		do
			instructions.extend ("ARG " + a_name)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	arg_default (a_name, a_default: STRING): like Current
			-- Add ARG instruction with default value.
		require
			name_not_void: a_name /= Void
			name_not_empty: not a_name.is_empty
			default_not_void: a_default /= Void
		do
			instructions.extend ("ARG " + a_name + "=" + escape_value (a_default))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- USER instruction

	user (a_user: STRING): like Current
			-- Add USER instruction.
		require
			user_not_void: a_user /= Void
			user_not_empty: not a_user.is_empty
		do
			instructions.extend ("USER " + a_user)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	user_group (a_user, a_group: STRING): like Current
			-- Add USER instruction with group.
		require
			user_not_void: a_user /= Void
			user_not_empty: not a_user.is_empty
			group_not_void: a_group /= Void
			group_not_empty: not a_group.is_empty
		do
			instructions.extend ("USER " + a_user + ":" + a_group)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- VOLUME instruction

	volume (a_path: STRING): like Current
			-- Add VOLUME instruction.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
		do
			instructions.extend ("VOLUME " + a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	volume_multi (a_paths: ARRAY [STRING]): like Current
			-- Add VOLUME instruction with multiple paths.
		require
			paths_not_void: a_paths /= Void
			paths_not_empty: not a_paths.is_empty
		do
			instructions.extend ("VOLUME " + array_to_json (a_paths))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- HEALTHCHECK instruction

	healthcheck (a_cmd: STRING): like Current
			-- Add HEALTHCHECK instruction.
		require
			cmd_not_void: a_cmd /= Void
			cmd_not_empty: not a_cmd.is_empty
		do
			instructions.extend ("HEALTHCHECK CMD " + a_cmd)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	healthcheck_options (a_cmd: STRING; a_interval, a_timeout, a_retries: INTEGER): like Current
			-- Add HEALTHCHECK instruction with options.
		require
			cmd_not_void: a_cmd /= Void
			cmd_not_empty: not a_cmd.is_empty
			interval_positive: a_interval > 0
			timeout_positive: a_timeout > 0
			retries_positive: a_retries > 0
		do
			instructions.extend ("HEALTHCHECK --interval=" + a_interval.out + "s --timeout=" +
				a_timeout.out + "s --retries=" + a_retries.out + " CMD " + a_cmd)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	healthcheck_none: like Current
			-- Add HEALTHCHECK NONE instruction.
		do
			instructions.extend ("HEALTHCHECK NONE")
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- SHELL instruction

	shell (a_shell: ARRAY [STRING]): like Current
			-- Add SHELL instruction.
		require
			shell_not_void: a_shell /= Void
			shell_not_empty: not a_shell.is_empty
		do
			instructions.extend ("SHELL " + array_to_json (a_shell))
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- STOPSIGNAL instruction

	stopsignal (a_signal: STRING): like Current
			-- Add STOPSIGNAL instruction.
		require
			signal_not_void: a_signal /= Void
			signal_not_empty: not a_signal.is_empty
		do
			instructions.extend ("STOPSIGNAL " + a_signal)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- Comments

	comment (a_text: STRING): like Current
			-- Add comment line.
		require
			text_not_void: a_text /= Void
		do
			instructions.extend ("# " + a_text)
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

	blank_line: like Current
			-- Add blank line.
		do
			instructions.extend ("")
			Result := Current
		ensure
			result_is_current: Result = Current
			instruction_added: instructions.count = old instructions.count + 1
		end

feature -- Output

	to_string: STRING
			-- Generate Dockerfile content.
		local
			l_result: STRING
		do
			create l_result.make (1000)

			if is_multi_stage then
				-- Save current stage first
				save_current_stage

				-- Output all stages
				across stages as s loop
					if attached s.name as sn then
						l_result.append ("FROM " + s.image + " AS " + sn + "%N")
					else
						l_result.append ("FROM " + s.image + "%N")
					end
					across s.instructions as instr loop
						l_result.append (instr + "%N")
					end
					l_result.append ("%N")
				end
			else
				-- Single stage
				l_result.append ("FROM " + base_image + "%N")
				if attached stage_name as sn then
					-- Shouldn't happen in non-multi-stage, but handle it
				end
				across instructions as instr loop
					l_result.append (instr + "%N")
				end
			end

			Result := l_result
		ensure
			result_not_void: Result /= Void
			result_not_empty: not Result.is_empty
		end

	save_to_file (a_path: STRING): BOOLEAN
			-- Save Dockerfile to file. Returns True on success.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_open_write (a_path)
			if l_file.is_open_write then
				l_file.put_string (to_string)
				l_file.close
				Result := True
			end
		end

feature {NONE} -- Implementation

	stage_name: detachable STRING
			-- Current stage name (for multi-stage builds).

	save_current_stage
			-- Save current stage to stages list.
			-- Only saves if there's actual content (image or instructions).
		local
			l_stage: TUPLE [name: detachable STRING; image: STRING; instructions: ARRAYED_LIST [STRING]]
		do
			-- Only save if we have content: either instructions or a base image with a stage name
			if not base_image.is_empty and (not instructions.is_empty or attached stage_name) then
				l_stage := [stage_name, base_image, instructions]
				stages.extend (l_stage)
				stage_name := Void
			end
		end

	array_to_json (a_array: ARRAY [STRING]): STRING
			-- Convert array to JSON array format.
		local
			i: INTEGER
		do
			create Result.make (100)
			Result.append ("[")
			from i := a_array.lower until i > a_array.upper loop
				if i > a_array.lower then
					Result.append (", ")
				end
				Result.append ("%"")
				Result.append (escape_json_string (a_array [i]))
				Result.append ("%"")
				i := i + 1
			end
			Result.append ("]")
		end

	escape_value (a_value: STRING): STRING
			-- Escape value for Dockerfile (quote if contains spaces).
		do
			if a_value.has (' ') or a_value.has ('%T') or a_value.is_empty then
				create Result.make (a_value.count + 2)
				Result.append ("%"")
				Result.append (escape_json_string (a_value))
				Result.append ("%"")
			else
				Result := a_value
			end
		end

	escape_json_string (a_string: STRING): STRING
			-- Escape string for JSON.
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_string.count)
			from i := 1 until i > a_string.count loop
				c := a_string [i]
				inspect c
				when '%"' then Result.append ("\%"")
				when '\' then Result.append ("\\")
				when '%N' then Result.append ("\n")
				when '%R' then Result.append ("\r")
				when '%T' then Result.append ("\t")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

invariant
	instructions_exist: instructions /= Void
	stages_exist: stages /= Void
	base_image_exists: base_image /= Void
	current_stage_valid: is_multi_stage implies current_stage >= -1
	single_stage_has_image: not is_multi_stage implies not base_image.is_empty or instructions.is_empty

end
