#include <format>
#include <iostream>
#include <libgen.h>
#include <string>
#include <unistd.h>

std::string PROGNAME;

std::string usage() {
    return std::format("Usage: {:s} [-h] [-f FILE]\n"
                       "  -h     \tPrint this help message\n"
                       "  -f FILE\tRead from FILE instead of STDIN\n",
                       PROGNAME);
}

int main(int argc, char** argv) {
    PROGNAME = basename(argv[0]);

    int opt;
    std::string input_path = "/dev/stdin";

    while ((opt = getopt(argc, argv, "hf:")) != -1) {
        switch (opt) {
            case 'h': {
                std::cout << usage();
                return EXIT_SUCCESS;
            }
            case 'f': {
                input_path = optarg;
                break;
            }
            default: {
                std::cerr << usage();
                return EXIT_FAILURE;
            }
        }
    }

    argc -= optind;
    argv += optind;

    if (argc > 0) {
        std::cerr << std::format("{:s}: Extra arguments given\n", PROGNAME);
        std::cerr << usage();
    }

    std::cout << input_path << "\n";

    return EXIT_SUCCESS;
}
