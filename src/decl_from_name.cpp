#include "slang/text/SourceManager.h"
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <string_view>
#include <getopt.h>
#include <libgen.h>
#include <sysexits.h>

std::string_view PROGNAME;

void help(bool to_stderr = false)
{
	if (to_stderr) {
		std::cerr << std::format("Usage: {:s} [-h] PATTERN FILE\n",
					 PROGNAME);
	} else {
		std::cout << std::format("Usage: {:s} [-h] PATTERN FILE\n",
					 PROGNAME);
	}
	return;
}

int main(int argc, char **argv)
{
	/* cmdline args
	 * decl_from_name [-h ] PATTERN FILE
	 * 
	 * Apparently arbitrary ordering of options and arguments is a GNU 
	 * extension. Since I am on OS X, I am bound to use the POSIX/BSD
	 * version that doesn't allow this. So -h or any other options are
	 * forced to come infront of the actual arguements
	 * */
	PROGNAME = basename(argv[0]);
	int opt;

	while ((opt = getopt(argc, argv, "h")) != -1) {
		switch (opt) {
		case 'h': {
			help();
			return EXIT_SUCCESS;
		}
			// getopt returns '?' if it encounters an option not in
			// the optstring
		case '?':
		default: {
			help(true);
			return EXIT_FAILURE;
		}
		}
	}

	// Remaining number of cmdline args
	argc -= optind;
	// Move pointer to the first non-option
	argv += optind;

	// After parsing the options we should have exactly 2 arguments
	// If that is not the case then show the usage
	if (argc != 2) {
		help(true);
		return EXIT_FAILURE;
	}

	std::string_view pattern = argv[0];
	std::filesystem::path file = std::filesystem::path(argv[1]);

	slang::SourceManager sm;
	auto sb = sm.readSource(file);
	if (!sb) {
		std::cout << std::format("{:s}: {:s} not found\n", PROGNAME,
					 file.string());
		return EX_NOINPUT;
	}

	return 0;
}
