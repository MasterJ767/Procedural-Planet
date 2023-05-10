Shader "Unlit/WaterSphere"
{
    Properties
    {
        [Header(World Generation)]
        _Radius ("Radius", float) = 3.0
        _Gravity ("Gravity", float) = 9.81
        _Depth ("Depth", float) = 10
        _Phase ("Phase", float) = 0
        _Direction1 ("Direction 1", vector) = (0.1,0,0,0)
        _Direction2 ("Direction 2", vector) = (0,0,0.1,0)
        _Direction3 ("Direction 3", vector) = (0.05,0,0,0)
        _Direction4 ("Direction 4", vector) = (0,0,0.05,0)
        _Amplitudes ("Amplitudes", vector) = (1,2,3,4)
        _TimeScales ("TimeScales", vector) = (1,2,3,4)
        _NeighbourDistance ("Neighbour Distance", float) = 1
        
        [Header(Texturing)]
        _TriplanarSharpness ("Triplanar Blend Sharpness", float) = 1.0
        _TextureTilingOffset ("Texture Tiling and Offset", vector) = (1,1,0,0)
        _TextureRotations ("Texture Rotations", vector) = (16,35,40,0)
        [NoScaleOffset] _WaterTex ("Texture", 2D) = "white" {}
        _TintBlendRegion1 ("Tint Blend Region 1", vector) = (0.19,0.27,0,0)
        _TintBlendRegion2 ("Tint Blend Region 2", vector) = (0.62,0.70,0,0)
        _EquatorialTint ("Equatorial Tint", color) = (0.26,0.84,0.93,1)
        _MiddleTint ("Middle Tint", color) = (1,1,1,1)
        _PolarTint ("Polar Tint", color) = (0.22,0.22,0.79,1)        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
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
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _WaterTex;
            float _Radius, _Gravity, _Depth, _Phase, _NeighbourDistance, _TriplanarSharpness;
            float4 _Direction1, _Direction2, _Direction3, _Direction4, _Amplitudes, _TimeScales, _TextureTilingOffset, _TextureRotations, _TintBlendRegion1, _TintBlendRegion2, _EquatorialTint, _MiddleTint, _PolarTint;

            float frequency( float3 direction, float gravity, float depth ) 
            {
                float magnitude = length(direction);
                float a = tanh(depth * magnitude) * (gravity * magnitude);
                return sqrt(a);
            }

            float theta( float3 direction, float3 position, float gravity, float depth, float time, float phase ) 
            {
                float a = (direction.x * position.x) + (direction.z * position.z);
                float b = frequency(direction, gravity, depth) * time;
                return (a - b) - phase;
            }

            float3 trochoidalWave( float3 direction, float3 position, float gravity, float depth, float time, float phase, float amplitude )
            {
                float t = theta(direction, position, gravity, depth, time, phase);
                float magnitude = length(direction);
                float a = (direction.x / magnitude);
                float b = amplitude / tanh(magnitude * depth);
                float c = a * b;
                float x = -(sin(t) * c);
                float y = cos(t) * amplitude;
                float d = (direction.z / magnitude);
                float e = d * b;
                float z = -(sin(t) * e);
                return float3(x, y, z);
            }
            
            float3 trochoidalDisplacement( float3 position, float gravity, float depth, float phase ) 
            {
                float a = trochoidalWave(_Direction1, position, gravity, depth, _TimeScales.x * _Time.y, phase, _Amplitudes.x);
                float b = trochoidalWave(_Direction2, position, gravity, depth, _TimeScales.y * _Time.y, phase, _Amplitudes.y);
                float c = trochoidalWave(_Direction3, position, gravity, depth, _TimeScales.z * _Time.y, phase, _Amplitudes.z);
                float d = trochoidalWave(_Direction4, position, gravity, depth, _TimeScales.w * _Time.y, phase, _Amplitudes.w);
                return (a + b) + (c + d) + position; 
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

            float3 deriveNormal( float3 source, float3 neighbour1, float3 neighbour2 )
            {
                float a = normalize(neighbour1 - source);
                float b = normalize(source - neighbour2);
                return normalize(cross(a, b));
            }

            v2f vert (appdata v)
            {
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex * _Radius);
                float4 worldPosWave = float4(trochoidalDisplacement(worldPos, _Gravity, _Depth, _Phase), 0);
                v2f o;
                o.objPos = mul(unity_WorldToObject, worldPosWave);
                o.vertex = UnityObjectToClipPos(o.objPos);
                o.screenPos = ComputeScreenPos(o.vertex);
                float4 n1 = worldPos + float4(0, 0, _NeighbourDistance, 0);
                float4 n1Wave = float4(trochoidalDisplacement(n1, _Gravity, _Depth, _Phase), 0);
                float4 n1obj = mul(unity_WorldToObject, n1Wave);
                float4 n2 = worldPos + float4(_NeighbourDistance, 0, 0, 0);
                float4 n2Wave = float4(trochoidalDisplacement(n2, _Gravity, _Depth, _Phase), 0);
                float4 n2obj = mul(unity_WorldToObject, n2Wave);
                //o.normal = float4(deriveNormal(o.objPos, n1obj, n2obj), 0);
                o.normal = normalize(v.vertex);
                o.color = float4(o.vertex.z / v.vertex.w, 0, 0, 0);
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

                float3 triW = abs(i.normal) * _TriplanarSharpness;
                triW = triW / (triW.x + triW.y + triW.z);

                float3 waterX1 = tex2D(_WaterTex, x1).rgb;
                float3 waterY1 = tex2D(_WaterTex, y1).rgb;
                float3 waterZ1 = tex2D(_WaterTex, z1).rgb;

                float3 waterX2 = tex2D(_WaterTex, x2).rgb;
                float3 waterY2 = tex2D(_WaterTex, y2).rgb;
                float3 waterZ2 = tex2D(_WaterTex, z2).rgb;

                float3 waterX3 = tex2D(_WaterTex, x3).rgb;
                float3 waterY3 = tex2D(_WaterTex, y3).rgb;
                float3 waterZ3 = tex2D(_WaterTex, z3).rgb;

                float3 waterX = (waterX1 + waterX2 + waterX3) / 3;
                float3 waterY = (waterY1 + waterY2 + waterY3) / 3;
                float3 waterZ = (waterZ1 + waterZ2 + waterZ3) / 3;

                float4 texCol = float4(waterX * triW.x + waterY * triW.y + waterZ * triW.z, 1.0);

                float maxAmplitude = max(max(max(_Amplitudes.x, _Amplitudes.y), _Amplitudes.z), _Amplitudes.w);
                float yDisplacement = abs(i.objPos.y) / (_Radius + maxAmplitude);

                float tintTime1 = smoothstep(_TintBlendRegion1.x, _TintBlendRegion1.y, yDisplacement);
                float tintTime2 = smoothstep(_TintBlendRegion2.x, _TintBlendRegion2.y, yDisplacement);

                fixed4 tintCol = lerp(lerp(_EquatorialTint, _MiddleTint, tintTime1), _PolarTint, tintTime2);

                fixed4 col = texCol * tintCol;
                //fixed4 col = float4(difference, difference, difference, 1.0);
                //fixed4 col = float4(depth, 0.0, 0.0, 1.0);
                //fixed4 col = float4(i.objPos.x, i.objPos.y, i.objPos.z, 0.1);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
