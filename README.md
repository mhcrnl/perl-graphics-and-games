perl-graphics-and-games
=======================

A hobby project that I've played with on and off for a while. At the centre of it is a 3D engine built entirely in software (perl/tk) by me without using any 3rd party 3D libraries mostly for a laugh to see what was possible (perl isn't the best for graphics, it's a bit slow)

Notes
------

This was developed with ActivePerl 5.10.1 build 1007, I haven't gone higher than that as I have been using Image-Magick for background resizing in roidstest.pl. The version I had was compiled for the above build.

Other than Image-Magick you will also need to install the Perl/Tk module if it hasn't been already

The roids game was developed on windows and uses some Win32 modules e.g. For sound, by all means develop yourself a linux version :)

The 3D library has a polygon mode and pixel mode, Tk doesn't draw very fast so pixel mode is very slow so you can't really use it for anything dynamic. I did port it to a Java version that does work quite well (not in this repository).


3D Library
----------
Is in the perllib folder. The required files here are:
CanvasObject.pm - The super class for all 3D objects
GamesLib.pm - Some common functions
LineEq.pm - Object for handling line equations
ThreeDCubesTest.pm - The main library, does the drawing,camera handling etc. (n.b. this should probably be renamed as it does more than cubes now - which is where it started)

The other pm files here define some 3D objects, some others are defined elsewhere such as Bullet.pm and Gate.pm in the gates game


Games
-------
minesweeper.pl
nxs/noughtsAndCrosses.pl
artillery/artillery.pl - 2D game, can be played over IP
gates/gatetestTest.pl - Fully 3D flying demo
roids/roidstest.pl - Mostly a 2D Asteroids homage that does use some 3D elements

Other
------
The chat folder contains a simple chat program
The various spheretest*.pl torustest*.pl are various tests of pixel drawing, bouncing balls etc. spheretest2.pl also contains an attempt at ray tracing for drawing shadows - though that implementation is not a general purpose function that can be added to the 3D library