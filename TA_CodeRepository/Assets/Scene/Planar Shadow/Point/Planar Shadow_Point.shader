Shader "Code Repository/Scene/Planar Shadow_Point" 
{
	Properties 
	{
		_BaseMap ("Example Texture", 2D) = "white" {}
		_BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)

		_PlaneNormal("Plane Normal(world space)", Vector) = (0, 1, 0)
		_PlaneDTerm("Plane DTerm(world space)", Float) = -1
		_ShadowColor("ShadowColor", Color) = (0.1, 0.1, 0.1, 1)
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

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float3 _PlaneNormal;
			float _PlaneDTerm;
			half4 _ShadowColor;
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Unlit"
			Tags { "LightMode"="UniversalForward" }

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
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
				// Or :
				//OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

				return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}

		Pass 
		{
			Name "Planar Shadow"
			Tags { "LightMode"="SRPDefaultUnlit" }

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
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				float3 planarNormal = _PlaneNormal;
				float3 sourcePos = _AdditionalLightsPosition[0].xyz;
				float ndots = dot(planarNormal, sourcePos);
				//https://zhuanlan.zhihu.com/p/94555744
				float4x4 M =  float4x4(ndots + _PlaneDTerm - planarNormal.x * sourcePos.x, -planarNormal.y * sourcePos.x, -planarNormal.z * sourcePos.x, -_PlaneDTerm*sourcePos.x,
										-planarNormal.x * sourcePos.y, ndots + _PlaneDTerm - planarNormal.y * sourcePos.y, -planarNormal.x * sourcePos.y, -_PlaneDTerm*sourcePos.y,
										-planarNormal.x * sourcePos.z, -planarNormal.y * sourcePos.z, ndots + _PlaneDTerm - planarNormal.z * sourcePos.z, -_PlaneDTerm*sourcePos.z,
										-planarNormal.x, -planarNormal.y, -planarNormal.z, ndots);
				float4 posW = float4(TransformObjectToWorld(IN.positionOS.xyz), 1);
				float4 shadowPosW = mul(M, posW);
				OUT.positionCS = TransformWorldToHClip(shadowPosW.xyz / shadowPosW.w);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				return _ShadowColor;
			}
			ENDHLSL
		}
	}
}