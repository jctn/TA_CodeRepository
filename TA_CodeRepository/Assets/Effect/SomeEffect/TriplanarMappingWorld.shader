Shader "Code Repository/Effect/TriplanarMappingWorld" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_NoiseTex ("NoiseTex", 2D) = "white" {}
		_Blend ("Blend", Range(0.1, 10)) = 1
		_ClipThreshold ("ClipThreshold", Range(0, 1)) = 0
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
			half _ClipThreshold;
			float _Blend;
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
				float3 normalW		: TEXCOORD1;
				float3 posWS		: TEXCOORD2;
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_NoiseTex);
			SAMPLER(sampler_NoiseTex);

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				OUT.normalW = TransformObjectToWorldNormal(IN.normal);
				OUT.posWS	= positionInputs.positionWS;
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				//Triplanar,使用世界坐标采样纹理，对非平面也有用
				//https://ravingbots.com/2015/09/02/how-to-improve-unity-terrain-texturing-tutorial/
				//https://cyangamedev.wordpress.com/2020/01/28/worldspace-uvs-triplanar-mapping/
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				half cX = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.posWS.zy).r;
				half cY = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.posWS.xz).r;
				half cZ = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.posWS.xy).r;
				float3 blendF = pow(abs(IN.normalW), _Blend);
				blendF /= dot(blendF, 1) + 0.001;
				half clipValue =  cX * blendF.x + cY * blendF.y + cZ * blendF.z;
				return half4(clipValue, clipValue, clipValue, 1);
				//clip(clipValue - _ClipThreshold);
				//return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}
	}
}