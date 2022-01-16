Shader "Code Repository/Effect/DitherByDistance" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_Near ("Near", Float) = 5
		_Far ("Far", Float) = 9
		_GridSize ("GridSize", Range(0, 1)) = 1
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="AlphaTest"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float _Near;
			float _Far;
			float _GridSize;
			CBUFFER_END
		ENDHLSL

		Pass {
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

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
				float4 posSS		: TEXCOORD1;
				float3 posWS		: TEXCOORD2;
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				OUT.posSS	= ComputeScreenPos(OUT.positionCS);
				OUT.posWS	= positionInputs.positionWS;
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				float2 screenPos = (IN.posSS.xy / IN.posSS.w) * _ScreenParams.xy;

				//dither0
				//float dither = frac((sin(IN.posWS.x + IN.posWS.y) * 99 + 11) * 99);
				//return dither;

				//dither1
				//float dither = InterleavedGradientNoise(screenPos, 0);

				//dither2,相当于把矩阵平铺到屏幕空间中
				//float4x4 ditherMatrix = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
				//float dither = ditherMatrix[floor(fmod(screenPos.x * _GridSize, 4))][floor(fmod(screenPos.y * _GridSize, 4))];

				//dither3
				//float2x4 ditherMatrix = {1, 0, 1, 0, 0, 1, 0, 1};
				//float dither = ditherMatrix[floor(fmod(screenPos.x * _GridSize, 2))][floor(fmod(screenPos.y * _GridSize, 4))];

				//dither4
				//float2x4 ditherMatrix = {1, 0, 1, 0, 0, 1, 0, 1};
				//float dither = ditherMatrix[floor(fmod(screenPos.x * _GridSize, 2))][floor(fmod(screenPos.y * _GridSize, 4))];

				//dither5
				float4x4 ditherMatrix = {1, 9, 3, 11, 13, 5, 15, 7, 4, 12, 2, 10, 8, 7, 14, 6};
				float dither = ditherMatrix[floor(fmod(screenPos.x * _GridSize, 4))][floor(fmod(screenPos.y * _GridSize, 4))] / 17;
				//float dither = ditherMatrix[floor(fmod(screenPos.x * _GridSize, 2))] / 17 * ditherMatrix[floor(fmod(screenPos.y * _GridSize, 4))] / 17;

				//return dither;

				float dis = smoothstep(_Near, _Far, distance(IN.posWS, _WorldSpaceCameraPos));			
				clip(dis-dither);
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}
	}
}