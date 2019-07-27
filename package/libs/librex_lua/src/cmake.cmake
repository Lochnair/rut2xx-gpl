### This is make file for CLION ###
#include(${CMAKE_CURRENT_SOURCE_DIR}/lib.cmake)

# Setting package name
SET_PROJECT(librex_lua)

COMPILE_LIB(librex_lua shared "librex_lua.c;librex_lua_f.c;common.c")
ADD_LIB("lua;pcre")
INCLUDE_DIR("include")
SET_CFLAGS("-O2 -fPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN -I/usr/include/lua5.1")

# Create Makefile for compilation, from this CMAKE
#FILL_MAKE_FILE()

# Use make command, to build package
#MAKE_PACKAGE()

# ONLY if SSHPASS is installed
##COPY_TO_ROUTER_LOC(false /usr/lib/ 192.168.1.1 root admin01)