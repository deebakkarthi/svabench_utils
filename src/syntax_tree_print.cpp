#include <format>
#include <iostream>
#include <libgen.h>
#include <string>
#include <unistd.h>

#include "slang/parsing/TokenKind.h"
#include "slang/syntax/SyntaxNode.h"
#include "slang/syntax/SyntaxTree.h"

std::string PROGNAME;

std::string usage() {
    return std::format("Usage: {:s} [-h | -f FILE]\n"
                       "  -h     \tPrint this help message\n"
                       "  -f FILE\tRead from FILE instead of STDIN\n",
                       PROGNAME);
}

void syntax_tree_print(slang::syntax::SyntaxNode& node, uint16_t level = 0) {
    std::cout << std::format("{:s}{:s}\n", std::string(level, ' '),
                             slang::syntax::toString(node.kind));

    for (size_t i = 0; i < node.getChildCount(); i++) {
        // If childNode() is not 0, then it is a SyntaxNode
        if (node.childNode(i) != nullptr) {
            syntax_tree_print(*node.childNode(i), level + 1);
        }
        else {
            // If childNode() is null, then it is a token
            // Don't have to recurse. They're always a leaf node
            std::cout << std::format("{:s}TOKEN:{:s}\n", std::string(level, ' '),
                                     slang::parsing::toString(node.childToken(i).kind));
        }
    }
}

int main(int argc, char** argv) {
    PROGNAME = basename(argv[0]);
    std::string input_path = "/dev/stdin";

    int opt;

    while ((opt = getopt(argc, argv, "hf:")) != -1) {
        switch (opt) {
            case 'h': {
                std::cout << usage();
                return 0;
            }
            case 'f': {
                input_path = optarg;
                break;
            }
            default: {
                std::cerr << usage();
                return 1;
                break;
            }
        }
    }
    // After getopt returns, optind points to the next non-option
    argc -= optind;
    argv += optind;

    if (argc > 0) {
        std::cerr << std::format("{:s}: Extra arguments given\n", PROGNAME);
        std::cerr << usage();
        return 1;
    }

    auto tree_or_err = slang::syntax::SyntaxTree::fromFile(input_path);
    if (!tree_or_err) {
        std::cerr << std::format("{:s}: {:s} could not be opened\n", PROGNAME, input_path);
    }

    std::shared_ptr<slang::syntax::SyntaxTree> tree = *tree_or_err;

    slang::syntax::SyntaxNode& root = tree->root();

    syntax_tree_print(root, 0);

    return 0;
}
