note
	description: "[
		Container lifecycle state constants.

		Docker container states:
		- created: Container exists but never started
		- running: Container is running
		- paused: Container processes suspended
		- restarting: Container is restarting
		- removing: Container is being removed
		- exited: Container stopped (check exit code)
		- dead: Container failed to stop properly
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CONTAINER_STATE

feature -- State Constants

	created: STRING = "created"
			-- Container exists but never started.

	running: STRING = "running"
			-- Container is running.

	paused: STRING = "paused"
			-- Container processes suspended.

	restarting: STRING = "restarting"
			-- Container is restarting.

	removing: STRING = "removing"
			-- Container is being removed.

	exited: STRING = "exited"
			-- Container stopped (check exit code).

	dead: STRING = "dead"
			-- Container failed to stop properly.

feature -- Queries

	is_valid_state (a_state: STRING): BOOLEAN
			-- Is `a_state' a valid container state?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (created) or else
				a_state.same_string (running) or else
				a_state.same_string (paused) or else
				a_state.same_string (restarting) or else
				a_state.same_string (removing) or else
				a_state.same_string (exited) or else
				a_state.same_string (dead)
		ensure
			known_states_valid: a_state.same_string (created) or else
				a_state.same_string (running) or else
				a_state.same_string (exited) implies Result
		end

	is_running_state (a_state: STRING): BOOLEAN
			-- Is `a_state' an active/running state?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (running) or else
				a_state.same_string (restarting)
		ensure
			running_implies_result: a_state.same_string (running) implies Result
			stopped_implies_not_running: is_stopped_state (a_state) implies not Result
		end

	is_stopped_state (a_state: STRING): BOOLEAN
			-- Is `a_state' a stopped state?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (created) or else
				a_state.same_string (exited) or else
				a_state.same_string (dead)
		ensure
			exited_implies_stopped: a_state.same_string (exited) implies Result
			running_not_stopped: a_state.same_string (running) implies not Result
		end

	can_start (a_state: STRING): BOOLEAN
			-- Can container be started from `a_state'?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (created) or else
				a_state.same_string (exited)
		ensure
			created_can_start: a_state.same_string (created) implies Result
			running_cannot_start: a_state.same_string (running) implies not Result
		end

	can_stop (a_state: STRING): BOOLEAN
			-- Can container be stopped from `a_state'?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (running) or else
				a_state.same_string (paused) or else
				a_state.same_string (restarting)
		ensure
			running_can_stop: a_state.same_string (running) implies Result
			exited_cannot_stop: a_state.same_string (exited) implies not Result
		end

	can_pause (a_state: STRING): BOOLEAN
			-- Can container be paused from `a_state'?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (running)
		ensure
			only_running_can_pause: Result implies a_state.same_string (running)
		end

	can_remove (a_state: STRING): BOOLEAN
			-- Can container be removed from `a_state'?
		require
			state_not_void: a_state /= Void
			state_not_empty: not a_state.is_empty
		do
			Result := a_state.same_string (created) or else
				a_state.same_string (exited) or else
				a_state.same_string (dead)
		ensure
			exited_can_remove: a_state.same_string (exited) implies Result
			running_cannot_remove: a_state.same_string (running) implies not Result
		end

end
