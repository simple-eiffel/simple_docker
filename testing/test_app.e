note
	description: "[
		Test application for simple_docker.

		PREREQUISITES:
		- Docker Desktop must be running on Windows
		- Tests connect via named pipe \\.\pipe\docker_engine
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature -- Initialization

	make
			-- Run tests.
		local
			l_tests: LIB_TESTS
		do
			print ("Testing SIMPLE_DOCKER v1.4.1...%N")

			create l_tests
			if l_tests.docker_available then
				print ("Docker daemon: reachable%N%N")
			else
				print ("Docker daemon: NOT reachable - tests that need it are SKIPPED (" + l_tests.docker_unavailable_reason + ")%N%N")
			end

			-- Connection tests
			print ("=== Connection Tests ===%N")
			run_docker_test (l_tests, "test_ping", agent l_tests.test_ping)
			run_docker_test (l_tests, "test_version", agent l_tests.test_version)
			run_docker_test (l_tests, "test_info", agent l_tests.test_info)

			-- Image tests
			print ("%N=== Image Tests ===%N")
			run_docker_test (l_tests, "test_list_images", agent l_tests.test_list_images)
			run_docker_test (l_tests, "test_image_exists_alpine", agent l_tests.test_image_exists_alpine)
			run_test (l_tests, "test_build_dockerfile_builder_generates_valid_output", agent l_tests.test_build_dockerfile_builder_generates_valid_output)

			-- Container tests
			print ("%N=== Container Tests ===%N")
			run_docker_test (l_tests, "test_list_containers", agent l_tests.test_list_containers)
			run_docker_test (l_tests, "test_create_and_remove_container", agent l_tests.test_create_and_remove_container)
			run_docker_test (l_tests, "test_container_lifecycle", agent l_tests.test_container_lifecycle)

			-- Spec tests
			print ("%N=== Spec Tests ===%N")
			run_test (l_tests, "test_spec_basic", agent l_tests.test_spec_basic)
			run_test (l_tests, "test_spec_fluent_api", agent l_tests.test_spec_fluent_api)
			run_test (l_tests, "test_spec_to_json", agent l_tests.test_spec_to_json)

			-- State tests
			print ("%N=== State Tests ===%N")
			run_test (l_tests, "test_state_constants", agent l_tests.test_state_constants)
			run_test (l_tests, "test_state_transitions", agent l_tests.test_state_transitions)

			-- Error tests
			print ("%N=== Error Tests ===%N")
			run_test (l_tests, "test_error_creation", agent l_tests.test_error_creation)
			run_test (l_tests, "test_error_connection", agent l_tests.test_error_connection)

			-- Dockerfile Builder tests (P2)
			print ("%N=== Dockerfile Builder Tests (P2) ===%N")
			run_test (l_tests, "test_dockerfile_basic", agent l_tests.test_dockerfile_basic)
			run_test (l_tests, "test_dockerfile_fluent_api", agent l_tests.test_dockerfile_fluent_api)
			run_test (l_tests, "test_dockerfile_multistage", agent l_tests.test_dockerfile_multistage)
			run_test (l_tests, "test_dockerfile_labels_and_args", agent l_tests.test_dockerfile_labels_and_args)

			-- Network tests (P2)
			print ("%N=== Network Tests (P2) ===%N")
			run_test (l_tests, "test_network_creation", agent l_tests.test_network_creation)
			run_test (l_tests, "test_network_queries", agent l_tests.test_network_queries)
			run_docker_test (l_tests, "test_list_networks", agent l_tests.test_list_networks)
			run_docker_test (l_tests, "test_create_and_remove_network", agent l_tests.test_create_and_remove_network)

			-- Volume tests (P2)
			print ("%N=== Volume Tests (P2) ===%N")
			run_test (l_tests, "test_volume_creation", agent l_tests.test_volume_creation)
			run_test (l_tests, "test_volume_anonymous_detection", agent l_tests.test_volume_anonymous_detection)
			run_docker_test (l_tests, "test_list_volumes", agent l_tests.test_list_volumes)
			run_docker_test (l_tests, "test_create_and_remove_volume", agent l_tests.test_create_and_remove_volume)

			-- Exec tests (P2)
			print ("%N=== Exec Tests (P2) ===%N")
			run_docker_test (l_tests, "test_exec_in_container", agent l_tests.test_exec_in_container)

			-- Cookbook verification tests (dogfooding)
			print ("%N=== Cookbook Verification Tests ===%N")
			run_test (l_tests, "test_cookbook_spec_add_port", agent l_tests.test_cookbook_spec_add_port)
			run_test (l_tests, "test_cookbook_spec_add_volume", agent l_tests.test_cookbook_spec_add_volume)
			run_test (l_tests, "test_cookbook_spec_restart_policy", agent l_tests.test_cookbook_spec_restart_policy)
			run_test (l_tests, "test_cookbook_spec_hostname", agent l_tests.test_cookbook_spec_hostname)
			run_test (l_tests, "test_cookbook_spec_memory_limit", agent l_tests.test_cookbook_spec_memory_limit)
			run_test (l_tests, "test_cookbook_spec_auto_remove", agent l_tests.test_cookbook_spec_auto_remove)
			run_test (l_tests, "test_cookbook_container_exit_code", agent l_tests.test_cookbook_container_exit_code)
			run_test (l_tests, "test_cookbook_container_is_dead", agent l_tests.test_cookbook_container_is_dead)
			run_test (l_tests, "test_cookbook_image_primary_tag", agent l_tests.test_cookbook_image_primary_tag)
			run_test (l_tests, "test_cookbook_error_is_retryable", agent l_tests.test_cookbook_error_is_retryable)

			-- Log Stream Options tests (P3 - Happy Path)
			print ("%N=== Log Stream Tests (P3 - Happy Path) ===%N")
			run_test (l_tests, "test_log_stream_options_defaults", agent l_tests.test_log_stream_options_defaults)
			run_test (l_tests, "test_log_stream_options_fluent_api", agent l_tests.test_log_stream_options_fluent_api)
			run_test (l_tests, "test_log_stream_options_to_query_string", agent l_tests.test_log_stream_options_to_query_string)
			run_test (l_tests, "test_log_stream_options_no_tail_in_query", agent l_tests.test_log_stream_options_no_tail_in_query)
			run_docker_test (l_tests, "test_stream_container_logs_happy_path", agent l_tests.test_stream_container_logs_happy_path)

			-- Log Stream Edge Cases tests (P3)
			print ("%N=== Log Stream Tests (P3 - Edge Cases) ===%N")
			run_test (l_tests, "test_log_stream_options_invalid", agent l_tests.test_log_stream_options_invalid)
			run_docker_test (l_tests, "test_stream_logs_nonexistent_container", agent l_tests.test_stream_logs_nonexistent_container)
			run_docker_test (l_tests, "test_stream_logs_callback_stops_streaming", agent l_tests.test_stream_logs_callback_stops_streaming)
			run_docker_test (l_tests, "test_stream_logs_stopped_container", agent l_tests.test_stream_logs_stopped_container)
			run_docker_test (l_tests, "test_stream_logs_timeout_behavior", agent l_tests.test_stream_logs_timeout_behavior)

			-- SIMPLE_DOCKER_QUICK tests (Beginner API)
			print ("%N=== SIMPLE_DOCKER_QUICK Tests (Happy Path) ===%N")
			run_docker_test (l_tests, "test_quick_is_available", agent l_tests.test_quick_is_available)
			run_docker_test (l_tests, "test_quick_run_script", agent l_tests.test_quick_run_script)
			run_docker_test (l_tests, "test_quick_redis", agent l_tests.test_quick_redis)
			run_docker_test (l_tests, "test_quick_postgres", agent l_tests.test_quick_postgres)
			run_docker_test (l_tests, "test_quick_cleanup", agent l_tests.test_quick_cleanup)

			print ("%N=== SIMPLE_DOCKER_QUICK Tests (Edge Cases) ===%N")
			run_docker_test (l_tests, "test_quick_client_access", agent l_tests.test_quick_client_access)
			run_docker_test (l_tests, "test_quick_empty_script", agent l_tests.test_quick_empty_script)
			run_docker_test (l_tests, "test_quick_failing_script", agent l_tests.test_quick_failing_script)
			run_docker_test (l_tests, "test_quick_stop_all", agent l_tests.test_quick_stop_all)

			print ("%N======================================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed, " + skipped.out + " skipped%N")
			if skipped > 0 then
				print ("Skipped: " + l_tests.docker_unavailable_reason + "%N")
			end
		end

