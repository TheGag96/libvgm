########################
#
# libvgm Makefile
#
########################

DEBUG = 0

ifeq ($(OS),Windows_NT)
WINDOWS = 1
else
WINDOWS = 0
endif

ifeq ($(WINDOWS), 0)
USE_BSD_AUDIO = 0
USE_ALSA = 1
USE_LIBAO = 1
USE_PULSE = 1
endif

CC = gcc
CXX = g++
PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man

ifeq ($(DEBUG), 1)
CFLAGS := -O0 -g $(CFLAGS) -D_DEBUG -I.
else
CFLAGS := -O2 -g0 $(CFLAGS) -I.
endif
CCFLAGS = -std=gnu90
CXXFLAGS = -std=gnu++98
ARFLAGS = -cr

CFLAGS += -Wall
#CFLAGS += -Wextra
#CFLAGS += -Wpedantic
CFLAGS += -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-long-long

# silence typical sound core warnings
ifneq ($(DEBUG), 1)
CFLAGS += -Wno-unknown-pragmas
CFLAGS += -Wno-unused-value -Wno-sign-compare
CFLAGS += -Wno-unused-variable -Wno-unused-const-variable -Wno-unused-function
endif

# additional warnings from http://blog.httrack.com/blog/2014/03/09/what-are-your-gcc-flags/
CFLAGS += -Wpointer-arith -Winit-self -Wstrict-aliasing
CFLAGS += -Wformat -Wformat-security -Wformat-nonliteral
#CFLAGS += -fstack-protector -Wpointer-arith -Winit-self
#LDFLAGS += -fstack-protector

# add Library Path, if defined
ifdef LD_LIBRARY_PATH
LDFLAGS += -L $(LD_LIBRARY_PATH)
endif

#CFLAGS += -D__BIG_ENDIAN__


ifeq ($(WINDOWS), 1)
CFLAGS += -Ilibs/include_mingw
# assume Windows 2000 and later for GetConsoleWindow API call
CFLAGS += -D _WIN32_WINNT=0x500
endif

ifeq ($(WINDOWS), 1)
# for Windows, add kernel32 and winmm (Multimedia APIs)
LDFLAGS += -lkernel32 -lwinmm -ldsound -luuid -lole32
else
# for Linux add pthread support (-pthread should include -lpthread)
LDFLAGS += -lrt -pthread
CFLAGS += -pthread -DSHARE_PREFIX=\"$(PREFIX)\"

# add librt (clock stuff)
#LDFLAGS += -lrt
endif

SRC = .
OBJ = obj
LIBAUDSRC = $(SRC)/audio
LIBAUDOBJ = $(OBJ)/audio
LIBEMUSRC = $(SRC)/emu
LIBEMUOBJ = $(OBJ)/emu
UTILSRC = $(SRC)/utils
UTILOBJ = $(OBJ)/utils

OBJDIRS = \
	$(OBJ) \
	$(LIBAUDOBJ) \
	$(LIBEMUOBJ) \
	$(LIBEMUOBJ)/cores \
	$(OBJ)/vgm \
	$(UTILOBJ) \
	$(OBJ)/player

ALL_LIBS = \
	$(LIBAUD_A) \
	$(LIBEMU_A)


#### Audio Output Library ####
AUD_MAINOBJS = \
	$(OBJ)/audiotest.o
LIBAUD_A = $(OBJ)/libaudio.a
LIBAUDOBJS = \
	$(LIBAUDOBJ)/AudioStream.o \
	$(LIBAUDOBJ)/AudDrv_WaveWriter.o
CFLAGS += -D AUDDRV_WAVEWRITE

ifeq ($(WINDOWS), 1)
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_WinMM.o \
	$(LIBAUDOBJ)/AudDrv_DSound.o \
	$(LIBAUDOBJ)/AudDrv_XAudio2.o
	#$(LIBAUDOBJ)/AudDrv_WASAPI.o	# MinGW lacks the required header files
CFLAGS += -D AUDDRV_WINMM
CFLAGS += -D AUDDRV_DSOUND
CFLAGS += -D AUDDRV_XAUD2
#CFLAGS += -D AUDDRV_WASAPI
endif

ifneq ($(WINDOWS), 1)
ifneq ($(USE_BSD_AUDIO), 1)
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_OSS.o
CFLAGS += -D AUDDRV_OSS
else
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_SADA.o
CFLAGS += -D AUDDRV_SADA
endif

ifeq ($(USE_ALSA), 1)
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_ALSA.o
LDFLAGS += -lasound
CFLAGS += -D AUDDRV_ALSA
endif

ifeq ($(USE_PULSE), 1)
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_Pulse.o
LDFLAGS += -lpulse-simple -lpulse
CFLAGS += -D AUDDRV_PULSE
endif

endif

ifeq ($(USE_LIBAO), 1)
LIBAUDOBJS += \
	$(LIBAUDOBJ)/AudDrv_libao.o
LDFLAGS += -lao
CFLAGS += -D AUDDRV_LIBAO
endif


#### Sound Emulation Library ####
EMU_MAINOBJS = \
	$(OBJ)/emutest.o
LIBEMU_A = $(OBJ)/libemu.a
LIBEMUOBJS = \
	$(LIBEMUOBJ)/SoundEmu.o \
	$(LIBEMUOBJ)/cores/vsu.o \
	$(LIBEMUOBJ)/Resampler.o \
	$(LIBEMUOBJ)/panning.o \
	$(LIBEMUOBJ)/dac_control.o


