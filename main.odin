package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "decoder"

main :: proc() {
	defer free_all(context.temp_allocator)
	assert(len(os.args) > 1, "No arguments provided. Please provide a path to the listing file.")
	assert(
		len(os.args) <= 2,
		"Too many arguments provided. Please provide only the path to the listing file.",
	)

	listing_file := os.args[1]

	cwd, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.println("Error getting current working directory: ", err)
		return
	}

	decoder.entry(fmt.tprintf("%s/listings/%s", cwd,listing_file))

}
