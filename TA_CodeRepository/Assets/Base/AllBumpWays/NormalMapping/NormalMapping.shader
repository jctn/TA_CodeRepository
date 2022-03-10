Shader "Code Repository/Base/NormalMapping" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_SpecularScale ("SpecularScale", Float) = 1
		_SpecularCol ("SpecularCol", Color) = (1, 1, 1, 1)
		_NormalTex ("NormalTex", 2D) = "white" {}
		_BumpScale ("BumpScale", Range(0, 20)) = 1
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
			half _SpecularScale;
			half4 _SpecularCol;
			half _BumpScale;
			CBUFFER_END


			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_NormalTex);
			SAMPLER(sampler_NormalTex);
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
				half4 TtoW0		: TEXCOORD1;
				half4 TtoW1		: TEXCOORD2;
				half4 TtoW2		: TEXCOORD3;
			};

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = SafeNormalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				float3 posWS = float3(IN.TtoW0.w, IN.TtoW1.w, IN.TtoW2.w);
				float2 uv = IN.uv;				
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				half4 packNormal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv);
				half3 normalTS = UnpackNormalScale(packNormal, _BumpScale);
				half3 normalWS = SafeNormalize(half3(dot(IN.TtoW0.xyz, normalTS), dot(IN.TtoW1.xyz, normalTS), dot(IN.TtoW2.xyz, normalTS)));

				half NdotL = max(0, dot(normalWS, _MainLightPosition.xyz));
				half3 diffuseCol = baseMap.rgb * _BaseColor.rgb * _MainLightColor.rgb * NdotL;

				half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - posWS);
				half3 halfDir = SafeNormalize(_MainLightPosition.xyz + viewDirWS);
				half NDotH = max(0, dot(normalWS, halfDir));
				half3 specularCol = pow(NDotH, _SpecularScale * 256)  * _SpecularCol.rgb * _MainLightColor.rgb;
				return half4(diffuseCol + specularCol, baseMap.a * _BaseColor.a);
			}
			ENDHLSL
		}
	}
}