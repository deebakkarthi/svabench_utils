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
                break;
            }
            default: {
                std::cerr << usage();
                break;
            }
        }
    }

    argc -= optind;
    argv += optind;
    return 0;
}
