Shader "Code Repository/Scene/Planar Shadow_Dir" 
{
	Properties 
	{
		_BaseMap ("Example Texture", 2D) = "white" {}
		_BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)

		_PlaneNormal("Plane Normal(world space)", Vector) = (0, 1, 0)
		_PlaneDTerm("Plane DTerm(world space)", Float) = -1
		_ShadowColor("ShadowColor", Color) = (0.1, 0.1, 0.1, 1)
		_ShadowFalloff("_ShadowFalloff", Range(0, 1)) = 0.5
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry+10"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float3 _PlaneNormal;
			float _PlaneDTerm;
			half4 _ShadowColor;
			half _ShadowFalloff;
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

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			Stencil
			{
				Ref 1
				Comp Equal
				Pass IncrSat 
			}

			Offset -1 , 0

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
				half   alpha		: TEXCOORD0;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				float3 planarNormal = _PlaneNormal;
				float ndotl = dot(planarNormal, _MainLightPosition.xyz);
				//https://zhuanlan.zhihu.com/p/94491734
				float3x4 M =  float3x4(1 - planarNormal.x * _MainLightPosition.x / ndotl, -planarNormal.y * _MainLightPosition.x / ndotl, -planarNormal.z * _MainLightPosition.x / ndotl, -_PlaneDTerm * _MainLightPosition.x / ndotl,
								-planarNormal.x * _MainLightPosition.y / ndotl, 1 - planarNormal.y * _MainLightPosition.y / ndotl, -planarNormal.z * _MainLightPosition.y / ndotl, -_PlaneDTerm * _MainLightPosition.y / ndotl,
								-planarNormal.x * _MainLightPosition.z / ndotl, -planarNormal.y * _MainLightPosition.z / ndotl, 1 - planarNormal.z * _MainLightPosition.z / ndotl, -_PlaneDTerm * _MainLightPosition.z / ndotl);
				float3 posW = TransformObjectToWorld(IN.positionOS.xyz);
				posW = mul(M, float4(posW, 1));
				OUT.positionCS = TransformWorldToHClip(posW);
				float3 centerPosW = TransformObjectToWorld(float3(0, 0, 0));
				OUT.alpha = 1 - saturate(distance(centerPosW, posW) * _ShadowFalloff);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				return half4(_ShadowColor.rgb, IN.alpha);
			}
			ENDHLSL
		}
	}
}