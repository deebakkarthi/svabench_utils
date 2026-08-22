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
    while ((opt = getopt(argc, argv, "h")) != -1) {
        switch (opt) {
            case 'h': {
                std::cout << usage();
                return EXIT_SUCCESS;
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

    return EXIT_SUCCESS;
}
