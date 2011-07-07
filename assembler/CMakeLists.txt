
option(BUILD_TESTS "BUILD_TESTS" OFF)
option(BUILD_STATIC "BUILD_STATIC" ON)
option(INSTALL_GPUASM "Install gpuasm" OFF)
add_subdirectory(${PATH64_GPUASM_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/__build)

add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/bin/pathas
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/yasm
                           ${PATH64_STAGE_DIR}/bin/pathas
                   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/__build/yasm
                  )

install(PROGRAMS ${PATH64_STAGE_DIR}/bin/pathas
        DESTINATION bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE
       )

add_custom_target(gpuasm-stage DEPENDS ${PATH64_STAGE_DIR}/bin/pathas) 
add_dependencies(gpuasm-stage yasm)
add_dependencies(path64-stage gpuasm-stage)
add_dependencies(compiler-stage gpuasm-stage)

