# GENESIS

Genesis is a Lua / LÖVE2D based world generator. My goals with Genesis are:

* To have a library that can be easily integrated into games
* To be able to generate interesting random patterns
* Worlds should be seedable: the same seed value should generate the same world
* Worlds should be easily usable with cubemaps
* Worlds should have biomes, rivers, seas, lakes, mountains
* Allow some configuration of the generator, e.g. detail level

# FURTHER READING

The Genesis source code is based on a variety of ideas and posts found on the 
internet. For reference I've added the most important links here.

* [Procedurally Generating Wrapping World Maps in Unity C#][0]
* [Wraparound square tile maps on a sphere][1]
* [Creating tileable noise maps][2]
* [Making maps with noise functions][3]
* [Fractal Brownian Motion][4]

[0]: http://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-1
[1]: https://www.redblobgames.com/x/1938-square-tiling-of-sphere/
[2]: https://ronvalstar.nl/creating-tileable-noise-maps
[3]: https://www.redblobgames.com/maps/terrain-from-noise/
[4]: https://thebookofshaders.com/13/
