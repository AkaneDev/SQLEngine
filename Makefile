# Makefile for SQL Game Engine (portable)

CXX := g++
TARGET := sqlEngine

SRC := $(wildcard src/*.cpp)
OBJ := $(SRC:.cpp=.o)

# Base flags
CXXFLAGS := -std=c++17 -O2 -Iinclude
LDFLAGS  := -lsqlite3

# SDL2 (portable)
CXXFLAGS += $(shell sdl2-config --cflags)
LDFLAGS  += $(shell sdl2-config --libs)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CXX) $(OBJ) -o $@ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)
