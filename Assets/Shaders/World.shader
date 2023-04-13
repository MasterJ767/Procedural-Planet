Shader "Custom/World"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Tint ("Tint", Color) = (1,1,1,0)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Radius ("Radius", float) = 100.0
        _WorldWidthVertices ("WorldWidthVertices", float) = 400.0
        _WorldHeight ("WorldHeight", float) = 128.0
        _Amount("Amount", Range(0,1)) = 0
        _MainTex("Main Texture", 2D) = "white"{}
		_DisplacementTexture("Displacement Texture", 2D) = "white"{}
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
            float2 uv_MainTex;
            float displacementValue;
            float4 truePosition;
        };

        fixed4 _Color,_Tint;
        half _Glossiness,_Metallic,_Radius,_WorldWidthVertices,_WorldHeight,_Amount;
        sampler2D _MainTex,_DisplacementTexture;

        UNITY_INSTANCING_BUFFER_START(Props)

        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v, out Input o) {
            float value = tex2Dlod(_DisplacementTexture, v.texcoord*7).x * _Amount;
            v.vertex.xyz += v.normal.xyz * value * 0.3;
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.displacementValue = value;

            /*float4 vPos = mul(unity_ObjectToWorld, v.vertex);
            float noise = PeriodicNoise(vPos.xz, _WorldWidthVertices);
            noise *= _WorldHeight;
            vPos.y += noise;
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.truePosition = vPos;

            float3 vertInCamSpace = v.vertex - _WorldSpaceCameraPos;
            float x_2 = vertInCamSpace.x * vertInCamSpace.x;
            float z_2 = vertInCamSpace.z * vertInCamSpace.z;
            float rad_2 = _Radius * _Radius;
            float x_offset = sqrt(rad_2 - x_2) - _Radius;
            float z_offset = sqrt(rad_2 - z_2) - _Radius;
            float y_offset = x_offset + (z_offset - x_offset) * 0.5f;
            v.vertex.y += y_offset;

            o.vertex = mul(unity_WorldToObject, vPos);*/
            //o.position = mul(unity_WorldToObject, vPos);
            //o.color = v.color;
            //o.uv_MainTex = v.texcoord.xy;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            
            o.Albedo = lerp(c.rgb * c.a, float3(0, 0, 0), IN.displacementValue); //lerp based on the displacement

            o.Alpha = c.a;

            /*float ARRAY_INDEX = 0;
            fixed4 c = UNITY_SAMPLE_TEX2DARRAY(_DiffuseTextures, float3(IN.uv_MainTex, ARRAY_INDEX)) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;*/
        }
        ENDCG
    }
    FallBack "Diffuse"
}
