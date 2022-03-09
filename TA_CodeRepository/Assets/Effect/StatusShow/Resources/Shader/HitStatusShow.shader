Shader "Code Repository/Effect/HitStatusShow" 
{
	Properties 
	{
		_BaseMap ("Base Map", 2D) = "white" {}
		_BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
		
        [Toggle]_HitOn("_HitOn", Float) = 0
        [HDR]_HitBaseCol("_HitBaseCol", Color) = (1, 1, 1, 1)
        [HDR]_HitRimCol("_HitRimCol", Color) = (1, 1, 1, 1)
        _HitRimThreshod("_HitRimThreshod", Range(0, 1)) = 0.5
        _HitRimSmooth("_HitRimSmooth", Range(0, 1)) = 0
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
			half4 _BaseColor;
			half _HitOn;
			half4 _HitRimCol;
			half4 _HitBaseCol;
			half4 _StaticShadowColor;
			float _HitRimThreshod;
			float _HitRimSmooth;
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Unlit"
			//Tags { "LightMode"="SRPDefaultUnlit" } // (is default anyway)

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			//效果分为3类，1.更改属性2.更改计算方式3.更改附加项
			//这是互斥的效果，直接影响结果的计算方式
			#pragma multi_compile _ A B C
			//这是叠加的效果，实在原有基础上添加颜色
			#pragma multi_compile _ a b c


			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float3 normal : NORMAL;
				float2 uv		    : TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float3 normalWS     : TEXCOORD1;
				float3 viewDirWS    : TEXCOORD2;
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
				OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
				OUT.viewDirWS = TransformObjectToWorld(IN.positionOS.xyz) - _WorldSpaceCameraPos.xyz;
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				half4 finalColor = baseMap * _BaseColor;

				float NdotV = 1 - saturate(dot(SafeNormalize(IN.normalWS), -SafeNormalize(IN.viewDirWS)));
				half3 hitCol = smoothstep((1 - _HitRimThreshod) - _HitRimSmooth, (1 - _HitRimThreshod) + _HitRimSmooth, NdotV) * _HitRimCol.rgb;
				float grayValue = 0.2125 * finalColor.r + 0.7154 * finalColor.g + 0.0721*finalColor.b;
				hitCol += grayValue * _HitBaseCol.rgb;
				finalColor.rgb = lerp(finalColor.rgb, hitCol, _HitOn);
				return finalColor;
			}
			ENDHLSL
		}
	}
}