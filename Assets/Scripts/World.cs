using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class World : MonoBehaviour
{
    public NoiseSettings noiseSettings;
    public Transform chunkPrefab;

    private List<Chunk> chunks = new List<Chunk>();

    private void Start()
    {
        CreateWorld();
    }

    private void CreateWorld()
    {
        for (int x = 0; x < Config.WorldWidthInChunks; x++)
        {
            for (int z = 0; z < Config.WorldWidthInChunks; z++)
            {
                Vector3 chunkPosition = new Vector3(x * (Config.ChunkWidth * Config.Scale), 0, z * (Config.ChunkWidth * Config.Scale));
                Transform newChunk = Instantiate(chunkPrefab, chunkPosition, Quaternion.identity, transform);
                newChunk.name = "(" + x + ", " + z + ")";
                Chunk chunk = newChunk.GetComponent<Chunk>();
                chunk.Initialise(noiseSettings);
                chunk.Render();
                chunks.Add(chunk);
            }
        }
    }
}

[Serializable]
public struct NoiseSettings
{
    public NoiseLayer[] layers;
}

[Serializable]
public struct NoiseLayer 
{
    public float scale;
    [Range(1, 8)]
    public int octaves;
    [Range(0f, 1f)]
    public float persistence;
    public float lacunarity;
}
