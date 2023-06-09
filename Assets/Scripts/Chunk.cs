using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Chunk : MonoBehaviour
{
    private int subdivisions;
    private bool spherise;
    private List<Vector3> vertices = new List<Vector3>();
    private List<int> triangles = new List<int>();
    private List<Vector3> normals = new List<Vector3>();

    public void Initialise(Vector3 firstPos, Vector3 secondPos, Vector3 thirdPos, int subdivisions, Material[] materials, bool spherise)
    {
        this.subdivisions = subdivisions;
        this.spherise = spherise;
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.materials = materials;

        vertices.Add(firstPos);
        vertices.Add(secondPos);
        vertices.Add(thirdPos);
        triangles.Add(0);
        triangles.Add(1);
        triangles.Add(2);
    }

    public void Render()
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();

        for (int i = 0; i < subdivisions; ++i) {
            Subdivide();
        }

        for (int j = 0; j < vertices.Count; ++j) {
            if (spherise) {
                normals.Add(vertices[j].normalized);
                vertices[j] = vertices[j].normalized; 
            }
            else 
            {
                normals.Add(Vector3.up);
            }
        }

        Mesh mesh = new Mesh();
        mesh.subMeshCount = 2;
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetTriangles(triangles.ToArray(), 1);
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.mesh = mesh;
    }

    public void Subdivide() {
        List<int> newTriangles = new List<int>();
        int currentIndex = vertices.Count;

        for (int i = 0; i < triangles.Count / 3; ++i) {
            Vector3 m1 = Vector3.Lerp(vertices[triangles[i * 3]], vertices[triangles[(i * 3) + 1]], 0.5f);
            Vector3 m2 = Vector3.Lerp(vertices[triangles[(i * 3) + 1]], vertices[triangles[(i * 3) + 2]], 0.5f);
            Vector3 m3 = Vector3.Lerp(vertices[triangles[(i * 3) + 2]], vertices[triangles[i * 3]], 0.5f);

            vertices.Add(m1);
            vertices.Add(m2);
            vertices.Add(m3);

            newTriangles.Add(triangles[i * 3]);
            newTriangles.Add(currentIndex);
            newTriangles.Add(currentIndex + 2);
            newTriangles.Add(triangles[(i * 3) + 1]);
            newTriangles.Add(currentIndex + 1);
            newTriangles.Add(currentIndex);
            newTriangles.Add(triangles[(i * 3) + 2]);
            newTriangles.Add(currentIndex + 2);
            newTriangles.Add(currentIndex + 1);
            newTriangles.Add(currentIndex);
            newTriangles.Add(currentIndex + 1);
            newTriangles.Add(currentIndex + 2);

            currentIndex += 3;
        }

        triangles = newTriangles;
    }
}
