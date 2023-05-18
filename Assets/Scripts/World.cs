using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class World : MonoBehaviour
{
    public SphereType sphereType;
    public int subdivisions;
    public Transform chunkPrefab;
    public Material[] materials;

    private List<Chunk> chunks = new List<Chunk>();
    private Fibonacci fSphere;
    private Radial uSphere;

    private void Start()
    {
        switch(sphereType) {
            case SphereType.Icosahedron:
                CreateIcosahedronWorld();
                break;
            case SphereType.Cube:
                CreateCubeWorld();
                break;
            case SphereType.Fibonacci:
                CreateFibonacciWorld();
                break;
            case SphereType.UV:
                CreateUVWorld();
                break;
            case SphereType.Plane:
                CreatePlaneWorld();
                break;
            default:
                break;
        }
    }

    private void CreateIcosahedronWorld()
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
            chunk.Initialise(verts[tris[i * 3]], verts[tris[(i * 3) + 1]], verts[tris[(i * 3) + 2]], subdivisions, materials, true);
            chunk.Render();
            chunks.Add(chunk);
        }
    }

    private void CreateCubeWorld() 
    {
        float a = 0.5f;

        Vector3[] verts = new[]
        {
            new Vector3(-a, -a, -a),
            new Vector3(-a, a, -a),
            new Vector3(a, a, -a),
            new Vector3(a, -a, -a),
            new Vector3(a, -a, a),
            new Vector3(a, a, a),
            new Vector3(-a, a, a),
            new Vector3(-a, -a, a)
        };

        int[] tris = new []
        {
            0, 1, 3,
            3, 1, 2,
            5, 6, 4,
            4, 6, 7,
            6, 1, 7,
            7, 1, 0,
            2, 5, 3,
            3, 5, 4,
            0, 3, 7,
            7, 3, 4,
            6, 5, 1,
            1, 5, 2
        };

        for (int i = 0; i < tris.Length / 3; ++i) 
        {
            Transform newChunk = Instantiate(chunkPrefab, transform.position, Quaternion.identity, transform);
            newChunk.name = "(" + i + ")";
            Chunk chunk = newChunk.GetComponent<Chunk>();
            chunk.Initialise(verts[tris[i * 3]], verts[tris[(i * 3) + 1]], verts[tris[(i * 3) + 2]], subdivisions, materials, true);
            chunk.Render();
            chunks.Add(chunk);
        }
    }

    private void CreateFibonacciWorld()
    {
        Transform world = Instantiate(chunkPrefab, transform.position, Quaternion.identity, transform);
        world.name = "(" + 0 + ")";
        Fibonacci fibonacci = world.GetComponent<Fibonacci>();
        fibonacci.Initialise(subdivisions, materials);
        fibonacci.Render();
        fSphere = fibonacci;
    }

    private void CreateUVWorld()
    {
        Transform world = Instantiate(chunkPrefab, transform.position, Quaternion.identity, transform);
        world.name = "(" + 0 + ")";
        Radial radial = world.GetComponent<Radial>();
        radial.Initialise(subdivisions, subdivisions, materials);
        radial.Render();
        uSphere = radial;
    }

    private void CreatePlaneWorld()
    {
        float a = 1f;

        Vector3[] verts = new[]
        {
            new Vector3(-a, 0, -a),
            new Vector3(0, 0, -a),
            new Vector3(a, 0, -a),
            new Vector3(-a, 0, 0),
            new Vector3(0, 0, 0),
            new Vector3(a, 0, 0),
            new Vector3(-a, 0, a),
            new Vector3(0, 0, a),
            new Vector3(a, 0, a),
        };

        int[] tris = new []
        {
            0, 3, 1,
            1, 3, 4,
            1, 4, 2,
            2, 4, 5,
            3, 6, 4,
            4, 6, 7,
            4, 7, 5,
            5, 7, 8
        };

        for (int i = 0; i < tris.Length / 3; ++i) 
        {
            Transform newChunk = Instantiate(chunkPrefab, transform.position, Quaternion.identity, transform);
            newChunk.name = "(" + i + ")";
            Chunk chunk = newChunk.GetComponent<Chunk>();
            chunk.Initialise(verts[tris[i * 3]], verts[tris[(i * 3) + 1]], verts[tris[(i * 3) + 2]], subdivisions, materials, false);
            chunk.Render();
            chunks.Add(chunk);
        }
    }
}

[Serializable]
public enum SphereType
{
    None,
    Icosahedron,
    Cube,
    Fibonacci,
    UV,
    Plane
}