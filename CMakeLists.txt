cmake_minimum_required(VERSION 3.15)

project(svabench_utils)

include(FetchContent)
FetchContent_Declare(
	slang
	GIT_REPOSITORY https://github.com/deebakkarthi/slang
	GIT_TAG dbk
	GIT_SHALLOW ON)
FetchContent_MakeAvailable(slang)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(${PROJECT_NAME} src/main.cpp)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	add_compile_options("-Wall;-Wextra;-Werror;-Wunused-value;-Wformat-security;-Wimplicit-fallthrough=5;-Walloc-zero;-Wlogical-op;-Wlogical-not-parentheses;-Wvla;-Wduplicated-cond;-Wtype-limits;-Wno-maybe-uninitialized;-Wno-alloc-size-larger-than;-Wno-dangling-reference;-Wno-stringop-overflow;-Wno-array-bounds")
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
	add_compile_options("-Wall;-Wextra;-Werror;-Warray-bounds-pointer-arithmetic;-Wassign-enum;-Wbad-function-cast;-Wcast-qual;-Wchar-subscripts;-Wcomma;-Wconditional-uninitialized;-Wconversion;-Wdelete-non-virtual-dtor;-Wnon-virtual-dtor;-Wctad-maybe-unsupported;-Wc++98-compat-extra-semi;-Wcovered-switch-default;-Wdeprecated;-Wduplicate-enum;-Wduplicate-method-arg;-Wembedded-directive;-Wfor-loop-analysis;-Wformat-pedantic;-Widiomatic-parentheses;-Wimplicit-fallthrough;-Wpedantic;-Wrange-loop-analysis;-Wredundant-parens;-Wreserved-id-macro;-Wshadow;-Wundefined-reinterpret-cast;-Wunreachable-code-aggressive;-Wno-missing-braces;-Wno-deprecated-literal-operator")
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE slang::slang)
