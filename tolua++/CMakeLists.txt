##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
#
##############################################################

cmake_minimum_required(VERSION 3.1.0)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(tolua++)

set(TOLUA_SOURCES 
	tolua_event.c
	tolua_is.c
	tolua_map.c
	tolua_push.c
	tolua_to.c
)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -Wabi -pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -Wabi -pedantic")

include_directories("../lua5.1")

add_library(tolua++ ${TOLUA_SOURCES})
target_link_libraries(tolua++ lua5.1)
target_include_directories(tolua++ PUBLIC include)
