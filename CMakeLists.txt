cmake_minimum_required(VERSION 2.8.0)

enable_testing()

# Whatever arbitrary number you'd like in 3 string format eg 3.9.99
IF(NOT PSC_FULL_VERSION)
    SET(PSC_FULL_VERSION "1.0.0" CACHE STRING "Defaulting to version 1.0.0")
ENDIF()


if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/opt/ekopath/${PSC_FULL_VERSION}" CACHE PATH "Installation root prefix" FORCE)
  set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT FALSE)
endif()

if("${CMAKE_GENERATOR}" MATCHES "Makefiles" AND NOT CMAKE_BUILD_TYPE)
	if(NOT __DEFAULT_BUILD_TYPE_SET)
		set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
		set(__DEFAULT_BUILD_TYPE_SET YES CACHE INTERNAL "")
	endif()
endif()


MESSAGE(STATUS "Version is set to "${PSC_FULL_VERSION})
string(REGEX REPLACE "^([0-9.]+).*$" "\\1" TMPVERSION ${PSC_FULL_VERSION})
# If it's not in three string format it sucks to be you
string(REGEX REPLACE "^([0-9]+).+$" "\\1" PSC_MAJOR_VERSION ${TMPVERSION})
string(REGEX REPLACE "^[0-9]+\\.([0-9]+).*$" "\\1" PSC_MINOR_VERSION ${TMPVERSION})

option(PATH64_ENABLE_PSCRUNTIME "Enables pathscale runtime libraries" ON)
option(PATH64_BUILD_STDCXX "Enables building stdcxx library" ON)
option(PATH64_ENABLE_TESTING "Enables ekopath-suite testing" ON)
option(PATH64_ENABLE_CXX "Enables C++" ON)
option(PATH64_ENABLE_PROFILING "Enables profiling" ON)
option(PATH64_ENABLE_FORTRAN "Enables Fortran" ON)
option(PATH64_ENABLE_MATHLIBS "Enables math libraries" ON)
option(PATH64_ENABLE_OPENMP "Enables OpenMP" ON)
option(PATH64_ENABLE_PATHOPT2 "Enables 'PATHOPT2'" OFF)


if("${CMAKE_BUILD_TYPE}" STREQUAL "Release" AND (NOT "${CMAKE_C_COMPILER_ID}" STREQUAL "PathScale"))
	message(WARNING "Building in Release mode with a non-PathScale compiler (${CMAKE_C_COMPILER_ID}) is not supported and probably won't work!")
endif()

set(BUILD_PSCLANG FALSE)

function(check_directory var_name desc def_val)
    set(dir "${${var_name}}")

    if("${dir}" STREQUAL "" AND NOT "${def_val}" STREQUAL "")
        set(dir "${def_val}")
    endif()

	if(NOT "${dir}" STREQUAL "")
		if(IS_DIRECTORY "${dir}")
			get_filename_component(abs_path "${dir}" ABSOLUTE)
			set(${var_name} ${abs_path} PARENT_SCOPE)
			message(STATUS "Using ${desc} from ${abs_path}")
		else()
			message(FATAL_ERROR "Directory '${dir}' does not exist")
		endif()
	else()
		message(FATAL_ERROR "${var_name} is not specified")
	endif()
endfunction()


if("${CMAKE_C_COMPILER_ID}" STREQUAL "PathScale" AND "${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    # linking pathscale runtime statically

    set(c_flags "-nodefaultlibs -Wl,-Bstatic -lmv -lmpath -leh -lgcc -lpscrt -Wl,-Bdynamic")
    set(cxx_flags "-nodefaultlibs -Wl,-Bstatic -lmv -lmpath -lstl -lcxxrt -leh -lgcc -lpscrt -Wl,-Bdynamic -lpthread -lm")

    if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
        # there is no libdl on freebsd
        set(cxx_flags "${cxx_flags} -ldl")
    endif()

    set(CMAKE_C_LINK_EXECUTABLE "${CMAKE_C_LINK_EXECUTABLE} ${c_flags}")
    set(CMAKE_C_CREATE_SHARED_LIBRARY "${CMAKE_C_CREATE_SHARED_LIBRARY} ${c_flags}")

    set(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_CXX_LINK_EXECUTABLE} ${cxx_flags}")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} ${cxx_flags}")

    set(linker_flags "-Wl,-s -fbootstrap-hack")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${linker_flags}")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${linker_flags}")
    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} ${linker_flags}")
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/DetectDefaults.cmake)

