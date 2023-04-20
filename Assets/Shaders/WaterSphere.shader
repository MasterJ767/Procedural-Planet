Shader "Unlit/WaterSphere"
{
    Properties
    {
        _WaterTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", float) = 3.0
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

            sampler2D _WaterTex;
            float _Radius, _DisplacementAmplitude, _TextureScale;

            float pi = 3.141592653589793238462;

            v2f vert (appdata v)
            {
                float4 displacement = v.normal * 0.65 * _DisplacementAmplitude;
                v2f o;
                o.objPos = v.vertex * _Radius + displacement;
                o.vertex = UnityObjectToClipPos(o.objPos);
                o.normal = normalize(v.normal);
                o.color = float4(0, 0, 0, 0);
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

                float3 albedoX = tex2D(_WaterTex, x).rgb;
                float3 albedoY = tex2D(_WaterTex, y).rgb;
                float3 albedoZ = tex2D(_WaterTex, z).rgb;

                fixed4 col = float4(albedoX * triW.x + albedoY * triW.y + albedoZ * triW.z, 1.0);
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
