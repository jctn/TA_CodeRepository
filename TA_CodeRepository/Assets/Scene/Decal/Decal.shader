Shader "Code Repository/Scene/Decal" 
{
	Properties 
	{
		_ProjectorTex ("ProjectorTex", 2D) = "white" {}
		_MaskMap ("MaskMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Transparent" 
			"DisableBatching"="true"
		}

		ZWrite Off
		Blend DstColor Zero

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			CBUFFER_END
		ENDHLSL

		Pass {
			//Tags { "LightMode"="SRPDefaultUnlit" } // (is default anyway)

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float4 color		: COLOR;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 screenPos	: TEXCOORD0;
				float4 color		: COLOR;
			};

			// Textures, Samplers & Global Properties
			TEXTURE2D(_ProjectorTex);
			SAMPLER(sampler_ProjectorTex);

			TEXTURE2D(_MaskMap);
			SAMPLER(sampler_MaskMap);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			// Vertex Shader
			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.screenPos = ComputeScreenPos(OUT.positionCS);
				OUT.color = IN.color;
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				float2 screenPos = IN.screenPos.xy / IN.screenPos.w;
				float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				#if defined(UNITY_REVERSED_Z)
					depth = 1 - depth;
				#endif
				//return half4(depth,depth, depth,1);
				float4 clipPos = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, depth * 2 - 1, 1);
				float4 cameraSpacePos = mul(unity_CameraInvProjection, clipPos);
				float4 worldSpacePos = mul(unity_MatrixInvV, cameraSpacePos);
				worldSpacePos /= worldSpacePos.w;
				float3 posOS = mul(unity_WorldToObject, worldSpacePos).xyz;
				//clip(float3(0.5, 0.5, 0.5) - abs(posOS));
				float2 uv = posOS.xz + 0.5;
				half4 col = SAMPLE_TEXTURE2D(_ProjectorTex, sampler_ProjectorTex, uv) * _BaseColor;
				half4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);

				col.rgb =  lerp(half3(1, 1, 1), col.rgb, (1 - mask.r));
				return col;
			}
			ENDHLSL
		}
	}
}