set(source_file "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/hash-style.c")
file(WRITE "${source_file}" "#include <stdio.h>
                             int main(void)
                             {
                                 return printf(\"\");
                             }
                             ")

message(STATUS "Checking for --hash-style=gnu support")
try_run(SUPPORT_HASH_STYLE_GNU SUPPORT_HASH_STYLE_GNU_BUILD
        ${CMAKE_BINARY_DIR} ${source_file}
        CMAKE_FLAGS -DLINK_LIBRARIES:STRING=-Wl,--hash-style=gnu
        OUTPUT_VARIABLE output)
if(SUPPORT_HASH_STYLE_GNU_BUILD AND SUPPORT_HASH_STYLE_GNU EQUAL 0)
    set(hash_style_supported TRUE)
    message(STATUS "Checking for --hash-style=gnu support -- found ")
else()
    set(hash_style_supported FALSE)
    message(STATUS "Checking for --hash-style=gnu support -- not found ")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
         "Checking support for --hash-style=gnu support failed with the following output:\n"
         "${output}\n")
endif()

# use --hash-style=both option to build portable packages
if(hash_style_supported)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -Wl,--hash-style=both")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} -Wl,--hash-style=both")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} -Wl,--hash-style=both")
endif()


set(CMAKE_SKIP_RPATH TRUE)
set(PATH64_STAGE_DIR ${CMAKE_CURRENT_BINARY_DIR}/Xcompiler)

add_custom_target(path64-stage ALL true)

check_directory(PATH64_COMPILER_SOURCE "path64 compiler"
                "${CMAKE_CURRENT_SOURCE_DIR}/compiler/compiler")
add_subdirectory(${PATH64_COMPILER_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/Xcompiler)

# Including multitarget stuff from compiler sources
include(${PATH64_COMPILER_SOURCE}/src/targets.cmake)


if(PATH64_ENABLE_PSCRUNTIME)
    if(PATH64_ENABLE_PSCLANG)
        if(PATH64_ENABLE_DEFAULT_PSCLANG)
            check_directory(PATH64_PSCLANG_SOURCE "psclang"
                            "${CMAKE_CURRENT_SOURCE_DIR}/compiler/psclang")
        endif()

        if(NOT "${PATH64_PSCLANG_SOURCE}" STREQUAL "")
            set(BUILD_PSCLANG TRUE)
            add_subdirectory(psclang)
        endif()
    endif()

    check_directory(PATH64_COMPILER_RT_SOURCE "compiler rt"
                    "${CMAKE_CURRENT_SOURCE_DIR}/compiler/compiler-rt")
    add_subdirectory(compiler_rt)

    check_directory(PATH64_LIBUNWIND_SOURCE "libunwind"
                    "${CMAKE_CURRENT_SOURCE_DIR}/compiler/libunwind")
    add_subdirectory(libunwind)

    if(PATH64_ENABLE_CXX)
        check_directory(PATH64_LIBCXXRT_SOURCE "libcxxrt"
                        "${CMAKE_CURRENT_SOURCE_DIR}/compiler/libcxxrt")
        add_subdirectory(libcxxrt)
    endif()

    if(PATH64_ENABLE_PATHAS)
        check_directory(PATH64_ASSEMBLER_SOURCE "assembler"
                        "${CMAKE_CURRENT_SOURCE_DIR}/compiler/assembler")
        add_subdirectory(assembler)
    endif()

    if(PATH64_ENABLE_CXX)
        check_directory(PATH64_LIBSTDCXX_SOURCE "libstdcxx"
                        "${CMAKE_CURRENT_SOURCE_DIR}/compiler/stdcxx")
        add_subdirectory(libstdcxx)
    endif()

    if(PATH64_ENABLE_TESTING)
        add_subdirectory(bootstrap)
    endif()

    if(PATH64_ENABLE_PATHDB)
        check_directory(PATH64_PATHDB_SOURCE "pathdb"
                        "${CMAKE_CURRENT_SOURCE_DIR}/compiler/pathdb")
        add_subdirectory(pathdb)
    endif()

    check_directory(PATH64_LIBDWARF_SOURCE "libdwarf"
                    "${CMAKE_CURRENT_SOURCE_DIR}/compiler/libdwarf-bsd")
    add_subdirectory(libdwarf)
endif()


# Adding qa if specified
if(PATH64_QA_SOURCE)
    if(IS_DIRECTORY ${PATH64_QA_SOURCE})
        message(STATUS "Using QA from ${PATH64_QA_SOURCE}")

        set(qa_C_compiler "${PATH64_STAGE_DIR}/bin/pathcc")
        set(qa_CXX_compiler "${PATH64_STAGE_DIR}/bin/pathCC")
        set(qa_Fortran_compiler "${PATH64_STAGE_DIR}/bin/pathf90")
        set(qa_env_lib_path "${PATH64_STAGE_DIR}/lib")

        add_subdirectory(${PATH64_QA_SOURCE} qa)

    else()
        message(FATAL_ERROR "Directory '${PATH64_QA_SOURCE}' does not exist")
    endif()
endif()


