
set(CXXRT_SOURCES
    dynamic_cast.cc
    exception.cc
    guard.cc
    terminate.cc
    typeinfo.cc
    stdexcept.cc
    memory.cc
    aux.cc
    libelftc_dem_gnu3.c
   )


path64_set_multitarget_sources_base_path(cxxrt-static "${PATH64_LIBCXXRT_SOURCE}/src")
path64_set_multitarget_sources(cxxrt-static COMMON ${CXXRT_SOURCES})
path64_set_multitarget_property_(cxxrt-static OUTPUT_NAME "cxxrt")
path64_set_multitarget_property_(cxxrt-static COMPILE_FLAGS "-fPIC -fexceptions")
path64_add_multitarget_library(cxxrt-static STATIC)
path64_add_multitarget_multitarget_dependencies(cxxrt-static compiler-rt-static unwind pscrt-static)
path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX cxxrt-static)

path64_set_multitarget_sources_base_path(cxxrt "${PATH64_LIBCXXRT_SOURCE}/src")
path64_set_multitarget_sources(cxxrt COMMON ${CXXRT_SOURCES})
path64_set_multitarget_property_(cxxrt OUTPUT_NAME "cxxrt")
path64_set_multitarget_property_(cxxrt COMPILE_FLAGS "-fPIC -nostdlib++ -fexceptions -lpthread")
path64_set_multitarget_property_(cxxrt LINK_FLAGS "-nodefaultlibs -fbootstrap-hack")
if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    path64_multitarget_link_libraries(cxxrt dl)
endif()
path64_add_multitarget_library(cxxrt SHARED)
path64_add_multitarget_multitarget_dependencies(cxxrt compiler-rt unwind pscrt-static)
path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX cxxrt)

