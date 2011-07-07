
add_subdirectory(${PATH64_PATHDB_SOURCE} __build)

add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/bin/pathdb
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/bin/pathdb
                           ${PATH64_STAGE_DIR}/bin/pathdb)


add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/bin/doctool
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/bin/doctool
                           ${PATH64_STAGE_DIR}/bin/doctool)


add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/bin/funclookup
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/bin/funclookup
                           ${PATH64_STAGE_DIR}/bin/funclookup)


add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/etc/pathdb-help.xml
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/etc/pathdb-help.xml
                           ${PATH64_STAGE_DIR}/etc/pathdb-help.xml)


add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/share/emacs.el
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_BINARY_DIR}/__build/share/emacs.el
                           ${PATH64_STAGE_DIR}/share/emacs.el)

                                                   
add_custom_target(enzo-pathdb-stage DEPENDS
                  ${PATH64_STAGE_DIR}/bin/pathdb
                  ${PATH64_STAGE_DIR}/bin/doctool
                  ${PATH64_STAGE_DIR}/bin/funclookup
                  ${PATH64_STAGE_DIR}/etc/pathdb-help.xml
                  ${PATH64_STAGE_DIR}/share/emacs.el)

add_dependencies(enzo-pathdb-stage pathdb-stage)
add_dependencies(compiler-stage enzo-pathdb-stage)

