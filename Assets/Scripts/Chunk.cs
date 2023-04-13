using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Chunk : MonoBehaviour
{
    private int radius;
    private int subdivisions;
    private List<Vector3> vertices = new List<Vector3>();
    private List<int> triangles = new List<int>();
    private List<Vector2> uvs = new List<Vector2>();
    private List<Vector3> normals = new List<Vector3>();
    private bool show = false;

    public void Initialise(Vector3 firstPos, Vector3 secondPos, Vector3 thirdPos, int radius, int subdivisions)
    {
        this.radius = radius;
        this.subdivisions = subdivisions;

        vertices.Add(firstPos);
        vertices.Add(secondPos);
        vertices.Add(thirdPos);
        triangles.Add(0);
        triangles.Add(1);
        triangles.Add(2);
    }

    private void OnDrawGizmos() {
        if (show) {
            Gizmos.color = Color.yellow;
            Gizmos.DrawLine(vertices[0], vertices[0] + normals[0]);
            Gizmos.color = Color.red;
            Gizmos.DrawLine(vertices[0] + normals[0], vertices[0] + normals[0] + Vector3.up);
            /*for (int j = 0; j < vertices.Count; ++j) {
                Gizmos.color = Color.yellow;
                Gizmos.DrawLine(vertices[j], vertices[j] + normals[j]);
            }*/
        }
    }

    public void Render()
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();

        for (int i = 0; i < subdivisions; ++i) {
            Subdivide();
        }

        show = true;

        for (int j = 0; j < vertices.Count; ++j) {
            normals.Add(vertices[j].normalized);
            vertices[j] = vertices[j].normalized; 
        }

        Mesh mesh = new Mesh();
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetUVs(0, uvs.ToArray());
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.sharedMesh = mesh;
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
