package main

import "core:slice"
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "sim"

CLI_EXECUTION_KEY :: [2]string{"decode", "simulate"}

Error :: union{
	os.Error,
	sim.Error,
}

cwd :: proc() -> (dir: string, err: Error){
	dir = os.get_working_directory(context.temp_allocator) or_return

	return dir, nil
}

decode :: proc(listing_file: string) {

	cwd, err := cwd()
	assert(err == nil, fmt.tprintf("Error getting current working directory: %v", err))

	sim.decode(fmt.tprintf("%s/listings/%s", cwd, listing_file))
}

simulate :: proc(args: []string) {
	listing_file := args[1]
	cwd, err := cwd()
	assert(err == nil, fmt.tprintf("Error getting current working directory: %v", err))

	list_path := fmt.tprintf("%s/listings/%s", cwd, listing_file)

	// TODO: Seems silly need to fix
	bit_instructions, e1 := sim.read_binary_listing(list_path);
	assert(e1 == nil, fmt.tprintf("Error reading binary listing: %v", e1))

	asm_instructions, e := sim.write_asm_from(bit_instructions)
	assert(e == nil, fmt.tprintf("Error writing assembly instructions: %v", e))

	dump := slice.contains(args, "--dump")
	sim.simulate(asm_instructions, dump)
}

is_valid_execution_key :: proc(exec_key: string) -> bool {
	for key, _ in CLI_EXECUTION_KEY {
		if key == exec_key {
			return true
		}
	}

	return false
}

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	cli_args := os.args[1:]
	assert(len(cli_args) > 0, "No arguments provided. Please provide a path to the listing file.")
	assert(
		is_valid_execution_key(cli_args[0]),
		fmt.tprintf(
			"Invalid execution key provided. Please provide a valid execution key. %v",
			CLI_EXECUTION_KEY,
		),
	)

	switch cli_args[0] {
	case "decode":
		assert(
			len(cli_args) == 2,
			"Invalid number of arguments provided for decode execution. Please provide only the path to the listing file.",
		)
		decode(cli_args[1])
	case "simulate":
		assert(
			len(cli_args) == 2 || len(cli_args) == 3,
			"Invalid number of arguments provided for simulate execution. Please provide only the path to the listing file.",
		)
		simulate(cli_args)
	}

}
