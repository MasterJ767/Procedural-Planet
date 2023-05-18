using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Radial : MonoBehaviour
{
    private int parallels;
    private int meridians;
    
    private List<Vector3> vertices = new List<Vector3>();
    private List<int> triangles = new List<int>();
    private List<Vector3> normals = new List<Vector3>();

    public void Initialise(int parallels, int meridians, Material[] materials)
    {
        this.parallels = parallels;
        this.meridians = meridians;
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.materials = materials;
    }

    public void Render()
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();

        Generate();

        Triangulate();

        Mesh mesh = new Mesh();
        mesh.subMeshCount = 2;
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetTriangles(triangles.ToArray(), 1);
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.mesh = mesh;
    }

    private void Generate() 
    {
        vertices.Add(new Vector3(0, 1, 0));
        normals.Add(new Vector3(0, 1, 0).normalized);

        for (int p = 0; p < parallels - 1; ++p) 
        {
            float parallel = Mathf.PI * (p + 1) / parallels;
            for (int m = 0; m < meridians; ++m)
            {
                float meridian = 2 * Mathf.PI * m / meridians;
                float x = Mathf.Sin(parallel) * Mathf.Cos(meridian);
                float y = Mathf.Cos(parallel);
                float z = Mathf.Sin(parallel) * Mathf.Sin(meridian);

                vertices.Add(new Vector3(x, y, z));
                normals.Add(new Vector3(x, y, z).normalized);
            }
        }

        vertices.Add(new Vector3(0, -1, 0));
        normals.Add(new Vector3(0, -1, 0).normalized);
    }

    private void Triangulate()
    {
        for (int i = 0; i < meridians; ++i)
        {
            int i0 = i + 1;
            int i1 = (i + 1) % meridians + 1;
            triangles.Add(0);
            triangles.Add(i1);
            triangles.Add(i0);
            i0 = i + meridians * (parallels - 2) + 1;
            i1 = (i + 1) % meridians + meridians * (parallels - 2) + 1;
            triangles.Add(vertices.Count - 1);
            triangles.Add(i0);
            triangles.Add(i1);
        }

        for (int j = 0; j < parallels - 2; ++j)
        {
            int j0 = j * meridians + 1;
            int j1 = (j + 1) * meridians + 1;
            for (int i = 0; i < meridians; i++)
            {
                int i0 = j0 + i;
                int i1 = j0 + (i + 1) % meridians;
                int i2 = j1 + (i + 1) % meridians;
                int i3 = j1 + i;
                triangles.Add(i3);
                triangles.Add(i0);
                triangles.Add(i2);
                triangles.Add(i2);
                triangles.Add(i0);
                triangles.Add(i1);
            }
        }
    }
}
