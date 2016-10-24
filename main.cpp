/*
 * Bermuda Syndrome engine rewrite
 * Copyright (C) 2007-2011 Gregory Montoir
 */

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif
#include "game.h"
#include "systemstub.h"

#ifdef PSVITA
	#include <psp2/power.h>
	#include <psp2/kernel/processmgr.h>
	#include <psp2/io/fcntl.h>
	#include <psp2/io/stat.h>
	
	
#endif
#include <debugnet.h>
#include <psp2/kernel/processmgr.h>
#define ip_server "192.168.0.195"
#define port_server 18194
static const char *USAGE =
	"Bermuda Syndrome\n"
	"Usage: bs [OPTIONS]...\n"
	"  --datapath=PATH   Path to data files (default 'DATA')\n"
	"  --savepath=PATH   Path to save files (default '.')\n"
	"  --musicpath=PATH  Path to music files (default 'MUSIC')\n";

static bool parseOption(const char *arg, const char *longCmd, const char **opt) {
	bool handled = false;
	if (arg[0] == '-' && arg[1] == '-') {
		if (strncmp(arg + 2, longCmd, strlen(longCmd)) == 0) {
			*opt = arg + 2 + strlen(longCmd);
			handled = true;
		}
	}
	return handled;
}

static Game *g_game;
static SystemStub *g_stub;

static void init(const char *dataPath, const char *savePath, const char *musicPath) {
	g_stub = SystemStub_SDL_create();
	debugNetPrintf(DEBUG,"1");
	g_game = new Game(g_stub, dataPath, savePath, musicPath);
	debugNetPrintf(DEBUG,"2");
	g_game->init();
	debugNetPrintf(DEBUG,"3");
}

static void fini() {
	g_game->fini();
	delete g_game;
	g_stub->destroy();
	delete g_stub;
	g_stub = 0;
}

#ifdef __EMSCRIPTEN__
static void mainLoop() {
	if (!g_stub->_quit) {
		g_game->mainLoop();
	}
}
#endif

#undef main
int main(int argc, char *argv[]) {
int ret;
ret=debugNetInit(ip_server,port_server,DEBUG);

	#ifdef PSVITA
		sceIoMkdir("ux0:data", 0755);
		sceIoMkdir("ux0:data/SOMO00004", 0755);
		sceIoMkdir("ux0:data/SOMO00004", 0755);
		sceIoMkdir("ux0:data/SOMO00004/SAVE", 0755);
		sceIoMkdir("ux0:data/SOMO00004/MUSIC", 0755);
		
		const char *dataPath = "ux0:data/SOMO00004";
		const char *savePath = "ux0:data/SOMO00004/SAVE";
		const char *musicPath = "ux0:data/SOMO00004/MUSIC";
	#else
		const char *dataPath = "DATA";
		const char *savePath = ".";
		const char *musicPath = "MUSIC";
	#endif	

	for (int i = 1; i < argc; ++i) {
		bool opt = false;
		if (strlen(argv[i]) >= 2) {
			opt |= parseOption(argv[i], "datapath=", &dataPath);
			opt |= parseOption(argv[i], "savepath=", &savePath);
			opt |= parseOption(argv[i], "musicpath=", &musicPath);
		}
		if (!opt) {
			printf("%s", USAGE);
			return 0;
		}
	}
	g_debugMask = DBG_INFO; // | DBG_GAME | DBG_OPCODES | DBG_DIALOGUE;
	init(dataPath, savePath, musicPath);
#ifdef __EMSCRIPTEN__
	emscripten_set_main_loop(mainLoop, kCycleDelay, 0);
#else
	while (!g_stub->_quit) {
		g_game->mainLoop();
	}
	fini();
#endif
	return 0;
}
