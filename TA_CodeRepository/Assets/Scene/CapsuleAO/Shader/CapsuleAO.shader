Shader "Code Repository/Scene/CapsuleAO" 
{
	Properties 
	{
		_BaseMap ("Base Texture", 2D) = "white" {}
		_BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "CapsuleAO.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float3 _PlaneNormal;
			float _PlaneDTerm;
			half4 _ShadowColor;
			half _ShadowFalloff;
			CBUFFER_END
		ENDHLSL

		Pass 
		{
			Tags { "LightMode"="UniversalForward" }

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
				float3 normal		: NORMAL;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
				float3 posWS		: TEXCOORD1;
				float3 normalWS		: TEXCOORD2;	
			};

			// Textures, Samplers & Global Properties
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			// Vertex Shader
			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.posWS = positionInputs.positionWS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
                float4 shadowCoord = TransformWorldToShadowCoord(IN.posWS);
                Light light = GetMainLight(shadowCoord);
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				float ao = SpheresAO_AmbientTerm_2(IN.posWS, normalize(IN.normalWS));
				return baseMap * _BaseColor * IN.color * light.shadowAttenuation * ao;
			}
			ENDHLSL
		}
	}
}