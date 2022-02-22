Shader "Code Repository/Scene/SimpleStylizedWater"
{
	Properties 
	{
		_NormalMap ("NormalMap", 2D) = "white" {}
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _NormalMap_ST;
			CBUFFER_END
		ENDHLSL

		Pass 
		{
			Name "SimpleStylizedWater"

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 positionSS	: TEXCOORD0;
			};

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);

			TEXTURE2D(_ReflectionTex);
			SAMPLER(sampler_ReflectionTex);
	
			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float2 screenUV = IN.positionSS.xy / IN.positionSS.w;
				half4 reflectionTex = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, screenUV);
				return reflectionTex;
			}
			ENDHLSL
		}
	}
}
