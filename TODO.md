# Rivers

Following this guide, but adjusting for our implementation: https://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-3/#rivers

I think we should probably have to tables:

- rivers:
	{
		id: ..,
		origin: { face, x, y },
		tiles: { tile_ids or hash },
	}
- tileRiverInfo:
	{ 
		tile_id: 
		{ 
			river.id, ...

		} 
	}

These tables can then be used in the FindPathToWater function, as an alternative of storing this info in tile or river objects.
We might mark a tile as having a river in a flag.
