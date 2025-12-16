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
			l_passed, l_failed, l_total: INTEGER
		do
			print ("Testing SIMPLE_DOCKER v1.4.0...%N")
			print ("Requires Docker Desktop running%N%N")

			create l_tests

			-- Connection tests
			print ("=== Connection Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_ping", agent l_tests.test_ping)
			l_passed := l_passed + run_test (l_tests, "test_version", agent l_tests.test_version)
			l_passed := l_passed + run_test (l_tests, "test_info", agent l_tests.test_info)

			-- Image tests
			print ("%N=== Image Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_list_images", agent l_tests.test_list_images)
			l_passed := l_passed + run_test (l_tests, "test_image_exists_alpine", agent l_tests.test_image_exists_alpine)
			l_passed := l_passed + run_test (l_tests, "test_build_dockerfile_builder_generates_valid_output", agent l_tests.test_build_dockerfile_builder_generates_valid_output)

			-- Container tests
			print ("%N=== Container Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_list_containers", agent l_tests.test_list_containers)
			l_passed := l_passed + run_test (l_tests, "test_create_and_remove_container", agent l_tests.test_create_and_remove_container)
			l_passed := l_passed + run_test (l_tests, "test_container_lifecycle", agent l_tests.test_container_lifecycle)

			-- Spec tests
			print ("%N=== Spec Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_spec_basic", agent l_tests.test_spec_basic)
			l_passed := l_passed + run_test (l_tests, "test_spec_fluent_api", agent l_tests.test_spec_fluent_api)
			l_passed := l_passed + run_test (l_tests, "test_spec_to_json", agent l_tests.test_spec_to_json)

			-- State tests
			print ("%N=== State Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_state_constants", agent l_tests.test_state_constants)
			l_passed := l_passed + run_test (l_tests, "test_state_transitions", agent l_tests.test_state_transitions)

			-- Error tests
			print ("%N=== Error Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_error_creation", agent l_tests.test_error_creation)
			l_passed := l_passed + run_test (l_tests, "test_error_connection", agent l_tests.test_error_connection)

			-- Dockerfile Builder tests (P2)
			print ("%N=== Dockerfile Builder Tests (P2) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_dockerfile_basic", agent l_tests.test_dockerfile_basic)
			l_passed := l_passed + run_test (l_tests, "test_dockerfile_fluent_api", agent l_tests.test_dockerfile_fluent_api)
			l_passed := l_passed + run_test (l_tests, "test_dockerfile_multistage", agent l_tests.test_dockerfile_multistage)
			l_passed := l_passed + run_test (l_tests, "test_dockerfile_labels_and_args", agent l_tests.test_dockerfile_labels_and_args)

			-- Network tests (P2)
			print ("%N=== Network Tests (P2) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_network_creation", agent l_tests.test_network_creation)
			l_passed := l_passed + run_test (l_tests, "test_network_queries", agent l_tests.test_network_queries)
			l_passed := l_passed + run_test (l_tests, "test_list_networks", agent l_tests.test_list_networks)
			l_passed := l_passed + run_test (l_tests, "test_create_and_remove_network", agent l_tests.test_create_and_remove_network)

			-- Volume tests (P2)
			print ("%N=== Volume Tests (P2) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_volume_creation", agent l_tests.test_volume_creation)
			l_passed := l_passed + run_test (l_tests, "test_volume_anonymous_detection", agent l_tests.test_volume_anonymous_detection)
			l_passed := l_passed + run_test (l_tests, "test_list_volumes", agent l_tests.test_list_volumes)
			l_passed := l_passed + run_test (l_tests, "test_create_and_remove_volume", agent l_tests.test_create_and_remove_volume)

			-- Exec tests (P2)
			print ("%N=== Exec Tests (P2) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_exec_in_container", agent l_tests.test_exec_in_container)

			-- Cookbook verification tests (dogfooding)
			print ("%N=== Cookbook Verification Tests ===%N")
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_add_port", agent l_tests.test_cookbook_spec_add_port)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_add_volume", agent l_tests.test_cookbook_spec_add_volume)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_restart_policy", agent l_tests.test_cookbook_spec_restart_policy)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_hostname", agent l_tests.test_cookbook_spec_hostname)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_memory_limit", agent l_tests.test_cookbook_spec_memory_limit)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_spec_auto_remove", agent l_tests.test_cookbook_spec_auto_remove)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_container_exit_code", agent l_tests.test_cookbook_container_exit_code)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_container_is_dead", agent l_tests.test_cookbook_container_is_dead)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_image_primary_tag", agent l_tests.test_cookbook_image_primary_tag)
			l_passed := l_passed + run_test (l_tests, "test_cookbook_error_is_retryable", agent l_tests.test_cookbook_error_is_retryable)

			-- Log Stream Options tests (P3 - Happy Path)
			print ("%N=== Log Stream Tests (P3 - Happy Path) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_log_stream_options_defaults", agent l_tests.test_log_stream_options_defaults)
			l_passed := l_passed + run_test (l_tests, "test_log_stream_options_fluent_api", agent l_tests.test_log_stream_options_fluent_api)
			l_passed := l_passed + run_test (l_tests, "test_log_stream_options_to_query_string", agent l_tests.test_log_stream_options_to_query_string)
			l_passed := l_passed + run_test (l_tests, "test_log_stream_options_no_tail_in_query", agent l_tests.test_log_stream_options_no_tail_in_query)
			l_passed := l_passed + run_test (l_tests, "test_stream_container_logs_happy_path", agent l_tests.test_stream_container_logs_happy_path)

			-- Log Stream Edge Cases tests (P3)
			print ("%N=== Log Stream Tests (P3 - Edge Cases) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_log_stream_options_invalid", agent l_tests.test_log_stream_options_invalid)
			l_passed := l_passed + run_test (l_tests, "test_stream_logs_nonexistent_container", agent l_tests.test_stream_logs_nonexistent_container)
			l_passed := l_passed + run_test (l_tests, "test_stream_logs_callback_stops_streaming", agent l_tests.test_stream_logs_callback_stops_streaming)
			l_passed := l_passed + run_test (l_tests, "test_stream_logs_stopped_container", agent l_tests.test_stream_logs_stopped_container)
			l_passed := l_passed + run_test (l_tests, "test_stream_logs_timeout_behavior", agent l_tests.test_stream_logs_timeout_behavior)

			-- SIMPLE_DOCKER_QUICK tests (Beginner API)
			print ("%N=== SIMPLE_DOCKER_QUICK Tests (Happy Path) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_quick_is_available", agent l_tests.test_quick_is_available)
			l_passed := l_passed + run_test (l_tests, "test_quick_run_script", agent l_tests.test_quick_run_script)
			l_passed := l_passed + run_test (l_tests, "test_quick_redis", agent l_tests.test_quick_redis)
			l_passed := l_passed + run_test (l_tests, "test_quick_postgres", agent l_tests.test_quick_postgres)
			l_passed := l_passed + run_test (l_tests, "test_quick_cleanup", agent l_tests.test_quick_cleanup)

			print ("%N=== SIMPLE_DOCKER_QUICK Tests (Edge Cases) ===%N")
			l_passed := l_passed + run_test (l_tests, "test_quick_client_access", agent l_tests.test_quick_client_access)
			l_passed := l_passed + run_test (l_tests, "test_quick_empty_script", agent l_tests.test_quick_empty_script)
			l_passed := l_passed + run_test (l_tests, "test_quick_failing_script", agent l_tests.test_quick_failing_script)
			l_passed := l_passed + run_test (l_tests, "test_quick_stop_all", agent l_tests.test_quick_stop_all)

			l_total := 58  -- 49 + 9 SIMPLE_DOCKER_QUICK tests
			l_failed := l_total - l_passed

			print ("%N======================================%N")
			print ("Results: " + l_passed.out + " passed, " + l_failed.out + " failed%N")

			if l_failed > 0 then
				print ("%NNOTE: Some tests may fail if Docker Desktop is not running%N")
				print ("or if the alpine:latest image is not available.%N")
			end
		end

feature {NONE} -- Implementation

	run_test (a_tests: LIB_TESTS; a_name: STRING; a_test: PROCEDURE): INTEGER
			-- Run a single test. Return 1 if passed, 0 if failed.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				print ("  " + a_name + ": ")
				a_tests.on_prepare
				a_test.call (Void)
				a_tests.on_clean
				print ("PASSED%N")
				Result := 1
			else
				-- Rescue has set l_failed, just return 0
				Result := 0
			end
		rescue
			print ("FAILED%N")
			l_failed := True
			a_tests.on_clean
			retry
		end

end
