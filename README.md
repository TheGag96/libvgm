# libvgm (modified for the 3DS)

This is a VERY quick-and-dirty modification of libvgm to be able to compile and run on the 3DS. To use, make sure devkitARM is installed, and compile with:

```Makefile
make -f Makefile.3ds vgmplayer
```

And use the generated `libemu.a` and `libvgmplayer.a` files in your project. The linking dependencies will look like:

```
-lvgmplayer -lemu -lz -lstdc++
```

To make things super simple and remove the need for dealing with the project's existing header files, I made a very basic `extern "C"` wrapper with only a few definitions needed for just loading a file with the `VGMPlayer` class and rendering samples:

```cpp
typedef int32_t DEV_SMPL;
typedef struct _waveform_32bit_stereo
{
  DEV_SMPL L;
  DEV_SMPL R;
} WAVE_32BS;

extern "C" void    vgm_init_player();                            //initializes the VGMPlayer object
extern "C" void    vgm_deinit_player();                          //closes/frees everything
extern "C" uint8_t vgm_load_file(const char* path);              //loads the file at the given path to RAM and sets up playback; ready for vgm_render after call
extern "C" int32_t vgm_render(int32_t smplCnt, WAVE_32BS* data); //renders
extern "C" uint8_t vgm_set_sample_rate(int32_t sampleRate);      //sets the sample rate of the rendered samples
extern "C" uint8_t vgm_seek(int8_t unit, int32_t pos);           //seeks within the loaded vgm file
```

...or for D:

```d
alias DEV_SMPL = int;
struct WAVE_32BS {
  DEV_SMPL L;
  DEV_SMPL R;
}

extern (C) void  vgm_init_player();                        //initializes the VGMPlayer object
extern (C) void  vgm_deinit_player();                      //closes/frees everything
extern (C) ubyte vgm_load_file(const(char)* path);         //loads the file at the given path to RAM and sets up playback; ready for vgm_render after call
extern (C) int   vgm_render(int smplCnt, WAVE_32BS* data); //renders
extern (C) ubyte vgm_set_sample_rate(int sampleRate);      //sets the sample rate of the rendered samples
extern (C) ubyte vgm_seek(byte unit, int pos);             //seeks within the loaded vgm file
```

You can use it like:

```cpp
WAVE_32BS* buffer = (WAVE_32BS*) linearAlloc(NUM_SAMPLES * sizeof(WAVE_32BS));

vgm_init_player();  //you can use return value to check if failed - other functions return non-zero on failure as well
vgm_set_sample_rate(44100);
vgm_load_file("romfs:/your_file.vgz");

int samplesRendered = vgm_render(NUM_SAMPLES, buffer);
//do something with buffer

//when done...
vgm_deinit_player();
```

Some notes:

* [`Makefile.3ds`](Makefile.3ds) and [`SoundEmu.c`](emu/SoundEmu.c) have been modified to only enable the VSU (Virtual Boy) core for my own purposes. One could easily reenable everything else by modifying those two files.
* To try to remove the dependency on iconv, the code that reads tags from the given file is dummied out.