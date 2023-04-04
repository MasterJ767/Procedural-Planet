using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Config : MonoBehaviour
{
    public static readonly float Scale = 0.5f; 
    public static readonly int ChunkWidth = 21;
    public static readonly int ChunkHeight = 256;
    public static readonly int WorldWidthInChunks = 5;

    public static int MinimunTerrainHeight => ChunkHeight / 6;
    public static int SeaLevel => ChunkHeight / 4;
}
