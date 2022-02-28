Shader "Code Repository/Base/Bump Mapping" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_BumpTex ("BumpTex", 2D) = "white" {}
		_BumpScale ("BumpScale", Range(0, 20)) = 2
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
			float4 _BumpTex_TexelSize;
			half _BumpScale;
			CBUFFER_END


			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_BumpTex);
			SAMPLER(sampler_BumpTex);

			//https://www.jianshu.com/p/fea6c9fc610f
			//凹凸贴图和法线贴图效果类似，只是凹凸贴图需要实时计算法线。凹凸贴图和法线贴图只能改变明暗变化，对于应该不能看见的部分无法实现遮挡（视差可以），https://www.cnblogs.com/jim-game-dev/p/5410529.html
			half3 CalculateNormal(float2 uv)
			{
				float2 du = float2(0.5 * _BumpTex_TexelSize.x, 0);
				half u1 = 1 - SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, uv - du).r; //这里采样的是深度图，故取反
				half u2 = 1 - SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, uv + du).r;
				half3 tu = half3(1, 0, (u2 - u1) * _BumpScale);

				float2 dv = float2(0, 0.5 * _BumpTex_TexelSize.y);
				half v1 = 1 - SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, uv - dv).r;
				half v2 = 1 - SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, uv + dv).r;
				half3 tv = half3(0, 1, (v2 - v1) * _BumpScale);
				
				return SafeNormalize(cross(tu, tv)); //切线空间
			}
		ENDHLSL

		Pass {
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				half3 TtoW0		: TEXCOORD1;
				half3 TtoW1		: TEXCOORD2;
				half3 TtoW2		: TEXCOORD3;
			};

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = SafeNormalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.TtoW0 = float3(tangentWS.x, binormalWS.x, normalWS.x);
				OUT.TtoW1 = float3(tangentWS.y, binormalWS.y, normalWS.y);
				OUT.TtoW2 = float3(tangentWS.z, binormalWS.z, normalWS.z);
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
				half3 normalTS = CalculateNormal(IN.uv);
				half3 normalWS = SafeNormalize(half3(dot(IN.TtoW0.xyz, normalTS), dot(IN.TtoW1.xyz, normalTS), dot(IN.TtoW2.xyz, normalTS)));
				half NdotL = max(0, dot(normalWS, _MainLightPosition.xyz));
				return baseMap * _BaseColor * _MainLightColor * NdotL;
			}
			ENDHLSL
		}
	}
}