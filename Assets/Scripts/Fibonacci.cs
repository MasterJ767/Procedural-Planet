using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Fibonacci : MonoBehaviour
{
    protected int points;

    protected List<Vector3> vertices = new List<Vector3>();
    protected List<int> triangles = new List<int>();
    protected List<Vector3> normals = new List<Vector3>();

    public void Initialise(int points, Material[] materials)
    {
        this.points = points;
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.materials = materials;
    }

    public virtual void Render() 
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();

        Generate();

        Triangulate();

        //List<int> indices = Enumerable.Range(0, vertices.Count - 1).ToList();

        Mesh mesh = new Mesh();
        mesh.subMeshCount = 2;
        mesh.SetVertices(vertices.ToArray());
        //mesh.SetIndices(indices, MeshTopology.Points, 0);
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetTriangles(triangles.ToArray(), 1);
        mesh.SetNormals(normals.ToArray());
        mesh.Optimize();

        meshFilter.mesh = mesh;
    }

    public void Generate() 
    {
        float phi = Mathf.PI * (3f - Mathf.Sqrt(5f));
        for (int i = 0; i < points; ++i) 
        {
            float y = 1 - (i / (points - 1f)) * 2;
            
            float radius = Mathf.Sqrt(1 - Mathf.Pow(y, 2));
            float theta = phi * i;

            float x = Mathf.Cos(theta) * radius;
            float z = Mathf.Sin(theta) * radius;

            vertices.Add(new Vector3(x, y, z));
            normals.Add(new Vector3(x, y, z).normalized);
        }
    }

    public virtual void Triangulate()
    {
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

            triangles.Add(vertices.IndexOf(tri.v1));
            triangles.Add(vertices.IndexOf(tri.v2));
            triangles.Add(vertices.IndexOf(tri.v3));
        }

       ReverseStereographicProjection();
    }

    protected Triangle GetSuperTriangle()
    {
        float minx = Int32.MaxValue;
        float miny = Int32.MaxValue;
        float maxx = -Int32.MaxValue;
        float maxy = -Int32.MaxValue;
        foreach (Vector3 vertex in vertices) 
        {
            minx = Mathf.Min(minx, vertex.x);
		    miny = Mathf.Min(minx, vertex.y);
		    maxx = Mathf.Max(maxx, vertex.x);
		    maxy = Mathf.Max(maxx, vertex.y);
        }

        float dx = (maxx - minx) * 0.1f;
		float dy = (maxy - miny) * 0.1f;

        Vector3 v1 = new Vector3(minx - dx, miny - dy * 3);
		Vector3 v2 = new Vector3(minx - dx, maxy + dy);
		Vector3 v3 = new Vector3(maxx + dx * 3, maxy + dy);

	    return new Triangle(v1, v2, v3);
    }

    protected List<Triangle> AddVertex(Vector3 vert, List<Triangle> tris)
    {
        List<Edge> edges = new List<Edge>();
        List<Triangle> triKeep = new List<Triangle>();

        foreach (Triangle tri in tris)
        {
            if (tri.inCircumCircle(vert)) {
                edges.Add(new Edge(tri.v1, tri.v2));
                edges.Add(new Edge(tri.v2, tri.v3));
                edges.Add(new Edge(tri.v3, tri.v1));
            }
            else 
            {
                triKeep.Add(tri);
            }
        }

        edges = GetUniqueEdges(edges);
        foreach (Edge edge in edges)
        {
            Triangle newTri = new Triangle(edge.v1, edge.v2, vert);
            if (!triKeep.Contains(newTri)) { triKeep.Add(newTri); }
        }

        return triKeep;
    }

    private List<Edge> GetUniqueEdges(List<Edge> edges)
    {
        List<Edge> result = new List<Edge>();
        for (int i = 0; i < edges.Count; ++i) 
        {
            bool isUnique = true;
            for (int j = 0; j < edges.Count; ++j) 
            {
                if (i != j && edges[i].Equals(edges[j])) 
                {
                    isUnique = false;
                    break;
                }
            }

            if (isUnique)
            { 
                result.Add(edges[i]); 
            }
        }
        return result;
    }

    protected void StereographicProjection() 
    {
        List<Vector3> newVerts = new List<Vector3>();

        for (int i = 0; i < vertices.Count; ++i)
        {
            float x = (2 * vertices[i].x) / (1 - vertices[i].z);
            float y = (2 * vertices[i].y) / (1 - vertices[i].z);

            newVerts.Add(new Vector3(x, y, 0));
        }

        vertices = newVerts;
    }

    protected void ReverseStereographicProjection() 
    {
        List<Vector3> newVerts = new List<Vector3>();

        for (int i = 0; i < vertices.Count; ++i)
        {
            float x = (2 * vertices[i].x) / (vertices[i].x * vertices[i].x + vertices[i].y * vertices[i].y + 1);
            float y = (2 * vertices[i].y) / (vertices[i].x * vertices[i].x + vertices[i].y * vertices[i].y + 1);
            float z = (vertices[i].x * vertices[i].x + vertices[i].y * vertices[i].y - 1) / (vertices[i].x * vertices[i].x + vertices[i].y * vertices[i].y + 1);

            newVerts.Add(new Vector3(x, y, z));
        }

        vertices = newVerts;
    }

    protected float GetWinding(Vector3 a, Vector3 b, Vector3 c) {
        return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
    }
}

