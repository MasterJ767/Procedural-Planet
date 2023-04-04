using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Chunk : MonoBehaviour
{
    public void Render()
    {
        MeshFilter meshFilter = gameObject.GetComponent<MeshFilter>();
        MeshRenderer meshRenderer = gameObject.GetComponent<MeshRenderer>();

        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();
        List<int> triangles = new List<int>();

        for (int x = 0; x < Config.ChunkWidth + 1; ++x)
        {
            for (int z = 0; z < Config.ChunkWidth + 1; ++z)
            {
                vertices.Add(new Vector3(x * Config.Scale, 0, z * Config.Scale));
                normals.Add(Vector3.up);
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
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.sharedMesh = mesh;
    }
}
