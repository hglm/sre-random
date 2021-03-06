# Do not edit normally. Configuration settings are in Makefile.conf.

include Makefile.conf

LIBRARY_NAME = libsrerandom
VERSION = 0.1.2
VERSION_MAJOR = 0

# CFLAGS with optional tuning for CPU
OPTCFLAGS = -Ofast -ffast-math
ifeq ($(TARGET_CPU), CORTEX_A7)
OPTCFLAGS += -mcpu=cortex-a7 -mfpu=vfpv4
endif
ifeq ($(TARGET_CPU), CORTEX_A8)
OPTCFLAGS += -mcpu=cortex-a8
endif
ifeq ($(TARGET_CPU), CORTEX_A9)
OPTCFLAGS += -mcpu=cortex-a9
endif
ifeq ($(LIBRARY_CONFIGURATION), DEBUG)
OPTCFLAGS = -ggdb
endif
CFLAGS = -Wall -pipe $(OPTCFLAGS)

ifeq ($(LIBRARY_CONFIGURATION), SHARED)
LIBRARY_OBJECT = $(LIBRARY_NAME).so.$(VERSION)
INSTALL_TARGET = install_shared
LIBRARY_DEPENDENCY = $(SHARED_LIB_DIR)/$(LIBRARY_OBJECT)
TEST_PROGRAM_LFLAGS = -lsrerandom
CFLAGS_LIB = $(CFLAGS) -fPIC -fvisibility=hidden -DSRE_RANDOM_SHARED -DSRE_RANDOM_SHARED_EXPORTS
else
ifeq ($(LIBRARY_CONFIGURATION), DEBUG)
LIBRARY_OBJECT = $(LIBRARY_NAME)_dbg.a
else
LIBRARY_OBJECT = $(LIBRARY_NAME).a
endif
# install_static also works for debugging library
INSTALL_TARGET = install_static
LIBRARY_DEPENDENCY = $(LIBRARY_OBJECT) $(BACKEND_OBJECT)
TEST_PROGRAM_LFLAGS = $(LIBRARY_OBJECT)
CFLAGS_LIB = $(CFLAGS)
endif

LIBRARY_MODULE_OBJECTS = random.o rng-cmwc.o
LIBRARY_HEADER_FILES = sreRandom.h

default : library

library : $(LIBRARY_OBJECT)

$(LIBRARY_NAME).so.$(VERSION) : $(LIBRARY_MODULE_OBJECTS)
	g++ -shared -Wl,-soname,$(LIBRARY_OBJECT) -fPIC -o $(LIBRARY_OBJECT) \
$(LIBRARY_MODULE_OBJECTS) -lc -lm
	@echo Run '(sudo) make install to install.'

$(LIBRARY_NAME).a : $(LIBRARY_MODULE_OBJECTS)
	ar r $(LIBRARY_OBJECT) $(LIBRARY_MODULE_OBJECTS)
	@echo 'Run (sudo) make install to install, or make test to build the test program.'

$(LIBRARY_NAME)_dbg.a : $(LIBRARY_MODULE_OBJECTS)
	ar r libsre_dbg.a $(LIBRARY_MODULE_OBJECTS)
	@echo 'The library is compiled with debugging enabled.'

install : $(INSTALL_TARGET) install_headers

install_headers : $(LIBRARY_HEADER_FILES)
	@for x in $(LIBRARY_HEADER_FILES); do \
	echo Installing $$x.; \
	install -m 0644 $$x $(INCLUDE_DIR)/$$x; done

install_shared : $(LIBRARY_OBJECT)
	install -m 0644 $(LIBRARY_OBJECT) $(SHARED_LIB_DIR)/$(LIBRARY_OBJECT)
	ln -sf $(SHARED_LIB_DIR)/$(LIBRARY_OBJECT) $(SHARED_LIB_DIR)/$(LIBRARY_NAME).so
	ln -sf $(SHARED_LIB_DIR)/$(LIBRARY_OBJECT) $(SHARED_LIB_DIR)/$(LIBRARY_NAME).so.$(VERSION_MAJOR)
	@echo 'Run make test to build the test program.'

install_static : $(LIBRARY_OBJECT)
	install -m 0644 $(LIBRARY_OBJECT) $(STATIC_LIB_DIR)/$(LIBRARY_OBJECT)

test : test-random

test-random :  $(LIBRARY_DEPENDENCY) test-random.cpp sreRandom.h
	g++ $(CFLAGS) test-random.cpp -o test-random -lm -lfgen $(TEST_PROGRAM_LFLAGS)

clean :
	rm -f $(LIBRARY_MODULE_OBJECTS)
	rm -f test-program
	rm -f $(LIBRARY_NAME).so.$(VERSION)
	rm -f $(LIBRARY_NAME).a
	rm -f $(LIBRARY_NAME)_dbg.a
	rm -f test-program

.cpp.o :
	g++ -c $(CFLAGS_LIB) $< -o $@

dep :
	rm -f .depend
	make .depend

.depend: Makefile.conf Makefile
	g++ -MM $(patsubst %.o,%.cpp,$(LIBRARY_MODULE_OBJECTS)) >> .depend
        # Make sure Makefile.conf is a dependency for all modules.
	for x in $(LIBRARY_MODULE_OBJECTS); do \
	echo $$x : Makefile.conf >> .depend; done
	echo '# Module dependencies' >> .depend
	g++ -MM test-random.cpp >> .depend

include .depend
