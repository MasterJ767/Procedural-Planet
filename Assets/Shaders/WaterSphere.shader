Shader "Unlit/WaterSphere"
{
    Properties
    {
        _WaterTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", float) = 3.0
        _DisplacementAmplitude ("Displacement Amplitude", float) = 3.0
        _TextureScale ("Texture Scale", float) = 1024.0
        _Depth ("Depth", float) = 3.0
        _Wavelength ("Wavelength", float) = 3.0
        _Speed ("Speed", float) = 3.0
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
            float _Radius, _DisplacementAmplitude, _TextureScale, _Depth, _Wavelength, _Speed;

            v2f vert (appdata v)
            {
                float k = 2 * UNITY_PI / _Wavelength;
                float f = k * (v.vertex.y - _Speed * _Time.x);
                float s = (sin(f) + 1) / 2;
                float c = (cos(f) + 1) / 2;
                float4 displacement = v.normal * lerp(lerp(0.65, 0.7, s), lerp(0.65, 0.7, c), 0.5) *_DisplacementAmplitude;
                v2f o;
                o.objPos = v.vertex * _Radius + displacement;
                o.vertex = UnityObjectToClipPos(o.objPos);
                //UNITY_TRANSFER_DEPTH(o.depth);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.normal = normalize(v.normal);
                o.color = float4(o.vertex.z / v.vertex.w, 0, 0, 0);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //UNITY_OUTPUT_DEPTH(i.depth);
                float2 screenSpaceUV = i.screenPos.xy / i.screenPos.w;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenSpaceUV);
                float linearDepth = Linear01Depth(depth);

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
