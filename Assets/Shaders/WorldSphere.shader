Shader "Unlit/WorldSphere"
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Radius, _NoiseScale, _DisplacementAmplitude;
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

            v2f vert (appdata v)
            {
                float noiseValue = noise(v.vertex * _NoiseScale + _NoiseOffset.xyz);
                float4 displacement = v.normal * float4(noiseValue, noiseValue, noiseValue, 1) * _DisplacementAmplitude;
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex * _Radius + displacement);
                if (noiseValue < 0.65) {
                    o.color = float4(0.76, 0.7, 0.5, 1);
                }
                else if (noiseValue < 0.8) {
                    o.color = float4(0.47, 0.82, 0.13, 1);
                }
                else if (noiseValue < 0.9) {
                    o.color = float4(0.4, 0.4, 0.4, 1);
                }
                else {
                    o.color = float4(0.9, 0.9, 1, 1);
                }
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 col = i.color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
