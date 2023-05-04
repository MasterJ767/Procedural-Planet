Shader "Unlit/WorldSphere"
{
    Properties
    {
        [Header(World Generation)]
        _Radius ("Radius", float) = 3.0
        _NoiseScale ("Noise Scale", float) = 3.0
        _NoiseOffset ("Noise Offset", vector) = (1,1,1,0)
        _DisplacementAmplitude ("Displacement Amplitude", float) = 3.0

        [Header(Texturing)]
        _TriplanarSharpness ("Triplanar Blend Sharpness", float) = 1.0
        _TextureTilingOffset ("Texture Tiling and Offset", vector) = (1,1,0,0)
        _TextureRotations ("Texture Rotations", vector) = (16,35,40,0)
        _BlendRegion1 ("Blend Region 1", vector) = (0.67,0.72,0,0)
        _BlendRegion2 ("Blend Region 2", vector) = (0.77,0.82,0,0)
        _BlendRegion3 ("Blend Region 3", vector) = (0.87,0.92,0,0)
        _SandTex ("Sand Texture", 2D) = "white" {}
        _GrassTex ("Grass Texture", 2D) = "white" {}
        _RockTex ("Rock Texture", 2D) = "white" {}
        _IceTex ("Ice Texture", 2D) = "white" {}        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 normal : NORMAL;
                float4 objPos : TEXCOORD0;
            };

            sampler2D _SandTex, _GrassTex, _RockTex, _IceTex;
            float _Radius, _NoiseScale, _DisplacementAmplitude, _TextureScale, _TriplanarSharpness;
            float4 _NoiseOffset, _BlendRegion1, _BlendRegion2, _BlendRegion3, _TextureTilingOffset, _TextureRotations;

            float hash( float n )
			{
			    return frac(sin(n)*43758.5453);
			}

			float noise( float3 x )
			{
			    float3 p = floor(x);
			    float3 f = frac(x);

			    f = f*f*(3.0-2.0*f);
			    float n = p.x + p.y*57.0 + 113.0*p.z;

			    float noise = lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
			                   lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
			               lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
			                   lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
                
                return (noise + 1) / 2;
			}

            float smoothstep( float a, float b, float x )
            {
                float t = clamp((x - a) / (b - a), 0, 1);
                return t * t * (3 - 2 * t);
            }

            float2 rotateUVs( float2 uv, float2 center, float rotation ) 
            {
                uv -= center;
                float s = sin(rotation);
                float c = cos(rotation);
                float2x2 rMat = float2x2(c, -s, s, c);
                rMat *= 0.5;
                rMat += 0.5;
                rMat = rMat * 2 - 1;
                uv = mul(uv, rMat);
                uv += center;
                return uv;
            }

            inline float2 randomVector( float2 uv, float offset )
            {
                float2x2 mat = float2x2(15.27, 47.63, 99.41, 89.98);
                uv = frac(sin(mul(uv, mat)) * 46839.32);
                return float2(sin(uv.y*+offset) * 0.5 + 0.5, cos(uv.x*offset) * 0.5 + 0.5);
            }

            void voronoi( float2 uv, float angleOffset, float cellDensity, out float Cells )
            {
                float2 g = floor(uv * cellDensity);
                float2 f = frac(uv * cellDensity);
                float t = 8.0;
                float3 res = float3(8.0, 0.0, 0.0);

                for(int y=-1; y<=1; y++)
                {
                    for(int x=-1; x<=1; x++)
                    {
                        float2 lattice = float2(x,y);
                        float2 offset = randomVector(lattice + g, angleOffset);
                        float d = distance(lattice + offset, f);
                        if(d < res.x)
                        {
                            res = float3(d, offset.x, offset.y);
                            //Out = res.x;
                            Cells = res.y;
                        }
                    }
                }
            }

            v2f vert (appdata v)
            {
                float noiseValue = noise(v.vertex * _NoiseScale + _NoiseOffset.xyz);
                float4 displacement = v.normal * float4(noiseValue, noiseValue, noiseValue, 1) * _DisplacementAmplitude;
                v2f o;
                o.objPos = v.vertex * _Radius + displacement;
                o.vertex = UnityObjectToClipPos(o.objPos);
                o.normal = normalize(v.normal);
                o.color = float4(noiseValue, 0, 0, 0);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 tiling = float2(_TextureTilingOffset.x, _TextureTilingOffset.y);
                float2 offset1 = float2(_TextureTilingOffset.z, _TextureTilingOffset.w);
                float2 offset2 = offset1 + float2(0.25, 0.25);
                float2 offset3 = offset1 + float2(0.75, 0.75);

                float2 x1 = i.objPos.zy * tiling + offset1;
                float2 y1 = i.objPos.xz * tiling + offset1;
                float2 z1 = i.objPos.xy * tiling + offset1;

                float2 x2 = i.objPos.zy * tiling + offset2;
                float2 y2 = i.objPos.xz * tiling + offset2;
                float2 z2 = i.objPos.xy * tiling + offset2;

                float2 x3 = i.objPos.zy * tiling + offset3;
                float2 y3 = i.objPos.xz * tiling + offset3;
                float2 z3 = i.objPos.xy * tiling + offset3;

                float xRot = 0;
                float yRot = 0;
                float zRot = 0;
                float2 center = float2(0.5, 0.5);

                voronoi(x1, 2, _TextureRotations.x, xRot);
                voronoi(y1, 2, _TextureRotations.x, yRot);
                voronoi(z1, 2, _TextureRotations.x, zRot);
                x1 = rotateUVs(x1, center, xRot);
                y1 = rotateUVs(y1, center, yRot);
                z1 = rotateUVs(z1, center, zRot);

                voronoi(x2, 2, _TextureRotations.y, xRot);
                voronoi(y2, 2, _TextureRotations.y, yRot);
                voronoi(z2, 2, _TextureRotations.y, zRot);
                x2 = rotateUVs(x2, center, xRot);
                y2 = rotateUVs(y2, center, yRot);
                z2 = rotateUVs(z2, center, zRot);

                voronoi(x3, 2, _TextureRotations.z, xRot);
                voronoi(y3, 2, _TextureRotations.z, yRot);
                voronoi(z3, 2, _TextureRotations.z, zRot);
                x3 = rotateUVs(x3, center, xRot);
                y3 = rotateUVs(y3, center, yRot);
                z3 = rotateUVs(z3, center, zRot);

                float3 triW = abs(i.normal) * _TriplanarSharpness;
                triW = triW / (triW.x + triW.y + triW.z);

                float3 sandX1 = tex2D(_SandTex, x1).rgb;
                float3 sandY1 = tex2D(_SandTex, y1).rgb;
                float3 sandZ1 = tex2D(_SandTex, z1).rgb;
                
                float3 sandX2 = tex2D(_SandTex, x2).rgb;
                float3 sandY2 = tex2D(_SandTex, y2).rgb;
                float3 sandZ2 = tex2D(_SandTex, z2).rgb;

                float3 sandX3 = tex2D(_SandTex, x3).rgb;
                float3 sandY3 = tex2D(_SandTex, y3).rgb;
                float3 sandZ3 = tex2D(_SandTex, z3).rgb;

                float3 sandX = (sandX1 + sandX2 + sandX3) / 3;
                float3 sandY = (sandY1 + sandY2 + sandY3) / 3;
                float3 sandZ = (sandZ1 + sandZ2 + sandZ3) / 3;
                float4 sandColor = float4(sandX * triW.x + sandY * triW.y + sandZ * triW.z, 1.0);

                float3 grassX1 = tex2D(_GrassTex, x1).rgb;
                float3 grassY1 = tex2D(_GrassTex, y1).rgb;
                float3 grassZ1 = tex2D(_GrassTex, z1).rgb;

                float3 grassX2 = tex2D(_GrassTex, x2).rgb;
                float3 grassY2 = tex2D(_GrassTex, y2).rgb;
                float3 grassZ2 = tex2D(_GrassTex, z2).rgb;

                float3 grassX3 = tex2D(_GrassTex, x3).rgb;
                float3 grassY3 = tex2D(_GrassTex, y3).rgb;
                float3 grassZ3 = tex2D(_GrassTex, z3).rgb;

                float3 grassX = (grassX1 + grassX2 + grassX3) / 3;
                float3 grassY = (grassY1 + grassY2 + grassY3) / 3;
                float3 grassZ = (grassZ1 + grassZ2 + grassZ3) / 3;
                float4 grassColor = float4(grassX * triW.x + grassY * triW.y + grassZ * triW.z, 1.0);

                float3 rockX1 = tex2D(_RockTex, x1).rgb;
                float3 rockY1 = tex2D(_RockTex, y1).rgb;
                float3 rockZ1 = tex2D(_RockTex, z1).rgb;

                float3 rockX2 = tex2D(_RockTex, x2).rgb;
                float3 rockY2 = tex2D(_RockTex, y2).rgb;
                float3 rockZ2 = tex2D(_RockTex, z2).rgb;

                float3 rockX3 = tex2D(_RockTex, x3).rgb;
                float3 rockY3 = tex2D(_RockTex, y3).rgb;
                float3 rockZ3 = tex2D(_RockTex, z3).rgb;

                float3 rockX = (rockX1 + rockX2 + rockX3) / 3;
                float3 rockY = (rockY1 + rockY2 + rockY3) / 3;
                float3 rockZ = (rockZ1 + rockZ2 + rockZ3) / 3;
                float4 rockColor = float4(rockX * triW.x + rockY * triW.y + rockZ * triW.z, 1.0);
                
                float3 iceX1 = tex2D(_IceTex, x1).rgb;
                float3 iceY1 = tex2D(_IceTex, y1).rgb;
                float3 iceZ1 = tex2D(_IceTex, z1).rgb;

                float3 iceX2 = tex2D(_IceTex, x2).rgb;
                float3 iceY2 = tex2D(_IceTex, y2).rgb;
                float3 iceZ2 = tex2D(_IceTex, z2).rgb;

                float3 iceX3 = tex2D(_IceTex, x3).rgb;
                float3 iceY3 = tex2D(_IceTex, y3).rgb;
                float3 iceZ3 = tex2D(_IceTex, z3).rgb;

                float3 iceX = (iceX1 + iceX2 + iceX3) / 3;
                float3 iceY = (iceY1 + iceY2 + iceY3) / 3;
                float3 iceZ = (iceZ1 + iceZ2 + iceZ3) / 3;
                float4 iceColor = float4(iceX * triW.x + iceY * triW.y + iceZ * triW.z, 1.0);

                float blendTime1 = smoothstep(_BlendRegion1.x, _BlendRegion1.y, i.color.x);
                float blendTime2 = smoothstep(_BlendRegion2.x, _BlendRegion2.y, i.color.x);
                float blendTime3 = smoothstep(_BlendRegion3.x, _BlendRegion3.y, i.color.x);

                fixed4 col = lerp(lerp(lerp(sandColor, grassColor, blendTime1), rockColor, blendTime2), iceColor, blendTime3);
                
                /*float a2 = roughness * roughness;
                float d = ((NdotH * a2 - NdotH) * NdotH + 1.0);
                float D = a2 / (d * d * UNITY_PI);
                float k = roughness * roughness / 2.0;
                float g_v = NdotV / (NdotV * (1.0 - k) + k);
                float g_l = NdotL / (NdotL * (1.0 - k) + k);
                float G = g_v * g_l;
                float3 F = f0 + (float3(1.0, 1.0, 1.0) - f0) * pow(1 - 1DotH, 5.0);
                col = D * G * F / (4.0 * NdotL * NdotV);*/

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
