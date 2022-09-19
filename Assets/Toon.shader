Shader "Custom/Toon"
{
    Properties
    {
        _Color("Color", Color) = (0.5, 0.65, 1, 1)

        // Color of ambient light
        [HDR] // Allows for values above 1
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

        // Tints reflections
        [HDR] 
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        // Size of reflections
        _Glossiness("Glossiness", Float) = 32

        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "LightMode"="ForwardBase" // Request lighting data
            "PassFlags"="OnlyDirectional" // Request only main directional light
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Enable shader variants
            #pragma multi_compile_fwdbase
            //// make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 worldNormal: NORMAL;
                float3 viewDir : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                TRANSFER_SHADOW(o)
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 _Color;
            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                // Commpare world normal to light direction
                float NdotL = dot(_WorldSpaceLightPos0, normal);


                float shadow = SHADOW_ATTENUATION(i); // Get whether shadowed 
                // Smoothstep the lighting bands
                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
                // Include light color of main directional light
                float4 light = lightIntensity * _LightColor0;

                // Normalize view direction
                float3 viewDir = normalize(i.viewDir);
                // Get vector between viewing direction and light source
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);
                // Specular Blinn-Phong reflection intensity
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;

                // Get surfaces facing away from camera
                float4 rimDot = 1 - dot(viewDir, normal);
                // Reflect rim only on lit surfaces and extend it's size to threshold.
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

                // sample the texture
                fixed4 sample = tex2D(_MainTex, i.uv);
                //// apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return _Color * sample * (_AmbientColor + light + specular + rim);
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
