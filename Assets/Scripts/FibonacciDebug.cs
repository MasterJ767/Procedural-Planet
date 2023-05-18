using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class FibonacciDebug : Fibonacci
{
    private int index = 0;
    private int[] increments;
    private int increment = 3;
    private float timer = 1.25f;

    private void Start()
    {
        increments = new int[]{3, 48, 58, 59, points};
        //59, 62, 67
    }

    private void Update() 
    {
        timer -= Time.deltaTime;
        if (timer <= 0 && increment <= points) {
            index++;
            if (index >= increments.Length) { index = increments.Length - 1; }
            increment = increments[index];
            Debug.Log(increment);
            Render();
            timer = 1.25f;
        }
    }

    public override void Render() 
    {
        vertices.Clear();
        triangles.Clear();
        normals.Clear();

        MeshFilter meshFilter = GetComponent<MeshFilter>();

        Generate();

        Triangulate();

        //List<int> indices = Enumerable.Range(0, vertices.Count - 1).ToList();

        Mesh mesh = new Mesh();
        mesh.subMeshCount = 1;
        mesh.SetVertices(vertices.ToArray());
        //mesh.SetIndices(indices, MeshTopology.Points, 0);
        mesh.SetTriangles(triangles.ToArray(), 0);
        //mesh.SetTriangles(triangles.ToArray(), 1);
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.mesh = mesh;
    }

    protected override void Triangulate()
    {
        int value = Mathf.Min(increment, vertices.Count);
        vertices = vertices.Take(increment).ToList();
        normals = normals.Take(increment).ToList();

        StereographicProjection();

        Triangle superTri = GetSuperTriangle();
        List<Triangle> tris = new List<Triangle>();
        tris.Add(superTri);

        foreach (Vector3 vertex in vertices)
        {
            tris = AddVertex(vertex, tris);
        }
        
        foreach(Triangle tri in tris)
        {
            if (tri.v1 == superTri.v1 || tri.v1 == superTri.v2 || tri.v1 == superTri.v3 ||
                tri.v2 == superTri.v1 || tri.v2 == superTri.v2 || tri.v2 == superTri.v3 ||
                tri.v3 == superTri.v1 || tri.v3 == superTri.v2 || tri.v3 == superTri.v3) 
            {
                continue;
            }

            /*if (GetWinding(tri.v1, tri.v2, tri.v3) > 0)
            {
                triangles.Add(vertices.IndexOf(tri.v1));
                triangles.Add(vertices.IndexOf(tri.v3));
                triangles.Add(vertices.IndexOf(tri.v2));
            }
            else
            {
                triangles.Add(vertices.IndexOf(tri.v1));
                triangles.Add(vertices.IndexOf(tri.v2));
                triangles.Add(vertices.IndexOf(tri.v3));
            }*/
            triangles.Add(vertices.IndexOf(tri.v1));
            triangles.Add(vertices.IndexOf(tri.v2));
            triangles.Add(vertices.IndexOf(tri.v3));
        }

       ReverseStereographicProjection();
    }
}
