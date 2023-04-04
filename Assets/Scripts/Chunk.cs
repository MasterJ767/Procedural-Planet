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
        int vertexIndex = 0;

        for (int x = 0; x < Config.ChunkWidth; ++x)
        {
            for (int z = 0; z < Config.ChunkWidth; ++z)
            {
                vertices.Add(new Vector3(x * Config.Scale, 0, z * Config.Scale));
                normals.Add(Vector3.up);
                
                if (x < Config.ChunkWidth - 1 && z < Config.ChunkWidth - 1) 
                {
                    triangles.Add(vertexIndex);
                    triangles.Add(vertexIndex + 1);
                    triangles.Add(vertexIndex + Config.ChunkWidth);
                    triangles.Add(vertexIndex + Config.ChunkWidth);
                    triangles.Add(vertexIndex + 1);
                    triangles.Add(vertexIndex + Config.ChunkWidth + 1);
                }

                vertexIndex++;
            }
        }

        Mesh mesh = new Mesh();
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.sharedMesh = mesh;
    }
}
