// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WorldSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", float) = 3.0
        _NoiseScale ("Noise Scale", float) = 3.0
        _NoiseOffset ("Noise Offset", vector) = (1,1,1)
        _DisplacementAmplitude ("Displacement Amplitude", float) = 3.0
        _TextureScale ("Texture Scale", float) = 1024.0
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Radius, _NoiseScale, _DisplacementAmplitude, _TextureScale;
            float4 _NoiseOffset;

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
                float2 x = i.objPos.zy / _TextureScale;
                float2 y = i.objPos.xz / _TextureScale;
                float2 z = i.objPos.xy / _TextureScale;
                /*if (i.normal.x < 0) {
                    x.x = -x.x;
                }
                if (i.normal.y < 0) {
                    y.x = -y.x;
                }
                if (i.normal.z >= 0) {
                    z.x = -z.x;
                }
                x.y += 0.5;
                z.x += 0.5;*/

                float3 triW = abs(i.normal);
                triW = triW / (triW.x + triW.y + triW.z);
                
                float3 albedoX = tex2D(_MainTex, x).rgb;
                float3 albedoY = tex2D(_MainTex, y).rgb;
                float3 albedoZ = tex2D(_MainTex, z).rgb;

                fixed4 col = float4(albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z, 1.0);
                /*if (i.color.x < 0.65) {
                    col = float4(albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z, 1.0);
                }
                else if (i.color.x < 0.8) {
                    col = float4(0.47, 0.82, 0.13, 1);
                }
                else if (i.color.x < 0.9) {
                    col = float4(0.4, 0.4, 0.4, 1);
                }
                else {
                    col = float4(0.9, 0.9, 1, 1);
                }*/
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
