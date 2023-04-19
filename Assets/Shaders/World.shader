Shader "Custom/World"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", float) = 3.0
        _NoiseScale ("Noise Scale", float) = 3.0
        _NoiseOffset ("Noise Offset", vector) = (1,1,1)
        _DisplacementAmplitude ("Displacement Amplitude", float) = 3.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 4.0
        #pragma require 2darray

        UNITY_DECLARE_TEX2DARRAY(_DiffuseTextures);
        UNITY_DECLARE_TEX2DARRAY(_Normaltextures);

        struct Input
        {
            float4 vertex : SV_POSITION;
            float4 color : COLOR;
            float4 normal : NORMAL;
            float2 uv : TEXCOORD0;
        };

        sampler2D _MainTex;
        float _Radius, _NoiseScale, _DisplacementAmplitude;
        float4 _NoiseOffset;

        UNITY_INSTANCING_BUFFER_START(Props)

        UNITY_INSTANCING_BUFFER_END(Props)

        float hash( float n )
        {
            return frac(sin(n)*43758.5453);
        }

        float noise( float3 x )
        {
            // The noise function returns a value in the range -1.0f -> 1.0f

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

        void vert(inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            float noiseValue = noise(v.vertex * _NoiseScale + _NoiseOffset.xyz);
            float4 displacement = float4(v.normal, 1) * float4(noiseValue, noiseValue, noiseValue, 1) * _DisplacementAmplitude;
            o.vertex = UnityObjectToClipPos(v.vertex * _Radius + displacement);
            o.normal = float4(normalize(v.normal), 1);
            o.color = float4(noiseValue, 0, 0, 0);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 x = IN.vertex.zy / 1024.0;
            float2 y = IN.vertex.xz / 1024.0;
            float2 z = IN.vertex.xy / 1024.0;
            if (IN.normal.x < 0) {
                x.x = -x.x;
            }
            if (IN.normal.y < 0) {
                y.x = -y.x;
            }
            if (IN.normal.z >= 0) {
                z.x = -z.x;
            }
            x.y += 0.5;
            z.x += 0.5;

            float3 triW = abs(IN.normal);
            triW = triW / (triW.x + triW.y + triW.z);
            
            float3 albedoX = tex2D(_MainTex, x);
            float3 albedoY = tex2D(_MainTex, y);
            float3 albedoZ = tex2D(_MainTex, z);
            
            o.Albedo = float4(albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z, 1.0);

            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
