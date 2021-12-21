//只是模板，输出值没有用
Shader "Code Repository/Base/DepthToWorldPosTemplate" 
{
	Properties 
	{
		_BaseMap ("Example Texture", 2D) = "white" {}
		_BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)
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
			CBUFFER_END

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			//逆矩阵的方式
			//world = M ^-1 * ndc * Clip.w
			//1 = world.w = (M ^-1 * ndc).w * Clip.w ==> Clip.w = 1/(M ^-1 * ndc).w
			//==>world = M ^-1 * ndc * (M ^-1 * ndc).w
			float3 GetPosW(float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				//自己操作深度的时候，需要注意Reverse_Z的情况
				#if defined(UNITY_REVERSED_Z)
				depthTextureValue = 1 - depthTextureValue;
				#endif
				float4 ndc = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, depthTextureValue * 2 - 1, 1); //unity ndc z[-1, 1]
        
				float4 worldPos = mul(UNITY_MATRIX_I_V * unity_CameraInvProjection, ndc);
				worldPos /= worldPos.w;
				return worldPos.xyz;
			}

			//屏幕射线插值方式(https://blog.csdn.net/puppet_master/article/details/77489948),效率比逆矩阵好

		ENDHLSL

		Pass {
			Name "Unlit"
			//Tags { "LightMode"="SRPDefaultUnlit" } // (is default anyway)

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
	}
}