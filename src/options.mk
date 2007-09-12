
# Build options for RoadMap.  Mostly this file shouldn't need
# to be edited.  Personal changes can probably be made in config.mk

include $(TOP)/config.mk

# --- Installation options -------------------------------------------------

DESTDIR = 
INSTALLDIR = /usr/local
desktopdir = $(INSTALLDIR)/applications
bindir = $(INSTALLDIR)/bin
pkgbindir = $(bindir)

# if the user compiled in a new config dir, install to it
ifneq ($(strip $(ROADMAP_CONFIG_DIR)),)
pkgdatadir = $(ROADMAP_CONFIG_DIR)
else
pkgdatadir = $(INSTALLDIR)/share/roadmap
endif

# if the user compiled in a new map dir, create it here
ifneq ($(strip $(ROADMAP_MAP_DIR)),)
pkgmapsdir = $(ROADMAP_MAP_DIR)
else
pkgmapsdir = /var/lib/roadmap
endif

menudir = $(DESTDIR)/usr/lib/menu
icondir = $(INSTALLDIR)/share/pixmaps
mandir = $(INSTALLDIR)/share/man
man1dir = $(mandir)/man1

INSTALL      = install
INSTALL_DATA = install -m644
# the image conversion tool "convert" comes with ImageMagick.
# on debian or ubuntu:  "apt-get install imagemagick"
CONVERT      = convert

# if you want to cross-compile, define CROSS in config.mk.  you
# may also have to add paths to libraries (with -L) in LDFLAGS.
CC =    $(CROSS)gcc
CXX =   $(CROSS)g++
AS =    $(CROSS)as
AR =    $(CROSS)ar
LD =    $(CROSS)ld
STRIP = $(CROSS)strip
RANLIB = $(CROSS)ranlib


# --- Build options ------------------------------------------------

ALL_RDMODULES = gtk gtk2 qt qt4

ifeq ($(DESKTOP),GTK2)
	RDMODULES=gtk2
else
ifeq ($(DESKTOP),GPE)
	RDMODULES=gtk2
else
ifeq ($(DESKTOP),GTK)
	RDMODULES=gtk
else
ifeq ($(DESKTOP),QT)
	RDMODULES=qt
else
ifeq ($(DESKTOP),QT4)
	RDMODULES=qt4
else
ifeq ($(DESKTOP),QPE)
	RDMODULES=qt
else
ifeq ($(DESKTOP),QPE4)
	RDMODULES=qt4
else
ifeq ($(DESKTOP),WINCE)
	RDMODULES=win32
else
	RDMODULES=$(ALL_RDMODULES)
endif
endif
endif
endif
endif
endif
endif
endif

ifneq ($(DESKTOP),WINCE)
	LIBOS = $(TOP)/unix/libosroadmap.a
	OSDIR = unix
endif


ifeq ($(strip $(MODE)),DEBUG)
	# Memory leak detection using mtrace:
	# Do not forget to set the trace file using the env. 
	# variable MALLOC_TRACE, then use the mtrace tool to
	# analyze the output.
	#
	# (another excellent tool for this purpose, by the way,
	#  is "valgrind", which needs no special compilation --
	#  it works by replacing shared libraries.)
	#
	CFLAGS += -g -DROADMAP_DEBUG_HEAP -DROADMAP_LISTS_TYPESAFE
else
ifeq ($(strip $(MODE)),PROFILE)
	CFLAGS += -g -pg -fprofile-arcs -g
	LIBS += -pg
else
	CFLAGS += -O2 -ffast-math -fomit-frame-pointer
endif
endif

WARNFLAGS = -W \
	-Wall \
	-Wno-unused-parameter \
	-Wcast-align \
	-Wreturn-type \
	-Wsign-compare

#	 -Wpointer-arith \

CFLAGS += $(WARNFLAGS) 


RDMLIBS= $(TOP)/libroadmap.a \
	$(LIBOS) \
	$(TOP)/gpx/libgpx.a \
	$(TOP)/libroadmap.a 

LIBS += $(RDMLIBS)

ifneq ($(strip $(ROADMAP_CONFIG_DIR)),)
	CFLAGS += -DROADMAP_CONFIG_DIR=\"$(ROADMAP_CONFIG_DIR)\"
endif
ifneq ($(strip $(ROADMAP_MAP_DIR)),)
	CFLAGS += -DROADMAP_MAP_DIR=\"$(ROADMAP_MAP_DIR)\"
endif

# expat library, for xml GPX format
ifneq ($(strip $(EXPAT)),NO)
	LIBS += -lexpat 
	CFLAGS += -DROADMAP_USES_EXPAT
endif

# popt library, for option parsing (only in some programs)
ifneq ($(strip $(POPT)),NO)
	LIBS += -lpopt 
endif

# shapefile support needed for building some mapsets
ifneq ($(strip $(SHAPEFILES)),NO)
	CFLAGS += -DROADMAP_USE_SHAPEFILES
	LIBS += -lshp
endif

# rotation support in QT/QPE?
ifeq ($(strip $(QT_NO_ROTATE)),YES)
	CFLAGS += -DQT_NO_ROTATE
else
ifeq ($(strip $(DESKTOP)),QT)
	CFLAGS += -DROADMAP_NO_LINEFONT
endif
ifeq ($(strip $(DESKTOP)),QT4)
	CFLAGS += -DROADMAP_NO_LINEFONT
endif
ifeq ($(strip $(DESKTOP)),QPE)
	CFLAGS += -DROADMAP_NO_LINEFONT
endif
ifeq ($(strip $(DESKTOP)),QPE4)
	CFLAGS += -DROADMAP_NO_LINEFONT
endif
endif


# each DESKTOP version has a fully-"native" canvas
# implementation, as well as a possible agg-based implementation.
ifeq ($(strip $(AGG)),NO)
	CANVAS_OBJS = roadmap_canvas.o
else
	LIBS += -laggfontfreetype -lagg -lfreetype
	CFLAGS += -DROADMAP_NO_LINEFONT \
		-I$(TOP)/agg_support \
		-I/usr/include/agg2 \
		-I/usr/local/include/agg2 \
		-I/usr/include/freetype2
	CANVAS_OBJS = roadmap_canvas_agg.o \
		$(TOP)/agg_support/roadmap_canvas.o
endif

# bidirectional text lib
ifneq ($(strip $(BIDI)),NO)
	LIBS += -lfribidi
	CFLAGS += -DUSE_FRIBIDI -I/usr/include/fribidi
endif

# RoadMap internal profiling
ifeq ($(strip $(DBG_TIME)),YES)
	CFLAGS += -DROADMAP_DBG_TIME
endif


HOST=`uname -s`
ifeq ($(HOST),Darwin)
	ARFLAGS="r"
else
	ARFLAGS="rf"
endif


CFLAGS += -I$(TOP) -I/usr/local/include -DNDEBUG

LIBS := -L/usr/local/lib $(LIBS) -lm

CXXFLAGS = $(CFLAGS)