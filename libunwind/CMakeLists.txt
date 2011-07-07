

set(libunwind_SOURCE_DIR ${PATH64_LIBUNWIND_SOURCE})
include(${PATH64_LIBUNWIND_SOURCE}/src/config.cmake)

set(libunwind_sources_common
    mi/init.c
    mi/flush_cache.c
    mi/mempool.c
    mi/strerror.c
    dwarf/global.c
    mi/backtrace.c
    mi/dyn-cancel.c
    mi/dyn-info-list.c
    mi/dyn-register.c
    mi/Ldyn-extract.c
    mi/Lfind_dynamic_proc_info.c
    mi/Lget_accessors.c
    mi/Lget_proc_info_by_ip.c
    mi/Lget_proc_name.c
    mi/Lput_dynamic_unwind_info.c
    mi/Ldestroy_addr_space.c
    mi/Lget_reg.c
    mi/Lset_reg.c
    mi/Lget_fpreg.c
    mi/Lset_fpreg.c
    mi/Lset_caching_policy.c
    mi/_ReadULEB.c
    mi/_ReadSLEB.c
    unwind/Backtrace.c
    unwind/DeleteException.c
    unwind/FindEnclosingFunction.c
    unwind/ForcedUnwind.c
    unwind/GetBSP.c
    unwind/GetCFA.c
    unwind/GetDataRelBase.c
    unwind/GetGR.c
    unwind/GetIP.c
    unwind/GetLanguageSpecificData.c
    unwind/GetRegionStart.c
    unwind/GetTextRelBase.c
    unwind/RaiseException.c
    unwind/Resume.c
    unwind/Resume_or_Rethrow.c
    unwind/SetGR.c
    unwind/SetIP.c
    unwind/GetIPInfo.c
    dwarf/Lexpr.c
    dwarf/Lfde.c
    dwarf/Lparser.c
    dwarf/Lpe.c
    dwarf/Lstep.c
    dwarf/Lfind_proc_info-lsb.c
    ${PATH64_COMPILER_RT_SOURCE}/lib/gcc_personality_v0.c
   )

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_common os-linux.c)
elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    list(APPEND libunwind_sources_common os-solaris.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    list(APPEND libunwind_sources_common os-freebsd.c)
endif()

set(libunwind_sources_x86_32
    elf32.c
    x86/is_fpreg.c
    x86/regname.c
    x86/Lcreate_addr_space.c
    x86/Lget_save_loc.c
    x86/Lglobal.c
    x86/Linit.c
    x86/Linit_local.c
    x86/Linit_remote.c
    x86/Lget_proc_info.c
    x86/Lregs.c
    x86/Lresume.c
    x86/Lstep.c
   )

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_x86_32
         x86/Los-linux.c
         x86/getcontext-linux.S
    )
    set_property(SOURCE x86/getcontext-linux.S
                 PROPERTY LANGUAGE C)
endif()



set(libunwind_sources_x86_64
    elf64.c
    x86_64/is_fpreg.c
    x86_64/regname.c
    x86_64/Lcreate_addr_space.c
    x86_64/Lget_save_loc.c
    x86_64/Lglobal.c
    x86_64/Linit.c
    x86_64/Linit_local.c
    x86_64/Linit_remote.c
    x86_64/Lget_proc_info.c
    x86_64/Lregs.c
    x86_64/Lresume.c
    x86_64/Lstep.c
    x86_64/getcontext.S
    x86_64/setcontext.S
   )


if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_x86_64
         x86_64/Los-linux.c
    )
elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    list(APPEND libunwind_sources_x86_64
         x86_64/Los-solaris.c
    )
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    list(APPEND libunwind_sources_x86_64 x86_64/Los-freebsd.c)
endif()

set_property(SOURCE x86_64/getcontext.S
                    x86_64/setcontext.S
             PROPERTY LANGUAGE C)

include_directories(${PATH64_LIBUNWIND_SOURCE}/src
                    ${PATH64_LIBUNWIND_SOURCE}/include
                    ${CMAKE_CURRENT_BINARY_DIR}/include
                   )

add_definitions(-DHAVE_CONFIG_H
                -D_GNU_SOURCE
                -DPIC
               )

path64_set_multitarget_sources_base_path(unwind-static "${PATH64_LIBUNWIND_SOURCE}/src")
path64_set_multitarget_sources(unwind-static COMMON ${libunwind_sources_common})
path64_set_multitarget_sources(unwind-static x86_64 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_64})
path64_set_multitarget_sources(unwind-static x86_32 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_32})
if("X${CMAKE_BUILD_TYPE}" STREQUAL "XDebug")
    path64_set_multitarget_property_(unwind-static COMPILE_DEFINITIONS DEBUG)
endif()
path64_set_multitarget_property_(unwind-static COMPILE_FLAGS "-fPIC -fexceptions")
path64_set_multitarget_property_for_target(unwind-static x86_64 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86_64")
path64_set_multitarget_property_for_target(unwind-static x86_32 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86")
path64_set_multitarget_property_(unwind-static OUTPUT_NAME "eh")
path64_add_multitarget_library(unwind-static STATIC)
path64_add_dependencies_from_multitarget(compiler-stage-libs-C unwind-static)



path64_set_multitarget_sources_base_path(unwind "${PATH64_LIBUNWIND_SOURCE}/src")
path64_set_multitarget_sources(unwind COMMON ${libunwind_sources_common})
path64_set_multitarget_sources(unwind x86_64 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_64})
path64_set_multitarget_sources(unwind x86_32 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_32})
path64_set_multitarget_property_(unwind COMPILE_FLAGS "-fPIC -fexceptions")
path64_set_multitarget_property_for_target(unwind x86_64 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86_64")
path64_set_multitarget_property_for_target(unwind x86_32 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86")
if("X${CMAKE_BUILD_TYPE}" STREQUAL "XDebug")
    path64_set_multitarget_property_(unwind COMPILE_DEFINITIONS DEBUG)
endif()
path64_multitarget_link_libraries(unwind pthread c)
path64_set_multitarget_property_(unwind OUTPUT_NAME "eh")
path64_set_multitarget_property_(unwind LINK_FLAGS "-nodefaultlibs")
path64_add_multitarget_library(unwind SHARED)
path64_add_multitarget_multitarget_dependencies(unwind compiler-rt)
path64_add_dependencies_from_multitarget(compiler-stage-libs-C unwind)

