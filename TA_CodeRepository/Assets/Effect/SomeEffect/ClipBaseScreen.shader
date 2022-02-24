Shader "Code Repository/Effect/ClipBaseScreen" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_Grid ("Grid", Range(0, 0.5)) = 0
		[Enum(H, 0, V, 1, Both, 2, Chessboard, 3)]_GridType ("GridType", Float) = 3
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
			float _Grid;
			uint _GridType;
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
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				//https://blog.csdn.net/sgnyyy/article/details/70039412
				//float2 screenPos = IN.positionCS.xy;
				float2 screenPos = (IN.posSS.xy / IN.posSS.w) * _ScreenParams.xy;
				float2 grid = floor(screenPos * _Grid) * 0.5;
				//float2 grid = floor(IN.positionCS.xy * _Grid) * 0.5;
				float2 clipValue = 0;
				if(_GridType == 0)
				{
					clipValue = -frac(grid.x); //(x, 0)方向
				}
				else if(_GridType == 1)
				{
					clipValue = -frac(grid.y); //(0, y)方向
				}
				else if(_GridType == 2)
				{
					clipValue = -frac(grid); //x，y都为负数clip
				}
				else
				{
					clipValue = -frac(grid.x + grid.y); //棋盘
				}		
				clip(clipValue);
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}
	}
}