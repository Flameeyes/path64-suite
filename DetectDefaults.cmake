# Script MIT-licensed
# Copyright 2011 Iowa State University.
#
#Permission is hereby granted, free of charge, to any person obtaining a
#copy of this software and associated documentation files (the
#"Software"), to deal in the Software without restriction, including
#without limitation the rights to use, copy, modify, merge, publish,
#distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to
#the following conditions:

#The above copyright notice and this permission notice shall be included
#in all copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Called by default setting routines that need the basic gcc to do their work,
# so we don't require this unless necessary.
function(get_gcc_to_detect VARNAME)
	if(CMAKE_COMPILER_IS_GNUCXX)
		set(PATH64_GCC_EXECUTABLE "${CMAKE_C_COMPILER}")
		set(PATH64_GCC_EXECUTABLE "${PATH64_GCC_EXECUTABLE}" CACHE FILEPATH "Path to gcc" FORCE)
	else()
		find_program(PATH64_GCC_EXECUTABLE gcc)
	endif()
	if(NOT EXISTS "${PATH64_GCC_EXECUTABLE}")
		message(SEND_ERROR "No file exists at path given for gcc '${PATH64_GCC_EXECUTABLE}'.")
		set(PATH64_GCC_EXECUTABLE NOTFOUND)
		set(PATH64_GCC_EXECUTABLE "${PATH64_GCC_EXECUTABLE}" CACHE FILEPATH "Path to gcc" FORCE)
	endif()
	if(PATH64_GCC_EXECUTABLE)
		mark_as_advanced(PATH64_GCC_EXECUTABLE)
	else()
		message(SEND_ERROR "Could not find GCC - won't be able to automatically set variable '${VARNAME}'.")
	endif()
endfunction()

# Called by default setting routines that need the machine-gcc to do their work,
# so we don't require this unless necessary.
function(get_machine_gcc_to_detect VARNAME)
	get_gcc_to_detect(${VARNAME})
	if(NOT PSC_TARGET)
		message(SEND_ERROR "PSC_TARGET not set, so can't set PATH64_MACHINE_GCC_EXECUTABLE which is needed for ${VARNAME}")
	else()
		find_program(PATH64_MACHINE_GCC_EXECUTABLE ${PSC_TARGET}-gcc)
		if(PATH64_MACHINE_GCC_EXECUTABLE)
			mark_as_advanced(PATH64_MACHINE_GCC_EXECUTABLE)
		else()
			message(SEND_ERROR "Could not find GCC for ${PSC_TARGET} - won't be able to automatically set variable '${VARNAME}'.")
		endif()
	endif()
endfunction()

# GCC can tell us a default PSC_TARGET
if(NOT PSC_TARGET)
	get_gcc_to_detect(PSC_TARGET)
	if(PATH64_GCC_EXECUTABLE)
		set(_dumpmachine_command ${PATH64_GCC_EXECUTABLE} -dumpmachine)
		execute_process(COMMAND ${_dumpmachine_command}
			OUTPUT_VARIABLE _dumpmachine_output
			ERROR_QUIET
			RESULT_VARIABLE _dumpmachine_result
			OUTPUT_STRIP_TRAILING_WHITESPACE)
		if(NOT _dumpmachine_result EQUAL 0)
			message(FATAL_ERROR "Could not run '${_dumpmachine_command}' - got ${_dumpmachine_result}. Can't automatically set variables.")
		endif()
		set(PSC_TARGET "${_dumpmachine_output}" CACHE STRING "Target string")
		message(STATUS "Detected PSC_TARGET as '${PSC_TARGET}'")
	endif()
endif()

# PSC_TARGET implies defaults for PATH64_ENABLE_TARGETS
if(PSC_TARGET AND NOT PATH64_ENABLE_TARGETS)
	if(PSC_TARGET MATCHES "mips64")
		set(PATH64_ENABLE_TARGETS mips_32 mips_64)
	elseif((PSC_TARGET MATCHES "x86.*64.*") OR (PSC_TARGET MATCHES "amd64.*"))
		set(PATH64_ENABLE_TARGETS x86_64)
	else()
		message(FATAL_ERROR "Couldn't auto-identify targets with PSC_TARGET='${PSC_TARGET}'!")
	endif()
	set(PATH64_ENABLE_TARGETS "${PATH64_ENABLE_TARGETS}" CACHE STRING "Targets to enable.")
	message(STATUS "Detected PATH64_ENABLE_TARGETS as '${PATH64_ENABLE_TARGETS}'")
