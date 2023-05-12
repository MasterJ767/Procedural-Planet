using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Fibonnacci : MonoBehaviour
{
    private int points;

    private List<Vector3> vertices = new List<Vector3>();
    private List<int> triangles = new List<int>();
    private List<Vector3> normals = new List<Vector3>();

    public void Initialise(int points, Material[] materials)
    {
        this.points = points;
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

    public void Triangulate()
    {
        
    }
}

public class Edge
{
    public Vector3 v1;
    public Vector3 v2;

    public Edge(Vector3 v1, Vector3 v2) 
    {
        this.v1 = v1;
        this.v2 = v2;
    }

    public virtual bool Equals(Edge? e) 
    {
        return (this.v1.Equals(e.v1) && this.v2.Equals(e.v2)) || 
                (this.v1.Equals(e.v2) && this.v2.Equals(e.v1));
    }
}

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
        float dz = this.circumCirc.c.z - v.z;

        return Mathf.Sqrt(dx * dx + dy * dy + dz * dz) <= this.circumCirc.r;
    }
}

public struct CircumCircle
{
    public Vector3 c;
    public float r;
}