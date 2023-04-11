using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Chunk : MonoBehaviour
{
    private NoiseSettings noiseSettings;

    public void Initialise(NoiseSettings noiseSettings)
    {
        this.noiseSettings = noiseSettings;
    }

    public void Render()
    {
        MeshFilter meshFilter = gameObject.GetComponent<MeshFilter>();
        MeshRenderer meshRenderer = gameObject.GetComponent<MeshRenderer>();

        List<Vector3> vertices = new List<Vector3>();
        List<int> triangles = new List<int>();

        for (int x = 0; x < Config.ChunkWidth + 1; ++x)
        {
            for (int z = 0; z < Config.ChunkWidth + 1; ++z)
            {
                Vector3 localVertexPosition = new Vector3(x * Config.Scale, 0, z * Config.Scale);
                Vector3 globalVertexPosition = localVertexPosition + transform.position;
                vertices.Add(localVertexPosition);
                
            }
        }

        int rowOffset = Config.ChunkWidth + 1;
        for (int i = 0; i < (Config.ChunkWidth * Config.ChunkWidth); ++i)
        {
            int offset = i / Config.ChunkWidth;
            int j = i + offset;
            triangles.Add(j);
            triangles.Add(j + 1);
            triangles.Add(j + rowOffset);
            triangles.Add(j + rowOffset);
            triangles.Add(j + 1);
            triangles.Add(j + rowOffset + 1);
        }

        Mesh mesh = new Mesh();
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.RecalculateNormals();
        mesh.Optimize();

        meshFilter.sharedMesh = mesh;
    }

    private float EvaluateNoise(float xCoord, float zCoord)
    {
        float x = xCoord / Config.WorldWidthInVertices;
        float z = zCoord / Config.WorldWidthInVertices;

        float vertexModifier = 0;
        for (int i = 0; i < noiseSettings.layers.Length; ++i) {
            float noiseValue = PerlinNoise2D(x * noiseSettings.layers[i].scale, z * noiseSettings.layers[i].scale, i);
            noiseValue = Mathf.Max(0, noiseValue);
            vertexModifier += noiseValue;
            if (noiseValue == 0) { break; }
        }
        vertexModifier /= noiseSettings.layers.Length;
        return Config.ChunkHeight * vertexModifier;
    }

    private float PerlinNoise2D(float x, float z, int i) {
        float total = 0;
        float frequency = 1;
        float amplitude = 1;
        int n = noiseSettings.layers[i].octaves;

        for (int j = 0; i < n; ++j) {
            total += (Mathf.PerlinNoise(x * frequency, z * frequency) * amplitude);
            frequency *= noiseSettings.layers[i].lacunarity;
            amplitude *= noiseSettings.layers[i].persistence;
        }

        return total;
    }
}
