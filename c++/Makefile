CC=g++

RESTCLIENT_DIR   = ./inc/restclient-cpp

INC_I           := -I$(RESTCLIENT_DIR)/include
INC_L           := -L$(RESTCLIENT_DIR)/lib 
CC_FLAGS        := $(INC_I) $(INC_L)

LD_FLAGS        := -lrestclient-cpp -lboost_iostreams -lcurl -lz -ljsoncpp

H_FILES         := $(wildcard src/**/*.h) $(wildcard src/*.h)
CPP_FILES       := $(wildcard src/**/*.cpp) $(wildcard src/*.cpp)
OBJ_FILES       := $(patsubst src/%.cpp,obj/%.o,$(CPP_FILES))

EXECUTABLE       = liquidplanner

$(EXECUTABLE): $(OBJ_FILES)
	g++ $(INC_L) $^ -o $@ $(LD_FLAGS)

$(OBJ_FILES): obj/%.o : src/%.cpp
	mkdir -p $(dir $@)
	g++ $(CC_FLAGS) -c -o $@ $< $(LD_FLAGS)

$(CPP_FILES): $(H_FILES)

clean:
	rm -r obj/*
	rm $(EXECUTABLE)

run: $(EXECUTABLE)
	clear
	./$(EXECUTABLE)