endif()

# If we have targets, each one of them should have some additional variables
if(PATH64_ENABLE_TARGETS)
	# Check all enabled targets
	foreach(TARGET_NAME ${PATH64_ENABLE_TARGETS})
		if(TARGET_NAME STREQUAL "mips_32")
			set(TARGET_FLAGS "-mabi=n32")
		elseif(TARGET_NAME STREQUAL "mips_64")
			set(TARGET_FLAGS "-mabi=64")
		elseif(TARGET_NAME STREQUAL "x86_64")
			set(TARGET_FLAGS "-m64")
		else()
			message(FATAL_ERROR "Don't know what flags to use for target '${TARGET_NAME}'")
		endif()

		# Determine a default value for PSC_CRTBEGIN_PATH_${TARGET_NAME}
		if(NOT PSC_CRTBEGIN_PATH_${TARGET_NAME})
			get_machine_gcc_to_detect(PSC_CRTBEGIN_PATH_${TARGET_NAME})
			if(PATH64_MACHINE_GCC_EXECUTABLE)
				message(STATUS "Detecting PSC_CRTBEGIN_PATH_${TARGET_NAME}...")
				execute_process(COMMAND ${PATH64_MACHINE_GCC_EXECUTABLE} ${TARGET_FLAGS} -print-libgcc-file-name
					OUTPUT_VARIABLE _libgcc_fn
					ERROR_QUIET
					OUTPUT_STRIP_TRAILING_WHITESPACE)

				if(_libgcc_fn)
					get_filename_component(PSC_CRTBEGIN_PATH_${TARGET_NAME} "${_libgcc_fn}" PATH CACHE)
					message(STATUS "Detected PSC_CRTBEGIN_PATH_${TARGET_NAME} as ${PSC_CRTBEGIN_PATH_${TARGET_NAME}}")
				endif()
			endif()
		endif()

		# Determine a default value for PSC_CRT_PATH_${TARGET_NAME}
		if(NOT PSC_CRT_PATH_${TARGET_NAME})
			get_machine_gcc_to_detect(PSC_CRT_PATH_${TARGET_NAME})
			if(PATH64_MACHINE_GCC_EXECUTABLE)
				message(STATUS "Detecting PSC_CRT_PATH_${TARGET_NAME}...")
				execute_process(COMMAND ${PATH64_MACHINE_GCC_EXECUTABLE} ${TARGET_FLAGS} -print-file-name=crt1.o
					OUTPUT_VARIABLE _crt_fn
					ERROR_QUIET
					OUTPUT_STRIP_TRAILING_WHITESPACE)

				if(_crt_fn)
					get_filename_component(PSC_CRT_PATH_${TARGET_NAME} "${_crt_fn}" PATH CACHE)
					message(STATUS "Detected PSC_CRT_PATH_${TARGET_NAME} as ${PSC_CRT_PATH_${TARGET_NAME}}")
				endif()
			endif()
		endif()

		# Determine a default value for PSC_DYNAMIC_LINKER_${TARGET_NAME}
		if(NOT PSC_DYNAMIC_LINKER_${TARGET_NAME})
			get_machine_gcc_to_detect(PSC_DYNAMIC_LINKER_${TARGET_NAME})
			if(PATH64_MACHINE_GCC_EXECUTABLE)
				message(STATUS "Detecting PSC_DYNAMIC_LINKER_${TARGET_NAME}...")
				execute_process(COMMAND ${PATH64_MACHINE_GCC_EXECUTABLE} ${TARGET_FLAGS} --help -v
					#COMMAND awk "'/-dynamic-linker/ { match($0, \"-dynamic-linker +[^ ]+\"); print substr($0, RSTART+16, RLENGTH-16) }'"
					OUTPUT_QUIET
					ERROR_VARIABLE _ldso_output)

				if(_ldso_output MATCHES "-dynamic-linker ([^ ]+)")
					set(PSC_DYNAMIC_LINKER_${TARGET_NAME} "${CMAKE_MATCH_1}" CACHE FILEPATH "Dynamic linker library for ${TARGET_NAME}")
					message(STATUS "Detected PSC_DYNAMIC_LINKER_${TARGET_NAME} as ${PSC_DYNAMIC_LINKER_${TARGET_NAME}}")
				endif()
			endif()
		endif()
	endforeach()
endif()

