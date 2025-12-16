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
			print ("Testing SIMPLE_DOCKER v1.0.0...%N")
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

			l_total := 15
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
