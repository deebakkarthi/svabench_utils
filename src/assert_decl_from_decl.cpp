#include <cstdlib>
#include <iostream>
#include <libgen.h>
#include <unistd.h>

std::string_view PROGNAME;

void help(bool to_stderr = false)
{
	if (to_stderr) {
		std::cerr << std::format("Usage: {:s} [-h | -f FILE]\n",
					 PROGNAME);
	} else {
		std::cout << std::format("Usage: {:s} [-h | -f FILE]\n",
					 PROGNAME);
	}
	return;
}

int main(int argc, char **argv)
{
	PROGNAME = basename(argv[0]);

	int opt;
	while ((opt = getopt(argc, argv, "hf:")) != -1) {
		switch (opt) {
		case 'h': {
			help();
			return EXIT_SUCCESS;
		}
		case 'f': {
			std::cout << "optarg: " << optarg << std::endl;
			break;
		}
		case '?':
		default: {
			help(true);
			return EXIT_FAILURE;
		}
		}
	}
	// If there are no args, then argc will be set from 1 to be 0
	// So the preceeding check will work even if no args were sent in the
	// first place.
	argc -= optind;
	argv += optind;

	// There should be no remaining args in argv
	if (argc != 0) {
		std::cerr << std::format("{:s}: Invalid args\n", PROGNAME);
		help(true);
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