[Serializable]
public class Edge
{
    public Vector3 v1;
    public Vector3 v2;

    public Edge(Vector3 v1, Vector3 v2) 
    {
        this.v1 = v1;
        this.v2 = v2;
    }

    public virtual bool Equals(Edge e) 
    {
        return (this.v1.Equals(e.v1) && this.v2.Equals(e.v2)) || 
                (this.v1.Equals(e.v2) && this.v2.Equals(e.v1));
    }
}

[Serializable]
public class Triangle
{
    public Vector3 v1;
    public Vector3 v2;
    public Vector3 v3;
    public CircumCircle circumCirc;

    public Triangle(Vector3 v1, Vector3 v2, Vector3 v3) 
    {
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;

        this.circumCirc = CalculateCircumcentre();
    }

    public virtual bool Equals(Triangle t)
    {
        return (this.v1.Equals(t.v1) && this.v2.Equals(t.v2) && this.v3.Equals(t.v3)) || 
               (this.v1.Equals(t.v1) && this.v2.Equals(t.v3) && this.v3.Equals(t.v2)) ||
               (this.v1.Equals(t.v3) && this.v2.Equals(t.v2) && this.v3.Equals(t.v1)) ||
               (this.v1.Equals(t.v3) && this.v2.Equals(t.v1) && this.v3.Equals(t.v2)) ||
               (this.v1.Equals(t.v2) && this.v2.Equals(t.v1) && this.v3.Equals(t.v3)) ||
               (this.v1.Equals(t.v2) && this.v2.Equals(t.v3) && this.v3.Equals(t.v1));
    }

    private CircumCircle CalculateCircumcentre() 
    {
        Vector3 ab = v2 - v1;
        Vector3 ac = v3 - v1;
        Vector3 abXac = Vector3.Cross(ab, ac);

        Vector3 toCircumcentre = (Vector3.Cross(abXac, ab) * (ac.magnitude * ac.magnitude) + Vector3.Cross(ac, abXac) * (ab.magnitude * ab.magnitude)) / (2f * (abXac.magnitude * abXac.magnitude));
        return new CircumCircle{ c = v1 + toCircumcentre, r = toCircumcentre.magnitude};
    }

    public bool inCircumCircle(Vector3 v) 
    {
        float dx = this.circumCirc.c.x - v.x;
        float dy = this.circumCirc.c.y - v.y;

        return dx * dx + dy * dy <= this.circumCirc.r * this.circumCirc.r;
    }
}

[Serializable]
public struct CircumCircle
{
    public Vector3 c;
    public float r;
}