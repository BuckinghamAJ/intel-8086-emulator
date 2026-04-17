package tests

import "core:testing"
import "core:log"
import main ".."

@(test)
test_listing_file_for_debug :: proc(t: ^testing.T) {
	log.info("test_listing_file_for_debug...")

	main.simulate("listing_0052_memory_add_loop")
}
