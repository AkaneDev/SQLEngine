# Makefile for SQL Game Engine

CXX = g++
CXXFLAGS = -std=c++17 -O2 -Iinclude
LDFLAGS = -lsqlite3 -pthread -lSDL2

SRC = $(wildcard src/*.cpp)
OBJ = $(SRC:.cpp=.o)
TARGET = sqlEngine

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)
