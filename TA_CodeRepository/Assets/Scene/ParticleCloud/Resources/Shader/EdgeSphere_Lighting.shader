Shader "Code Repository/ParticleCloud/EdgeSphere_Lighting"
{
    Properties
    {
        _BaseColor("Base Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }

        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            Cull Off

            HLSLPROGRAM            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };
      
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4x4 _MVPMatrix;
            float4x4 _MMatrix;
            CBUFFER_END
            
            Varings vert(Attributes IN)
            {
                Varings OUT;
                OUT.positionCS = mul(_MVPMatrix, IN.positionOS);
                OUT.positionWS = mul(_MMatrix, IN.positionOS).xyz;
                OUT.normalWS = mul((float3x3)_MMatrix, IN.normalOS);
                return OUT;
            }
            
            half4 frag(Varings IN):SV_Target
            {
                IN.normalWS = normalize(IN.normalWS);
                Light light = GetMainLight();
                half3 diffuse = LightingLambert(light.color, light.direction, IN.normalWS);
                uint pixelLightCount = GetAdditionalLightsCount();
                //for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
                //{
                //    Light light = GetAdditionalLight(lightIndex, IN.positionWS);
                //    diffuse += LightingLambert(light.color, light.direction, IN.normalWS);
                //}

                half3 color = diffuse * _BaseColor.xyz;
                return half4(color,1);
            }
            ENDHLSL            
        }
    }
}
