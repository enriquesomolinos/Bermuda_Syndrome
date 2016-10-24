TARGET = Bermuda_Syndrome
TITLE_ID = SOMO00004
PSVITAIP = 192.168.0.201

# List of possible defines :
# BERMUDA_WIN32  : enable windows directory browsing code
# BERMUDA_POSIX  : enable unix/posix directory browsing code
# BERMUDA_VORBIS : enable playback of digital soundtracks (22 khz mono .ogg files)


DEFINES = -DBERMUDA_PSVITA  -DBERMUDA_VORBIS -DPSVITA
 VORBIS_LIBS= -lvorbisfile -lvorbis -logg

PREFIX   = arm-vita-eabi
CC       = $(PREFIX)-gcc
CXX      = $(PREFIX)-g++
CFLAGS   =  $(INCDIR) -fpermissive  -Wl,-q -Wall -O3  -Wno-write-strings  -Wno-unused-variable -Wno-unused-function  -Wno-unused-but-set-variable -DPSVITA
CXXFLAGS = $(CFLAGS)  -std=c++11 $(DEFINES)
ASFLAGS  = $(CFLAGS)

OBJDIR = obj

SRCS = avi_player.cpp bag.cpp decoder.cpp dialogue.cpp file.cpp fs.cpp game.cpp \
	main.cpp mixer_sdl.cpp mixer_soft.cpp opcodes.cpp parser_dlg.cpp parser_scn.cpp \
	random.cpp resource.cpp saveload.cpp staticres.cpp str.cpp systemstub_sdl.cpp \
	util.cpp win16.cpp

OBJS = $(SRCS:.cpp=.o)
DEPS = $(SRCS:.cpp=.d)

LIBS +=  -lSDL2  -lSDL2_mixer -lvita2d  ${VORBIS_LIBS}  \
			 -ldebugnet -lSceNetCtl_stub -lSceNet_stub \
	     -lSceKernel_stub -lSceGxm_stub -lSceDisplay_stub -lSceCtrl_stub -lSceAudio_stub \
		 -lSceSysmodule_stub -lScePgf_stub -lSceCommonDialog_stub \
		 -lScePower_stub -lfreetype -lpng -ljpeg -lz -lm -lc

all: $(OBJDIR) bs

bs: $(addprefix $(OBJDIR)/, $(OBJS))
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) 

$(OBJDIR):
	mkdir $(OBJDIR)

$(OBJDIR)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) -MMD -c $< -o $@


all: $(TARGET).vpk

%.vpk: eboot.bin
	vita-mksfoex  -s TITLE_ID=$(TITLE_ID) "$(TARGET)" param.sfo
	vita-pack-vpk -s param.sfo -b eboot.bin \
		--add pkg/sce_sys/icon0.png=sce_sys/icon0.png \
		--add pkg/sce_sys/livearea/contents/bg.png=sce_sys/livearea/contents/bg.png \
		--add pkg/sce_sys/livearea/contents/startup.png=sce_sys/livearea/contents/startup.png \
		--add pkg/sce_sys/livearea/contents/template.xml=sce_sys/livearea/contents/template.xml \
	$(TARGET).vpk
	
eboot.bin: $(TARGET).velf
	vita-make-fself -s $< $@
	
%.velf: %.elf	
	vita-elf-create $< $@

$(TARGET).elf: $(OBJS)
	$(CXX) $(CXXFLAGS) $^ $(LIBS) -o $@

%.o: %.png
	$(PREFIX)-ld -r -b binary -o $@ $^
%.o: %.txt
	$(PREFIX)-ld -r -b binary -o $@ $^

%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) -o $@ $<
	
	
vpksend: $(TARGET).vpk
	curl -T $(TARGET).vpk ftp://$(PSVITAIP):1337/ux0:/
	@echo "Sent."
send: eboot.bin
	curl -T eboot.bin ftp://$(PSVITAIP):1337/ux0:/app/$(TITLE_ID)/
	@echo "Sent."
clean:
    
	@rm -rf $(TARGET).velf $(TARGET).elf $(TARGET).vpk eboot.bin param.sfo *.o