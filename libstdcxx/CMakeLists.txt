

if(PATH64_MAKE_STDCXX_CONFIG)

# Making configs for stdcxx

# configuring scripts
foreach(targ ${PATH64_ENABLE_TARGETS})
    set(CURRENT_TARG ${targ})
    set(CURRENT_TARG_ARCH ${_PATH64_TARGET_ARCH_${targ}})
    set(CURRENT_TARG_ABI ${_PATH64_TARGET_BITS_${targ}})
    set(CURRENT_TARG_FLAGS ${_PATH64_TARGET_FLAG_${targ}})

    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/configure_libstdcxx.sh.cmake.in
                   ${CMAKE_CURRENT_BINARY_DIR}/configure_libstdcxx-${targ}.sh)
endforeach()

endif()


option(PATH64_BUILD_STDCXX "Enabled building stdcxx library" ON)

if(PATH64_BUILD_STDCXX)

# commands for installing libstdcxx headers to stage dir
file(GLOB_RECURSE headers
     RELATIVE "${PATH64_LIBSTDCXX_SOURCE}/include"
     "${PATH64_LIBSTDCXX_SOURCE}/include/*")
set(stdcxx_stage_headers)
foreach(header ${headers})
    # filtering .c extension
    get_filename_component(header_ext ${header} EXT)
    if(NOT "X${header_ext}" STREQUAL "X.c")
        add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/${header}
                           COMMAND ${CMAKE_COMMAND} -E copy
                                   ${PATH64_LIBSTDCXX_SOURCE}/include/${header}
                                   ${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/${header}
                           DEPENDS ${PATH64_LIBSTDCXX_SOURCE}/include/${header})
        list(APPEND stdcxx_stage_headers
             ${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/${header})
    endif()
endforeach()

# Selecing config for OS
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(config_os "linux")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "SunOS")
    set(config_os "solaris")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    set(config_os "freebsd")
endif()

