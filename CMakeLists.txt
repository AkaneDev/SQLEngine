cmake_minimum_required(VERSION 3.16)
project(SQLGameEngine VERSION 1.0 LANGUAGES CXX)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Add source files
file(GLOB SRC_FILES "src/*.cpp")

# Create the executable
add_executable(sqlEngine ${SRC_FILES})

# Include directories
target_include_directories(sqlEngine PRIVATE include)

# Find SQLite3
find_package(SQLite3 REQUIRED)
if(SQLite3_FOUND)
    target_include_directories(sqlEngine PRIVATE ${SQLite3_INCLUDE_DIRS})
    target_link_libraries(sqlEngine PRIVATE ${SQLite3_LIBRARIES})
endif()

# Find SDL2
find_package(SDL2 REQUIRED)
if(SDL2_FOUND)
    target_include_directories(sqlEngine PRIVATE ${SDL2_INCLUDE_DIRS})
    target_link_libraries(sqlEngine PRIVATE ${SDL2_LIBRARIES})
endif()

# Optional: optimization flags
if(MSVC)
    target_compile_options(sqlEngine PRIVATE /O2)
else()
    target_compile_options(sqlEngine PRIVATE -O2)
endif()
