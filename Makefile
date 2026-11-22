# xcraft-sdl -- CRAFT 3.5 on SDL2
#
#   make            build ./xcraft
#   make run        build and start the game
#   make clean      remove build products
#
# The game sources (src/*.hc) are written in "hierarchical C++": hcc
# (tools/hcc) expands their refinements into plain C++ under build/gen.

CXX      ?= g++
CXXFLAGS ?= -O2 -g
PKG_CONFIG ?= pkg-config

SDL_CFLAGS := $(shell $(PKG_CONFIG) --cflags sdl2)
SDL_LIBS   := $(shell $(PKG_CONFIG) --libs sdl2)

# The 1997 sources pass string literals as char [], ignore the results of
# fscanf/system and sprintf into fixed buffers; those warnings are silenced
# for them (and only for them). win.cc is built with -Wall -Wextra.
LEGACY_FLAGS := -std=gnu++17 -Wno-write-strings -Wno-unused-result \
                -Wno-format-overflow

BUILD := build
GEN   := $(BUILD)/gen
OBJ   := $(BUILD)/obj
HCC   := $(BUILD)/hcc

HC_SRCS := $(wildcard src/*.hc)
CC_SRCS := $(wildcard src/*.cc)
HEADERS := $(wildcard src/*.h)

OBJS := $(patsubst src/%.hc,$(OBJ)/%.o,$(HC_SRCS)) \
        $(patsubst src/%.cc,$(OBJ)/%.o,$(CC_SRCS))

xcraft: $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(SDL_LIBS) -lm

$(HCC): tools/hcc/hcc.cc src/bool.h
	@mkdir -p $(BUILD)
	$(CXX) -O2 $(LEGACY_FLAGS) -Isrc -o $@ $<

# hcc writes NAME.cc next to NAME.hc; "-compiler true" stops it from
# calling a compiler itself.
$(GEN)/%.cc: src/%.hc $(HCC)
	@mkdir -p $(GEN)
	cp $< $(GEN)/$*.hc
	$(HCC) -compiler true $(GEN)/$*
	@rm -f $(GEN)/$*.err

$(OBJ)/%.o: $(GEN)/%.cc $(HEADERS)
	@mkdir -p $(OBJ)
	$(CXX) $(CXXFLAGS) $(LEGACY_FLAGS) -Isrc $(SDL_CFLAGS) -c -o $@ $<

$(OBJ)/%.o: src/%.cc $(HEADERS)
	@mkdir -p $(OBJ)
	$(CXX) $(CXXFLAGS) -std=gnu++17 -Wall -Wextra -Isrc $(SDL_CFLAGS) -c -o $@ $<

run: xcraft
	./xcraft

clean:
	rm -rf $(BUILD) xcraft

.PHONY: run clean
.PRECIOUS: $(GEN)/%.cc