# Configuring config.h for all targets
foreach(targ ${PATH64_ENABLE_TARGETS})
    configure_file("${PATH64_LIBSTDCXX_SOURCE}/config/${config_os}/config-${targ}.h.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/include/__stl_config-${targ}.h")

    # Rules for installing config header
    add_custom_command(OUTPUT "${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/__stl_config-${targ}.h"
                       COMMAND ${CMAKE_COMMAND} -E copy
                               "${CMAKE_CURRENT_BINARY_DIR}/include/__stl_config-${targ}.h"
                               "${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/__stl_config-${targ}.h"
                       DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/include/__stl_config-${targ}.h")
    list(APPEND stdcxx_stage_headers "${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/__stl_config-${targ}.h")
endforeach()


set(stdcxx_sources
    assert.cpp
    bitset.cpp
    catalog.cpp
    codecvt.cpp
    collate.cpp
    ctype_bits.cpp
    ctype.cpp
    domain_error.cpp
    exception.cpp
    export.cpp
    facet.cpp
    file.cpp
    instance.cpp
    invalid_argument.cpp
    ios_bits.cpp
    ios.cpp
    iostore.cpp
    iostream.cpp
    iso2022.cpp
    length_error.cpp
    limits_bits.cpp
    limits.cpp
    locale_bits.cpp
    locale_body.cpp
    locale_classic.cpp
    locale_combine.cpp
    locale_core.cpp
    locale_eq.cpp
    locale_global.cpp
    locale_name.cpp
    logic_error.cpp
    memattr.cpp
    memory.cpp
    messages.cpp
    mman.cpp
    num_get.cpp
    num_put.cpp
    once.cpp
    out_of_range.cpp
    overflow_error.cpp
    punct.cpp
    random.cpp
    range_error.cpp
    runtime_error.cpp
#    rwstderr.cpp
    setlocale.cpp
    string.cpp
    strstream.cpp
    strtol.cpp
    ti_collate.cpp
    ti_filebuf.cpp
    ti_insert_dbl.cpp
    ti_insert_int.cpp
    ti_insert_ptr.cpp
    ti_ios.cpp
    ti_istream.cpp
    time_get.cpp
    time_put.cpp
    ti_messages.cpp
    ti_money_get.cpp
    ti_moneypunct.cpp
    ti_money_put.cpp
    ti_num_get.cpp
    ti_numpunct.cpp
    ti_num_put.cpp
    ti_ostream.cpp
    ti_podarray.cpp
    ti_streambuf.cpp
    ti_stringbuf.cpp
    ti_string.cpp
    ti_time_get.cpp
    ti_time_put.cpp
    ti_wcollate.cpp
    ti_wfilebuf.cpp
    ti_winsert_dbl.cpp
    ti_winsert_int.cpp
    ti_winsert_ptr.cpp
    ti_wios.cpp
    ti_wistream.cpp
    ti_wmessages.cpp
    ti_wmoney_get.cpp
    ti_wmoneypunct.cpp
    ti_wmoney_put.cpp
    ti_wnum_get.cpp
    ti_wnumpunct.cpp
    ti_wnum_put.cpp
    ti_wostream.cpp
    ti_wstreambuf.cpp
    ti_wstringbuf.cpp
    ti_wstring.cpp
    ti_wtime_get.cpp
    ti_wtime_put.cpp
    tmpbuf.cpp
    typeinfo.cpp
    underflow_error.cpp
    valarray.cpp
    vecbool.cpp
    version.cpp
    wcodecvt.cpp
    wctype.cpp
    atomic-cxx.S
   )

set(incl_dir_flags "-I${PATH64_LIBSTDCXX_SOURCE}/include/ansi")
set(incl_dir_flags "${incl_dir_flags} -I${PATH64_LIBSTDCXX_SOURCE}/include")
set(incl_dir_flags "${incl_dir_flags} -I${CMAKE_CURRENT_BINARY_DIR}/include")

path64_set_multitarget_sources_base_path(stdcxx "${PATH64_LIBSTDCXX_SOURCE}/src")
path64_set_multitarget_sources(stdcxx COMMON ${stdcxx_sources})
path64_set_multitarget_property_(stdcxx COMPILE_FLAGS
        "-fPIC -nostdinc++ -D_RWSTD_POSIX_THREADS -pthread ${incl_dir_flags}")
path64_set_multitarget_property_(stdcxx OUTPUT_NAME "stl")
path64_set_multitarget_property_(stdcxx LINK_FLAGS "-nodefaultlibs")
# XXX libstdcxx pulls in __isfinite() and __signbit() from libm.
if(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    path64_multitarget_link_libraries(stdcxx m)
endif()
path64_add_multitarget_library(stdcxx SHARED)
path64_add_multitarget_multitarget_dependencies(stdcxx compiler-rt cxxrt unwind)
path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX stdcxx)

path64_set_multitarget_sources_base_path(stdcxx-static "${PATH64_LIBSTDCXX_SOURCE}/src")
path64_set_multitarget_sources(stdcxx-static COMMON ${stdcxx_sources})
path64_set_multitarget_property_(stdcxx-static COMPILE_FLAGS
        "-fPIC -nostdinc++ -D_RWSTD_POSIX_THREADS -pthread ${incl_dir_flags}")
path64_set_multitarget_property_(stdcxx-static OUTPUT_NAME "stl")
path64_add_multitarget_library(stdcxx-static STATIC)
path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX stdcxx-static)


add_custom_target(stdcxx-headers-stage ALL DEPENDS ${stdcxx_stage_headers})
add_dependencies(compiler-stage-libs-CXX stdcxx-headers-stage)

set(inc_dir ${CMAKE_INSTALL_PREFIX}/include/${PSC_FULL_VERSION}/stl)

install(DIRECTORY ${PATH64_STAGE_DIR}/include/${PSC_FULL_VERSION}/stl/
        DESTINATION ${inc_dir})

endif()

