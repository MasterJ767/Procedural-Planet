Shader "Custom/WorldLitTest"
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
        [NoScaleOffset] _SandTex ("Sand Texture", 2D) = "white" {}
        [NoScaleOffset] _GrassTex ("Grass Texture", 2D) = "white" {}
        [NoScaleOffset] _RockTex ("Rock Texture", 2D) = "white" {}
        [NoScaleOffset] _IceTex ("Ice Texture", 2D) = "white" {}
        _TintBlendRegion1 ("Tint Blend Region 1", vector) = (0.19,0.27,0,0)
        _TintBlendRegion2 ("Tint Blend Region 2", vector) = (0.62,0.70,0,0)
        _EquatorialTint ("Equatorial Tint", color) = (0.77,0.58,0.17,1)
        _MiddleTint ("Middle Tint", color) = (1,1,1,1)
        _PolarTint ("Polar Tint", color) = (0.83,0.88,0.89,1)        
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 4.0

        sampler2D _SandTex, _GrassTex, _RockTex, _IceTex;
        float _Glossiness, _Metallic, _Radius, _NoiseScale, _DisplacementAmplitude, _TextureScale, _TriplanarSharpness;
        float4 _NoiseOffset, _BlendRegion1, _BlendRegion2, _BlendRegion3, _TextureTilingOffset, _TextureRotations, _TintBlendRegion1, _TintBlendRegion2, _EquatorialTint, _MiddleTint, _PolarTint;

        struct Input
        {
            float4 vertex : SV_POSITION;
            float4 noiseVal : COLOR;
            float4 normal : NORMAL;
            float4 objPos : TEXCOORD0;
        };

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

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

            float noise = lerp( lerp(   lerp( hash(n+0.0), hash(n+1.0),f.x),    lerp( hash(n+57.0), hash(n+58.0),f.x),  f.y),
                                lerp(   lerp( hash(n+113.0), hash(n+114.0),f.x),    lerp( hash(n+170.0), hash(n+171.0),f.x),    f.y),   f.z);
            
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

        float voronoi( float2 uv, float angleOffset, float cellDensity)
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
                        return res.y;
                    }
                }
            }
            return 0;
        }

        void vert(inout appdata_full v, out Input o) {
            float noiseValue = noise(v.vertex * _NoiseScale + _NoiseOffset.xyz);
            float4 displacement = float4(v.normal, 0) * float4(noiseValue, noiseValue, noiseValue, 1) * _DisplacementAmplitude;
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objPos = v.vertex * _Radius + displacement;
            o.vertex = UnityObjectToClipPos(o.objPos);
            v.vertex = o.objPos;
            o.normal = normalize(float4(v.normal, 0));
            v.normal = o.normal;
            o.noiseVal = float4(noiseValue, 0, 0, 0);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 tiling = float2(_TextureTilingOffset.x, _TextureTilingOffset.y);
            float2 offset1 = float2(_TextureTilingOffset.z, _TextureTilingOffset.w);
            float2 offset2 = offset1 + float2(0.25, 0.25);
            float2 offset3 = offset1 + float2(0.75, 0.75);

            float2 x1 = IN.objPos.zy * tiling + offset1;
            float2 y1 = IN.objPos.xz * tiling + offset1;
            float2 z1 = IN.objPos.xy * tiling + offset1;

            float2 x2 = IN.objPos.zy * tiling + offset2;
            float2 y2 = IN.objPos.xz * tiling + offset2;
            float2 z2 = IN.objPos.xy * tiling + offset2;

            float2 x3 = IN.objPos.zy * tiling + offset3;
            float2 y3 = IN.objPos.xz * tiling + offset3;
            float2 z3 = IN.objPos.xy * tiling + offset3;

            float2 center = float2(0.5, 0.5);

            float xRot1 = voronoi(x1, 2, _TextureRotations.x);
            float yRot1 = voronoi(y1, 2, _TextureRotations.x);
            float zRot1 = voronoi(z1, 2, _TextureRotations.x);
            x1 = rotateUVs(x1, center, xRot1);
            y1 = rotateUVs(y1, center, yRot1);
            z1 = rotateUVs(z1, center, zRot1);

            float xRot2 = voronoi(x2, 2, _TextureRotations.y);
            float yRot2 = voronoi(y2, 2, _TextureRotations.y);
            float zRot2 = voronoi(z2, 2, _TextureRotations.y);
            x2 = rotateUVs(x2, center, xRot2);
            y2 = rotateUVs(y2, center, yRot2);
            z2 = rotateUVs(z2, center, zRot2);

            float xRot3 = voronoi(x3, 2, _TextureRotations.z);
            float yRot3 = voronoi(y3, 2, _TextureRotations.z);
            float zRot3 = voronoi(z3, 2, _TextureRotations.z);
            x3 = rotateUVs(x3, center, xRot3);
            y3 = rotateUVs(y3, center, yRot3);
            z3 = rotateUVs(z3, center, zRot3);

            float3 triW = abs(IN.normal) * _TriplanarSharpness;
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

            float blendTime1 = smoothstep(_BlendRegion1.x, _BlendRegion1.y, IN.noiseVal.x);
            float blendTime2 = smoothstep(_BlendRegion2.x, _BlendRegion2.y, IN.noiseVal.x);
            float blendTime3 = smoothstep(_BlendRegion3.x, _BlendRegion3.y, IN.noiseVal.x);

            fixed4 texCol = lerp(lerp(lerp(sandColor, grassColor, blendTime1), rockColor, blendTime2), iceColor, blendTime3);

            float yDisplacement = abs(IN.objPos.y) / (_Radius + _DisplacementAmplitude);

            float tintTime1 = smoothstep(_TintBlendRegion1.x, _TintBlendRegion1.y, yDisplacement);
            float tintTime2 = smoothstep(_TintBlendRegion2.x, _TintBlendRegion2.y, yDisplacement);

            fixed4 tintCol = lerp(lerp(_EquatorialTint, _MiddleTint, tintTime1), _PolarTint, tintTime2);

            fixed4 col = texCol * tintCol;
            o.Albedo = col.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = col.a;
        }
        ENDCG
    }
    FallBack "WorldSphere"
}
