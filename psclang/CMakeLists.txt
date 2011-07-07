
option(INSTALL_PSCLANG "Install psclang" OFF)
add_subdirectory(${PATH64_PSCLANG_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/__build)

set(deps)
foreach(arch ${PATH64_ENABLE_ARCHES})
    set(input "${CMAKE_CURRENT_BINARY_DIR}/__build/bin/clang")
    set(output "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/psclang")
    add_custom_command(OUTPUT "${output}"
                       COMMAND "${CMAKE_COMMAND}" -E copy "${input}" "${output}"
                       DEPENDS "${input}")

    install(PROGRAMS "${output}"
            DESTINATION "lib/${PSC_FULL_VERSION}/${arch}")

    list(APPEND deps "${output}")
endforeach()

add_custom_target(psclang-stage DEPENDS ${deps}) 
add_dependencies(psclang-stage clang)
add_dependencies(path64-stage psclang-stage)
add_dependencies(compiler-stage psclang-stage)

