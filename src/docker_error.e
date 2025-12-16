note
	description: "[
		Docker operation error representation.

		Captures error information from Docker API responses:
		- HTTP status code
		- Error message
		- Error type classification
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	DOCKER_ERROR

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_from_response,
	make_connection_error,
	make_timeout_error

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_message: STRING)
			-- Create error with `a_code' and `a_message'.
		require
			message_not_empty: not a_message.is_empty
		do
			status_code := a_code
			message := a_message
			error_type := type_from_code (a_code)
		ensure
			code_set: status_code = a_code
			message_set: message.same_string (a_message)
		end

	make_from_response (a_status: INTEGER; a_body: STRING)
			-- Create error from HTTP response.
		require
			body_not_void: a_body /= Void
		do
			status_code := a_status
			if a_body.is_empty then
				message := default_message_for_code (a_status)
			else
				message := extract_message (a_body)
			end
			error_type := type_from_code (a_status)
		end

	make_connection_error (a_message: STRING)
			-- Create connection error.
		require
			message_not_void: a_message /= Void
			message_not_empty: not a_message.is_empty
		do
			status_code := 0
			message := a_message
			error_type := connection_error
		ensure
			is_connection_type: is_connection_error
			status_zero: status_code = 0
			message_set: message.same_string (a_message)
		end

	make_timeout_error (a_operation: STRING)
			-- Create timeout error for `a_operation'.
		require
			operation_not_void: a_operation /= Void
			operation_not_empty: not a_operation.is_empty
		do
			status_code := 0
			message := "Timeout during: " + a_operation
			error_type := timeout_error
		ensure
			is_timeout_type: is_timeout_error
			status_zero: status_code = 0
			message_contains_operation: message.has_substring (a_operation)
		end

feature -- Access

	status_code: INTEGER
			-- HTTP status code (0 for non-HTTP errors).

	message: STRING
			-- Error message.

	error_type: INTEGER
			-- Error type classification.

feature -- Error Type Constants

	connection_error: INTEGER = 1
			-- Failed to connect to Docker daemon.

	timeout_error: INTEGER = 2
			-- Operation timed out.

	not_found_error: INTEGER = 3
			-- Resource not found (404).

	conflict_error: INTEGER = 4
			-- Resource conflict (409).

	server_error: INTEGER = 5
			-- Docker daemon error (500+).

	client_error: INTEGER = 6
			-- Client request error (400-499).

	unknown_error: INTEGER = 0
			-- Unknown error type.

feature -- Queries

	is_connection_error: BOOLEAN
			-- Is this a connection error?
		do
			Result := error_type = connection_error
		ensure
			definition: Result = (error_type = connection_error)
		end

	is_timeout_error: BOOLEAN
			-- Is this a timeout error?
		do
			Result := error_type = timeout_error
		ensure
			definition: Result = (error_type = timeout_error)
		end

	is_not_found: BOOLEAN
			-- Is this a not-found error?
		do
			Result := error_type = not_found_error or else status_code = 404
		ensure
			status_404_implies_not_found: status_code = 404 implies Result
		end

	is_conflict: BOOLEAN
			-- Is this a conflict error?
		do
			Result := error_type = conflict_error or else status_code = 409
		ensure
			status_409_implies_conflict: status_code = 409 implies Result
		end

	is_server_error: BOOLEAN
			-- Is this a server error?
		do
			Result := error_type = server_error or else status_code >= 500
		ensure
			status_500_plus_implies_server_error: status_code >= 500 implies Result
		end

	is_retryable: BOOLEAN
			-- Should this error be retried?
		do
			Result := is_timeout_error or else
				is_connection_error or else
				status_code = 503 -- Service unavailable
		ensure
			timeout_is_retryable: is_timeout_error implies Result
			connection_is_retryable: is_connection_error implies Result
			service_unavailable_retryable: status_code = 503 implies Result
		end

feature -- Output

	out: STRING
			-- String representation.
		do
			create Result.make (100)
			Result.append ("DockerError[")
			if status_code > 0 then
				Result.append ("HTTP ")
				Result.append_integer (status_code)
				Result.append (": ")
			end
			Result.append (message)
			Result.append ("]")
		end

feature {NONE} -- Implementation

	type_from_code (a_code: INTEGER): INTEGER
			-- Determine error type from HTTP status code.
		do
			if a_code = 0 then
				Result := unknown_error
			elseif a_code = 404 then
				Result := not_found_error
			elseif a_code = 409 then
				Result := conflict_error
			elseif a_code >= 500 then
				Result := server_error
			elseif a_code >= 400 then
				Result := client_error
			else
				Result := unknown_error
			end
		end

	default_message_for_code (a_code: INTEGER): STRING
			-- Default message for HTTP status code.
		do
			inspect a_code
			when 400 then Result := "Bad request"
			when 404 then Result := "Not found"
			when 409 then Result := "Conflict"
			when 500 then Result := "Internal server error"
			when 503 then Result := "Service unavailable"
			else
				Result := "HTTP error " + a_code.out
			end
		end

	extract_message (a_body: STRING): STRING
			-- Extract error message from JSON body.
		local
			l_json: SIMPLE_JSON
			l_msg: detachable STRING_32
		do
			create l_json
			if attached l_json.parse (a_body) as v and then v.is_object then
				l_msg := v.as_object.string_item ("message")
				if l_msg = Void then
					l_msg := v.as_object.string_item ("error")
				end
			end
			if attached l_msg as m and then not m.is_empty then
				Result := m.to_string_8
			else
				Result := a_body
			end
		end

invariant
	message_not_void: message /= Void
	message_not_empty: not message.is_empty
	valid_error_type: error_type >= unknown_error and error_type <= client_error
	non_negative_status: status_code >= 0

end
