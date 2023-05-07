using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class World : MonoBehaviour
{
    public int subdivisions;
    public Transform chunkPrefab;
    public Material[] materials;

    private List<Chunk> chunks = new List<Chunk>();

    private void Start()
    {
        CreateWorld();
    }

    private void CreateWorld()
    {
        float phi = (1f + Mathf.Sqrt(5f)) * 0.5f;
        float a = 1f;
        float b = 1f / phi;

        Vector3[] verts = new[]
        {
            new Vector3(0, b, -a),
            new Vector3(b, a, 0),
            new Vector3(-b, a, 0),
            new Vector3(0, b, a),
            new Vector3(0, -b, a),
            new Vector3(-a, 0, b),
            new Vector3(0, -b, -a),
            new Vector3(a, 0, -b),
            new Vector3(a, 0, b),
            new Vector3(-a, 0, -b),
            new Vector3(b, -a, 0),
            new Vector3(-b, -a, 0)
        };

        int[] tris = new []
        {
            2, 1, 0,
            1, 2, 3,
            5, 4, 3,
            4, 8, 3,
            7, 6, 0,
            6, 9, 0,
            11, 10, 4,
            10, 11, 6,
            9, 5, 2,
            5, 9, 11,
            8, 7, 1,
            7, 8, 10,
            2, 5, 3,
            8, 1, 3,
            9, 2, 0,
            1, 7, 0,
            11, 9, 6,
            7, 10, 6,
            5, 11, 4,
            10, 8, 4
        };

        for (int i = 0; i < tris.Length / 3; ++i)
        {
            Transform newChunk = Instantiate(chunkPrefab, transform.position, Quaternion.identity, transform);
            newChunk.name = "(" + i + ")";
            Chunk chunk = newChunk.GetComponent<Chunk>();
            chunk.Initialise(verts[tris[i * 3]], verts[tris[(i * 3) + 1]], verts[tris[(i * 3) + 2]], subdivisions, materials);
            chunk.Render();
            chunks.Add(chunk);
        }
    }
}
