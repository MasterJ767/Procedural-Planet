Shader "Unlit/WorldSphere"
{
    Properties
    {
        _SandTex ("Sand Texture", 2D) = "white" {}
        _GrassTex ("Grass Texture", 2D) = "white" {}
        _RockTex ("Rock Texture", 2D) = "white" {}
        _IceTex ("Ice Texture", 2D) = "white" {}
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

            sampler2D _SandTex, _GrassTex, _RockTex, _IceTex;
            float _Radius, _NoiseScale, _DisplacementAmplitude, _TextureScale;
            float4 _NoiseOffset;

            float pi = 3.141592653589793238462;

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

                float3 albedoX;
                float3 albedoY;
                float3 albedoZ;
                if (i.color.x < 0.7) {
                    albedoX = tex2D(_SandTex, x).rgb;
                    albedoY = tex2D(_SandTex, y).rgb;
                    albedoZ = tex2D(_SandTex, z).rgb;
                }
                else if (i.color.x < 0.8) {
                    albedoX = tex2D(_GrassTex, x).rgb;
                    albedoY = tex2D(_GrassTex, y).rgb;
                    albedoZ = tex2D(_GrassTex, z).rgb;
                }
                else if (i.color.x < 0.9) {
                    albedoX = tex2D(_RockTex, x).rgb;
                    albedoY = tex2D(_RockTex, y).rgb;
                    albedoZ = tex2D(_RockTex, z).rgb;
                }
                else {
                    albedoX = tex2D(_IceTex, x).rgb;
                    albedoY = tex2D(_IceTex, y).rgb;
                    albedoZ = tex2D(_IceTex, z).rgb;
                }

                fixed4 col = float4(albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z, 1.0);
                
                /*float a2 = roughness * roughness;
                float d = ((NdotH * a2 - NdotH) * NdotH + 1.0);
                float D = a2 / (d * d * pi);
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
