# EXPERIMENTAL FORK FOR THE NINTENDO SWITCH

For generate the lib, you need to run the following command:

```bash
haxelib run lime rebuild switch
```

![](./switchExamples/switchlimelibcapture.png)

## Examples

Capture an OpenFL project from a real Nintendo Switch:

![](./switchExamples/switchOpenFLImage.png)


OpenFL Samples -> HelloTriangle:

![](./switchExamples/OpenFLHelloTriangle.png)

HaxeFlixel 6.1.2 running [Mode](https://haxeflixel.com/demos/Mode) on the Nintendo Switch:

<video controls src="./switchExamples/HaxeFixel_MODE_Game_test.mp4" title="Title"></video>

This fork is based on the commit ``68107ee`` (From  Sep 18, 2025) of the original [Lime](https://github.com/openfl/lime)

## How to use

You need to install [Haxe](https://haxe.org/download) and [DevKitPro stuff](https://devkitpro.org/wiki/Getting_Started)

Once you have Haxe and DevKitPro with DevKitA64 installed, install the dependencies:

(If you are on Linux/macOS, you will most likely need to use `sudo dkp-pacman` instead of `pacman`)

```bash
pacman -S --needed 
switch-bzip2 
switch-cmake 
switch-curl 
switch-flac 
switch-freetype 
switch-glad 
switch-glm 
switch-harfbuzz 
switch-libdrm_nouveau 
switch-libjpeg-turbo 
switch-libmodplug 
switch-libogg 
switch-libopus 
switch-libpng 
switch-libvorbis 
switch-libvorbisidec 
switch-libwebp 
switch-mesa 
switch-mpg123 
switch-openal-soft 
switch-opusfile 
switch-pkg-config 
switch-sdl2 
switch-sdl2_gfx 
switch-sdl2_image 
switch-sdl2_mixer 
switch-sdl2_net 
switch-sdl2_ttf 
switch-tools 
switch-zlib
```

Then just install this fork with:

```bash
haxelib git lime https://github.com/Slushi-Github/lime-nx.git
```

install the dependencies for Lime:

```bash
haxelib install format
haxelib install hxp
```

And and generate your Lime library:

```bash
haxelib run lime rebuild switch
```

For now, you must put this in your `project.xml`, otherwise your program will crash when you open it:

```xml
<haxedef name="lime-opengl" if="switch" />
<haxedef name="lime-cairo" value="false" if="switch" />
<set name="LIME_CAIRO" value="0" if="switch" />
<set name="LIME_OPENGL" value="1" if="switch" />
```

and it is also advisable to include this:

```xml
<!--Switch-specific-->
<window if="switch" orientation="landscape" fullscreen="true" width="0" height="0" resizable="false" hardware="true" />
```

And now you can compile your project!:

```bash
haxelib run lime build switch
```

----

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/openfl/lime.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/lime) [![Build Status](https://img.shields.io/github/actions/workflow/status/openfl/lime/main.yml?branch=develop)](https://github.com/openfl/lime/actions) [![Community](https://img.shields.io/discourse/posts?color=24afc4&server=https%3A%2F%2Fcommunity.openfl.org&label=community)](https://community.openfl.org/c/lime/19) [![Discord Server](https://img.shields.io/discord/415681294446493696.svg?color=7289da)](https://discordapp.com/invite/tDgq8EE)

Lime
====

Lime is a flexible, lightweight layer for Haxe cross-platform developers.

Lime supports native, Flash and HTML5 targets with unified support for:

 * Windowing
 * Input
 * Events
 * Audio
 * Render contexts
 * Network access
 * Assets

Lime does not include a renderer, but exposes the current context:

 * Cairo
 * Canvas
 * DOM
 * Flash
 * GL

The GL context is based upon the WebGL standard, implemented for both OpenGL and OpenGL ES as needed.

Lime provides a unified audio API, but also provides access to OpenAL for advanced audio on native targets.


License
=======

Lime is free, open-source software under the [MIT license](LICENSE.md).


Installation
============

First, install the latest version of [Haxe](http://www.haxe.org/download).

Then, install Lime from Haxelib and run Lime's setup command.

    haxelib install lime
    haxelib run lime setup


Development Builds
==================

When there are changes, Lime is built nightly. Builds are available for download [here](https://github.com/Slushi-Github/lime-nx/actions?query=branch%3Adevelop+is%3Asuccess).

To install a development build, use the "haxelib local" command:

    haxelib local lime-haxelib.zip


Building from Source
====================

**DO NOT FOLLOW THIS, USE THE ABOVE INSTEAD**

1. Clone the Lime repository, as well as the submodules:

        haxelib git lime https://github.com/https://github.com/Slushi-Github/lime-nx/

2. Install required dependencies:

        haxelib install format
        haxelib install hxp

3. Copy the ndll directory from the latest [Haxelib release](https://lib.haxe.org/p/lime/), or see [project/README.md](project/README.md) for details about building native binaries.

4. After any changes to the [tools](tools) or [lime/tools](src/lime/tools) directories, rebuild from source:

        lime rebuild tools

5. To switch away from a source build:

        haxelib set lime [version number]


Sample
======

You can build a sample Lime project with the following commands:

    lime create HelloWorld
    cd HelloWorld
    lime test neko

You can also list other projects that are available using "lime create".


Targets
=======

Lime currently supports the following targets:

    lime test windows
    lime test mac
    lime test linux
    lime test android
    lime test ios
    lime test html5
    lime test flash
    lime test air
    lime test neko
    lime test hl
    lime test switch

Desktop builds are currently designed to be built on the same host OS


Join the Community
==================

Have a question? Want a new place to hang out?

 * [Forums](https://community.openfl.org/c/lime/19)
 * [Discord](https://discordapp.com/invite/tDgq8EE)