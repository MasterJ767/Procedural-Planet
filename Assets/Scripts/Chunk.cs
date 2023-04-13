using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Chunk : MonoBehaviour
{
    private int radius;
    private int subdivisions;
    private Textures textures;
    private List<Vector3> vertices = new List<Vector3>();
    private List<int> triangles = new List<int>();
    private List<Vector2> uvs = new List<Vector2>();

    public void Initialise(Vector3 firstPos, Vector3 secondPos, Vector3 thirdPos, int radius, int subdivisions, Textures textures)
    {
        this.radius = radius;
        this.subdivisions = subdivisions;
        this.textures = textures;
        SetMaterialTextures();

        vertices.Add(firstPos);
        vertices.Add(secondPos);
        vertices.Add(thirdPos);
        triangles.Add(0);
        triangles.Add(1);
        triangles.Add(2);
    }

    public void SetMaterialTextures() {
        Texture2DArray textureArray = new Texture2DArray(textures.diffuseTextures[0].width,
            textures.diffuseTextures[0].height, textures.diffuseTextures.Length, textures.diffuseTextures[0].format, false);
        for (int i = 0; i < textures.diffuseTextures.Length; i++)
        {
            textureArray.SetPixels(textures.diffuseTextures[i].GetPixels(), i);
        }
        textureArray.Apply();
        GetComponent<MeshRenderer>().material.SetTexture("_DiffuseTextures", textureArray);

        Texture2DArray normalArray = new Texture2DArray(textures.normalTextures[0].width,
            textures.normalTextures[0].height, textures.normalTextures.Length, textures.normalTextures[0].format, false);
        for (int i = 0; i < textures.normalTextures.Length; i++)
        {
            normalArray.SetPixels(textures.normalTextures[i].GetPixels(), i);
        }
        normalArray.Apply();
        GetComponent<MeshRenderer>().material.SetTexture("_NormalTextures", normalArray);
    }

    public void Render()
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();

        for (int i = 0; i < subdivisions; ++i) {
            Subdivide();
        }

        for (int j = 0; j < vertices.Count; ++j) {
           vertices[j] = vertices[j].normalized * radius; 
        }

        Mesh mesh = new Mesh();
        mesh.SetVertices(vertices.ToArray());
        mesh.SetTriangles(triangles.ToArray(), 0);
        mesh.SetUVs(0, uvs.ToArray());
        mesh.RecalculateNormals();
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
