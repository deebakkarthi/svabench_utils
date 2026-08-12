#include <cstdlib>
#include <getopt.h>
#include <iostream>
#include <libgen.h>
#include <string_view>

#include "slang/syntax/SyntaxKind.h"
#include "slang/syntax/SyntaxPrinter.h"
#include "slang/syntax/SyntaxTree.h"
#include "slang/syntax/SyntaxVisitor.h"

std::string_view PROGNAME;

void help(bool to_stderr = false) {
    if (to_stderr) {
        std::cerr << std::format("Usage: {:s} [-h] PATTERN FILE\n", PROGNAME);
    }
    else {
        std::cout << std::format("Usage: {:s} [-h] PATTERN FILE\n", PROGNAME);
    }
    return;
}

int main(int argc, char** argv) {
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

    auto tree_or_err = slang::syntax::SyntaxTree::fromFile(argv[1]);
    if (!tree_or_err) {
        std::cout << std::format("{:s}: Couldn't open {:s}", PROGNAME, argv[1]);
        // OS error
        return tree_or_err.error().first.value();
    }

    const auto& tree = *tree_or_err;

    bool found = false;
    // We return after finding the first match
    // I don't think SystemVerilog allows for
    // duplicate module declaration. So it should be fine to stop after
    // finding the first match
    tree->root().visit(slang::syntax::makeSyntaxVisitor(
        [&](auto& visitor, const slang::syntax::ModuleDeclarationSyntax& node) {
            // node.kind can be of:
            // - ModuleDeclaration
            // - InterfaceDeclaration
            // - ProgramDeclaration
            // - PackageDeclaration
            //
            // We only need modules, so filtering by that
            if (node.kind == slang::syntax::SyntaxKind::ModuleDeclaration) {
                if (node.header->name.valueText() == pattern) {
                    // Use SyntaxPrinter to handle removing
                    // newlines, etc...
                    std::cout << std::format("{:s}\n",
                                             slang::syntax::SyntaxPrinter()
                                                 .setSquashNewlines(true)
                                                 .setIncludeComments(false)
                                                 .printExcludingLeadingComments(*node.header)
                                                 .str());
                    found = true;
                    return;
                }
                visitor.visitDefault(node);
            }
        }));

    return found ? EXIT_SUCCESS : EXIT_FAILURE;
}