feature -- Access

	passed: INTEGER
			-- Tests that passed.

	failed: INTEGER
			-- Tests that failed.

	skipped: INTEGER
			-- Tests skipped because the Docker daemon is not reachable.

feature {NONE} -- Implementation

	run_docker_test (a_tests: LIB_TESTS; a_name: STRING; a_test: PROCEDURE)
			-- Run a test that needs the Docker daemon, or skip it (with the
			-- reason) when the daemon is not reachable.
		do
			if a_tests.docker_available then
				run_test (a_tests, a_name, a_test)
			else
				print ("  " + a_name + ": SKIPPED (" + a_tests.docker_unavailable_reason + ")%N")
				skipped := skipped + 1
			end
		end

	run_test (a_tests: LIB_TESTS; a_name: STRING; a_test: PROCEDURE)
			-- Run a single test, counting it as passed or failed.
			-- A failure still runs `on_clean', so the test's containers,
			-- networks and volumes are removed.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				print ("  " + a_name + ": ")
				a_tests.on_prepare
				a_test.call (Void)
				a_tests.on_clean
				print ("PASSED%N")
				passed := passed + 1
			else
				failed := failed + 1
			end
		rescue
			print ("FAILED")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception and then attached al_exception.description as al_description then
				print (" - " + al_description.to_string_8)
			end
			print ("%N")
			l_failed := True
			a_tests.on_clean
			retry
		end

end