UTILOBJS = \
	$(UTILOBJ)/OSMutex_POSIX.o \
	$(UTILOBJ)/OSSignal_POSIX.o \
	$(UTILOBJ)/OSThread_POSIX.o

AUDEMU_MAINOBJS = \
	$(OBJ)/audemutest.o

VGMTEST_MAINOBJS = \
	$(OBJ)/player/dblk_compr.o \
	$(OBJ)/vgmtest.o

PLAYER_MAINOBJS = \
	$(OBJ)/player/helper.o \
	$(UTILOBJ)/DataLoader.o \
	$(UTILOBJ)/FileLoader.o \
	$(UTILOBJ)/MemoryLoader.o \
	$(UTILOBJ)/StrUtils-CPConv_IConv.o \
	$(OBJ)/player/playerbase.o \
	$(OBJ)/player/s98player.o \
	$(OBJ)/player/droplayer.o \
	$(OBJ)/player/vgmplayer.o \
	$(OBJ)/player/vgmplayer_cmdhandler.o \
	$(OBJ)/player/dblk_compr.o \
	$(OBJ)/player.o

VGMPLAYER_A = $(OBJ)/libvgmplayer.a
VGMPLAYER_MAINOBJS = \
	$(OBJ)/player/helper.o \
	$(UTILOBJ)/DataLoader.o \
	$(UTILOBJ)/FileLoader.o \
	$(UTILOBJ)/MemoryLoader.o \
	$(UTILOBJ)/StrUtils-CPConv_IConv.o \
	$(OBJ)/player/playerbase.o \
	$(OBJ)/player/vgmplayer.o \
	$(OBJ)/player/vgmplayer_cmdhandler.o \
	$(OBJ)/player/dblk_compr.o

all:	audiotest emutest audemutest vgmtest plrtest

audiotest:	dirs libaudio $(UTILOBJS) $(AUD_MAINOBJS)
	echo Linking audiotest ...
	$(CC) $(UTILOBJS) $(AUD_MAINOBJS) $(LIBAUD_A) $(LDFLAGS) -o $@
	echo Done.

libaudio:	$(LIBAUDOBJS)
	echo Archiving libaudio.a ...
	$(AR) $(ARFLAGS) $(LIBAUD_A) $(LIBAUDOBJS)

emutest:	dirs libemu $(EMU_MAINOBJS)
	echo Linking emutest ...
	$(CC) $(EMU_MAINOBJS) $(LIBEMU_A) $(LDFLAGS) -lm -o $@
	echo Done.

libemu:	$(LIBEMUOBJS)
	echo Archiving libemu.a ...
	$(AR) $(ARFLAGS) $(LIBEMU_A) $(LIBEMUOBJS)

audemutest:	dirs libaudio libemu $(UTILOBJS) $(AUDEMU_MAINOBJS)
	echo Linking audemutest ...
	$(CC) $(UTILOBJS) $(AUDEMU_MAINOBJS) $(LIBAUD_A) $(LIBEMU_A) $(LDFLAGS) -lm -o $@
	echo Done.

vgmtest:	dirs libaudio libemu $(UTILOBJS) $(VGMTEST_MAINOBJS)
	echo Linking vgmtest ...
	$(CC) $(UTILOBJS) $(VGMTEST_MAINOBJS) $(LIBAUD_A) $(LIBEMU_A) $(LDFLAGS) -lz -lm -o $@
	echo Done.

plrtest:	dirs libaudio libemu $(UTILOBJS) $(PLAYER_MAINOBJS)
	echo Linking $@ ...
	$(CXX) $(UTILOBJS) $(PLAYER_MAINOBJS) $(LIBAUD_A) $(LIBEMU_A) $(LDFLAGS) -lz -lm -o $@
	echo Done.

vgm_dbcompr_bench:	vgm_dbcompr_bench.c vgm/dblk_compr.c
	echo Compiling+Linking vgm_dbcompr_bench
	$(CC) $(CFLAGS) $(CCFLAGS) $^ $(LDFLAGS) -o vgm_dbcompr_bench
	echo Done.

vgmplayer: dirs libemu $(UTILOBJS) $(VGMPLAYER_MAINOBJS)
	echo Archiving vgmplayer.a ...
	$(AR) $(ARFLAGS) $(VGMPLAYER_A) $(VGMPLAYER_MAINOBJS)


dirs:
	mkdir -p $(OBJDIRS)

$(OBJ)/%.o: $(SRC)/%.c
	echo Compiling $< ...
	$(CC) $(CFLAGS) $(CCFLAGS) -c $< -o $@

$(OBJ)/%.o: $(SRC)/%.cpp
	echo Compiling $< ...
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	echo Deleting object files ...
	rm -f $(AUD_MAINOBJS) $(EMU_MAINOBJS) $(AUDEMU_MAINOBJS) $(VGMTEST_MAINOBJS) $(S98TEST_MAINOBJS) $(ALL_LIBS) $(LIBAUDOBJS) $(LIBEMUOBJS) $(PLAYER_MAINOBJS) $(VGMPLAYER_MAINOBJS)
	echo Deleting executable files ...
	rm -f audiotest emutest audemutest vgmtest
	echo Done.

#.PHONY: all clean install uninstall
