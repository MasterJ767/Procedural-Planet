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
        _WaterTex ("Texture", 2D) = "white" {}
        _TextureScale ("Texture Scale", float) = 1024.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass 
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            Fog {Mode Off}
            ZWrite On ZTest LEqual Cull Off
            Offset 1, 1

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f 
            { 
                V2F_SHADOW_CASTER;
            };

            v2f vert( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

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

            sampler2D _WaterTex, _CameraDepthTexture;
            float _Radius, _TextureScale, _Gravity, _Depth, _Phase, _NeighbourDistance;
            float4 _Direction1, _Direction2, _Direction3, _Direction4, _Amplitudes, _TimeScales;

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
                //UNITY_TRANSFER_DEPTH(o.depth);
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
                //UNITY_OUTPUT_DEPTH(i.depth);
                //float2 screenSpaceUV = i.screenPos.xy / i.screenPos.w;
                //float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenSpaceUV);
                //float linearDepth = Linear01Depth(depth);

                float2 x = i.objPos.zy / _TextureScale;
                float2 y = i.objPos.xz / _TextureScale;
                float2 z = i.objPos.xy / _TextureScale;
                if (i.normal.x < 0) {
                    x.x = -x.x;
                }
                if (i.normal.y < 0) {
                    y.x = -y.x;
                }
                if (i.normal.z >= 0) {
                    z.x = -z.x;
                }
                x.y += 0.5;
                z.x += 0.5;

                float3 triW = abs(i.normal);
                triW = triW / (triW.x + triW.y + triW.z);

                float3 albedoX = tex2D(_WaterTex, x).rgb;
                float3 albedoY = tex2D(_WaterTex, y).rgb;
                float3 albedoZ = tex2D(_WaterTex, z).rgb;

                fixed4 col = float4((albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z), 0.8);
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
