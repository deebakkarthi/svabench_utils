#include <format>
#include <iostream>
#include <libgen.h>
#include <string>
#include <unistd.h>

#include "slang/syntax/SyntaxTree.h"

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

    slang::syntax::SyntaxTree::TreeOrError tree_or_err = slang::syntax::SyntaxTree::fromFile(
        input_path);

    if (!tree_or_err) {
        std::cerr << std::format("{:s}: Couldn't open {:s}\n", PROGNAME, input_path);
        return tree_or_err.error().first.value();
    }

    return EXIT_SUCCESS;
}
