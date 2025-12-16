note
	description: "[
		Configuration options for container log streaming.

		Controls what log output to capture and how to format it.
		Used with DOCKER_CLIENT.stream_container_logs.

		Usage:
			create options.make
			options.set_stdout (True)
			options.set_stderr (True)
			options.set_timestamps (True)
			options.set_tail (100)  -- Start with last 100 lines
			options.set_follow (True)  -- Keep streaming new lines
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	LOG_STREAM_OPTIONS

create
	make,
	make_default

feature {NONE} -- Initialization

	make
			-- Create with default options (stdout+stderr, no timestamps, follow).
		do
			stdout := True
			stderr := True
			timestamps := False
			follow := True
			tail := 0  -- All logs
			timeout_ms := 0  -- No timeout (infinite)
		ensure
			stdout_enabled: stdout
			stderr_enabled: stderr
			no_timestamps: not timestamps
			following: follow
			no_tail_limit: tail = 0
			no_timeout: timeout_ms = 0
		end

	make_default
			-- Alias for make.
		do
			make
		end

feature -- Access

	stdout: BOOLEAN
			-- Capture stdout stream?

	stderr: BOOLEAN
			-- Capture stderr stream?

	timestamps: BOOLEAN
			-- Include timestamps in log output?

	follow: BOOLEAN
			-- Follow log output (stream continuously)?
			-- If False, returns existing logs and exits.

	tail: INTEGER
			-- Number of lines to show from end of logs.
			-- 0 means all available logs.

	timeout_ms: INTEGER
			-- Timeout in milliseconds for stream operations.
			-- 0 means no timeout (wait indefinitely).
			-- Useful for preventing hangs on unresponsive containers.

feature -- Configuration (Fluent API)

	set_stdout (a_value: BOOLEAN): like Current
			-- Set stdout capture.
		do
			stdout := a_value
			Result := Current
		ensure
			stdout_set: stdout = a_value
			returns_self: Result = Current
		end

	set_stderr (a_value: BOOLEAN): like Current
			-- Set stderr capture.
		do
			stderr := a_value
			Result := Current
		ensure
			stderr_set: stderr = a_value
			returns_self: Result = Current
		end

	set_timestamps (a_value: BOOLEAN): like Current
			-- Set timestamp inclusion.
		do
			timestamps := a_value
			Result := Current
		ensure
			timestamps_set: timestamps = a_value
			returns_self: Result = Current
		end

	set_follow (a_value: BOOLEAN): like Current
			-- Set follow mode.
		do
			follow := a_value
			Result := Current
		ensure
			follow_set: follow = a_value
			returns_self: Result = Current
		end

	set_tail (a_value: INTEGER): like Current
			-- Set tail line count.
		require
			non_negative: a_value >= 0
		do
			tail := a_value
			Result := Current
		ensure
			tail_set: tail = a_value
			returns_self: Result = Current
		end

	set_timeout_ms (a_value: INTEGER): like Current
			-- Set stream timeout in milliseconds.
		require
			non_negative: a_value >= 0
		do
			timeout_ms := a_value
			Result := Current
		ensure
			timeout_set: timeout_ms = a_value
			returns_self: Result = Current
		end

feature -- Query

	is_valid: BOOLEAN
			-- Are options valid for streaming?
			-- At least one of stdout/stderr must be enabled.
		do
			Result := stdout or stderr
		ensure
			definition: Result = (stdout or stderr)
		end

	to_query_string: STRING
			-- Convert options to Docker API query string.
		do
			create Result.make (100)
			Result.append ("stdout=")
			Result.append (stdout.out.as_lower)
			Result.append ("&stderr=")
			Result.append (stderr.out.as_lower)
			Result.append ("&timestamps=")
			Result.append (timestamps.out.as_lower)
			Result.append ("&follow=")
			Result.append (follow.out.as_lower)
			if tail > 0 then
				Result.append ("&tail=")
				Result.append (tail.out)
			end
		ensure
			not_empty: not Result.is_empty
			has_stdout: Result.has_substring ("stdout=")
			has_stderr: Result.has_substring ("stderr=")
			has_follow: Result.has_substring ("follow=")
		end

invariant
	tail_non_negative: tail >= 0
	timeout_non_negative: timeout_ms >= 0

end
