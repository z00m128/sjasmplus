##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
#
##############################################################

cmake_minimum_required(VERSION 3.9.6)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(tolua++)

set(TOLUA_SOURCES 
	tolua_event.c
	tolua_is.c
	tolua_map.c
	tolua_push.c
	tolua_to.c
)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -pedantic")

option(SYSTEM_LUA "Use system LUA and Tolua++ package" OFF)

if(SYSTEM_LUA)
	find_package(Lua51)
endif(SYSTEM_LUA)

if(LUA51_FOUND)
	message(STATUS "Local ${PROJECT_NAME} - Looking for Lua 5.1 - found")
else(LUA51_FOUND)
	message(STATUS "Local ${PROJECT_NAME} - Looking for Lua 5.1 - using local")
	include_directories("../lua5.1")
	set(LUA_SOURCE_DIR "../lua5.1")
endif(LUA51_FOUND)

add_library(tolua++ ${TOLUA_SOURCES} ${LUA_SOURCE_DIR})
target_link_libraries(tolua++ ${LUA_LIBRARY})
target_include_directories(tolua++ PUBLIC include)
