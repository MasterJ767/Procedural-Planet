using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Config : MonoBehaviour
{
    public static readonly float Scale = 0.5f; 
    public static readonly int ChunkWidth = 40;
    public static readonly int ChunkHeight = 128;
    public static readonly int WorldWidthInChunks = 10;
    public static int WorldWidthInVertices = (ChunkWidth * WorldWidthInChunks) + 1;
    public static int SeaLevel => ChunkHeight / 6;
}
