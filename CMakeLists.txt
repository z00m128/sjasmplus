##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
#
##############################################################

cmake_minimum_required(VERSION 3.9.6)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(sjasmplus)
set(MY_LUA_INCLUDE_DIR "lua5.1")
set(MY_LUA_LIBRARY "lua5.1")
set(MY_TOLUA++_INCLUDE_DIR "tolua++")
set(MY_TOLUA++_LIBRARY "tolua++")

set(SOURCES
	sjasm/devices.cpp
	sjasm/directives.cpp
	sjasm/io_nex.cpp
	sjasm/io_snapshots.cpp
	sjasm/io_tape.cpp
	sjasm/io_trd.cpp
	sjasm/parser.cpp
	sjasm/reader.cpp
	sjasm/sjasm.cpp
	sjasm/sjio.cpp
	sjasm/support.cpp
	sjasm/tables.cpp
	sjasm/z80.cpp
)

add_definitions(-DMAX_PATH=PATH_MAX)
add_definitions(-DCMAKE)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -pedantic")

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -s")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -s")

option(ENABLE_LUA "Enable LUA scripting support" ON)
option(SYSTEM_LUA "Use system LUA and Tolua++ package" OFF)

if(ENABLE_LUA)
	message(STATUS "Looking for Lua and Tolua++")
	message(STATUS "Looking for Tolua++")

	if(SYSTEM_LUA)
		find_package(Tolua++)
	endif(SYSTEM_LUA)

	if(TOLUA++_FOUND)
		message(STATUS "Looking for Tolua++ - found")
		include_directories(${TOLUA++_INCLUDE_DIR})
	else(TOLUA++_FOUND)
		message(STATUS "Looking for Tolua++ - using local")
		set(TOLUA++_LIBRARY ${MY_TOLUA++_LIBRARY})
		set(TOLUA++_INCLUDE_DIR ${MY_TOLUA++_INCLUDE_DIR})
		add_subdirectory(${TOLUA++_INCLUDE_DIR})
		target_include_directories(${MY_TOLUA++_LIBRARY} PUBLIC
            ${TOLUA++_INCLUDE_DIR}
        )
	endif(TOLUA++_FOUND)

	message(STATUS "Looking for Lua 5.1")

	if(SYSTEM_LUA)
		find_package(Lua51)
	endif(SYSTEM_LUA)

	if(LUA51_FOUND)
		message(STATUS "Looking for Lua 5.1 - found: ${LUA_LIBRARIES}")
		include_directories(${LUA_INCLUDE_DIR})
	else(LUA51_FOUND)
		message(STATUS "Looking for Lua 5.1 - using local")
		set(LUA_LIBRARY ${MY_LUA_LIBRARY})
		set(LUA_INCLUDE_DIR ${MY_LUA_INCLUDE_DIR})
		add_subdirectory(${LUA_INCLUDE_DIR})

		target_include_directories(${MY_LUA_LIBRARY} PUBLIC
            ${LUA_INCLUDE_DIR}
		)
	endif(LUA51_FOUND)

	list(APPEND SOURCES
		sjasm/lua_lpack.c
		sjasm/lua_sjasm.cpp
	)

	add_definitions(-DUSE_LUA)

	if( ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		add_definitions(-DLUA_USE_LINUX)
	elseif(CYGWIN)
		add_definitions(-DLUA_USE_LINUX)
	elseif(WIN32)
		add_definitions(-DLUA_USE_WINDOWS)
	endif()
endif(ENABLE_LUA)

include_directories(sjasm)

add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(
	${PROJECT_NAME}
	${LUA_LIBRARY}
	${TOLUA++_LIBRARY}
)

if(NOT WIN32)
	find_package(LibDL)
	if(LIBDL_FOUND)
	target_link_libraries(
		${PROJECT_NAME}
		${LIBDL_LIBRARIES}
	)
	endif(LIBDL_FOUND)
endif()


install(TARGETS ${PROJECT_NAME}
	RUNTIME DESTINATION bin)

find_program(BASH_PROGRAM bash)

if(BASH_PROGRAM)
	add_custom_target(tests COMMAND "EXE=${CMAKE_BINARY_DIR}/${PROJECT_NAME}" ${BASH_PROGRAM} "${CMAKE_SOURCE_DIR}/ContinuousIntegration/test_folder_tests.sh"
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		DEPENDS ${PROJECT_NAME})

	add_custom_target(examples COMMAND "EXE=${CMAKE_BINARY_DIR}/${PROJECT_NAME}" ${BASH_PROGRAM} "${CMAKE_SOURCE_DIR}/ContinuousIntegration/test_folder_examples.sh"
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		DEPENDS ${PROJECT_NAME})
endif()
