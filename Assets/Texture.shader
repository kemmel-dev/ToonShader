Shader "Custom/Texture"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SecondTex ("Albedo (RGB)", 2D) = "white" {}
        _BlendPoint("Blend point", Range(0,1)) = 0.25
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _SecondTex;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_SecondTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


        float _BlendPoint;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c1 = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            // Albedo comes from a texture tinted by color
            fixed4 c2 = tex2D (_SecondTex, IN.uv_SecondTex) * _Color;

            fixed4 outputTex1 = c1.rgba * (1.0 - (c2.a * _BlendPoint));
            fixed4 outputTex2 = c2.rgba * (c2.a * _BlendPoint);
            o.Albedo = outputTex1.rgb + outputTex2.rgb;
            o.Alpha = outputTex1.a + outputTex2.a;

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
