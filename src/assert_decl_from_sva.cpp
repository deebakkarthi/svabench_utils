#include <cstdlib>
#include <iostream>
#include <libgen.h>
#include <slang/syntax/SyntaxTree.h>
#include <slang/syntax/SyntaxVisitor.h>
#include <slang/text/SourceManager.h>
#include <slang/util/Bag.h>
#include <unistd.h>

std::string_view PROGNAME;

void usage(bool to_stderr = false) {
    if (to_stderr) {
        std::cerr << std::format(R"(Usage: {:s} [-h | -f FILE]
 -h         Print this help message
 -f FILE    Read input from a file instead of STDIN which is the default
)",
                                 PROGNAME);
    }
    else {
        std::cout << std::format(R"(Usage: {:s} [-h | -f FILE] -m MODULE
 -h         Print this help message
 -f FILE    Read input from a file instead of STDIN which is the default
 -m MODULE  Name of the module to use for the output
)",
                                 PROGNAME);
    }
}

int main(int argc, char** argv) {
    PROGNAME = basename(argv[0]);
    bool module_given = false;
    int opt;

    std::string input_path = "/dev/stdin";
    std::string module_name;

    while ((opt = getopt(argc, argv, "hf:m:")) != -1) {
        switch (opt) {
            case 'h': {
                usage();
                return EXIT_SUCCESS;
            }
            case 'f': {
                input_path = optarg;
                break;
            }
            case 'm': {
                module_name = optarg;
                module_given = true;
                break;
            }
            case '?':
            default: {
                usage(true);
                return EXIT_FAILURE;
            }
        }
    }

    // The input file is just a list of assertions but the final output
    // is a syntactically correct .sv file. We need a module name to create
    // that
    if (!module_given) {
        std::cerr << std::format("{:s}: Module name required\n", PROGNAME);
        return EXIT_FAILURE;
    }

    slang::syntax::SyntaxTree::TreeOrError tree_or_err = slang::syntax::SyntaxTree::fromFile(
        input_path);

    if (!tree_or_err) {
        std::cout << std::format("{:s}: Couldn't open {:s}", PROGNAME, argv[1]);
        // OS error
        return tree_or_err.error().first.value();
    }

    const auto& tree = *tree_or_err;
    std::set<std::string_view> symbols;

    tree->root().visit(slang::syntax::makeSyntaxVisitor(
        [&](auto& visitor, const slang::syntax::IdentifierNameSyntax& node) {
            symbols.insert(node.identifier.valueText());
            visitor.visitDefault(node);
        }));

    std::cout << std::format("module {:s}_assert (", module_name);
    for (auto it = symbols.begin(); it != symbols.end(); ++it) {
        if (std::next(it) != symbols.end()) {
            std::cout << std::format("input {:s},\n", *it);
        }
        // If it is the last element skip the comma
        else {
            std::cout << std::format("input {:s}\n", *it);
        }
    }
    std::cout << ");" << "\n";

    // Print out the original text
    // This should just have one bufferID
    // For the sake of completeness we are iterating
    for (auto& it : tree->getSourceBufferIds()) {
        // Have to use .data() instead of just the string_view
        // cout prints '\0' otherwise
        std::cout << tree->sourceManager().getSourceText(it).data() << '\n';
    }
    std::cout << "endmodule" << "\n";

    std::cout << std::format("bind {:s} {:s}_assert {:s}_assert_instance (.*);\n", module_name,
                             module_name, module_name);

    return EXIT_SUCCESS;
}
