Shader "Code Repository/Scene/Cloud/StylizedCloud2D_Noise_Lighting"
{
	Properties 
	{
		[NoScaleOffset]_CloudShapeTex ("CloudShapeTex", 2D) = "white" {}
		_CloudSpeedX ("CloudSpeedX", Float) = 1
		_CloudSpeedY ("CloudSpeedY", Float) = 1
		_CloudFill ("CloudFill", Range(0, 1)) = 0.5
		_CloudFillMax ("CloudFillMax", Float) = 1
		_CloudFillMin ("CloudFillMin", Float) = -1
		[NoScaleOffset]_CloudEdgeSoftUnevenTex ("CloudEdgeSoftUnevenTex", 2D) = "white" {}
		_CloudEdgeSoftUnevenTexScale ("CloudEdgeSoftUnevenTexScale", Float) = 4
		_CloudEdgeSoftMax ("CloudEdgeSoftMax", Float) = 0.1
		_CloudEdgeSoftMin ("CloudEdgeSoftMin", Float) = 0.01
		_CloudSize ("CloudSize", FLoat) = 1
		_CloudDetailSize ("CloudDetailSize", Float) = 2
		_CloudDetailIntensity ("CloudDetailIntensity", Float) = 0.5
		_CloudDetailIntensity_Few ("CloudDetailIntensity_Few", Float) = 3

		_CloudColor ("CloudColor", Color) = (1, 1, 1, 1)
		_CloudRimColor ("CloudRimColor", Color) = (1, 1, 1, 1)
		_CloudRimEdgeSoft ("CloudRimEdgeSoft", Float) = 0
		_CloudLightColor_NearSun ("CloudLightColor_NearSun", Color) = (1, 1, 1, 1)
		_CloudNearSunGlowRadius ("CloudNearSunGlowRadius", Float) = 1
		_CloudNearSunGlowIntensity ("CloudNearSunGlowIntensity", Float) = 1
		_CloudLightUVOffset ("CloudLightUVOffset", Float) = 0.01
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
				float _CloudSpeedX;
				float _CloudSpeedY;
				half _CloudFill;
				half _CloudFillMax;
				half _CloudFillMin;
				float _CloudEdgeSoftUnevenTexScale;
				half _CloudEdgeSoftMax;
				half _CloudEdgeSoftMin;
				float _CloudSize;
				float _CloudDetailSize;
				half _CloudDetailIntensity;
				half _CloudDetailIntensity_Few;

				half3 _CloudColor;
				half3 _CloudRimColor;
				half _CloudRimEdgeSoft;
				half3 _CloudLightColor_NearSun;
				float _CloudNearSunGlowRadius;
				float _CloudNearSunGlowIntensity;
				float _CloudLightUVOffset;
			CBUFFER_END

			TEXTURE2D(_CloudShapeTex);
			SAMPLER(sampler_CloudShapeTex);
			
			TEXTURE2D(_CloudEdgeSoftUnevenTex);
			SAMPLER(sampler_CloudEdgeSoftUnevenTex);	
		ENDHLSL

		Pass 
		{
			Name "StylizedCloud2D_Noise_Lighting"

			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				half3 Color			: COLOR;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;				
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 uv			: TEXCOORD0;
				float3 viewDirWS	: TEXCOORD1;
				float3 WtoT0		: TEXCOORD2;
				float3 WtoT1		: TEXCOORD3;
				float3 WtoT2		: TEXCOORD4;				
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv.xy = IN.uv * _CloudSize * ((1 - IN.Color.r) * 0.5 + 1); //2层差异
				OUT.uv.zw = (IN.Color.r * 0.5 + 1) * _Time.x * float2(_CloudSpeedX, _CloudSpeedY);
				OUT.viewDirWS = _WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformWorldToObjectDir(IN.tangent.xyz);
				float3 binormalWS = normalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.WtoT0 = tangentWS;
				OUT.WtoT1 = binormalWS;
				OUT.WtoT2 = normalWS;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float3 viewDirWS = normalize(IN.viewDirWS);
				float3 sunDir = -_MainLightPosition.xyz;
				//cloud shape
				float2 baseUV = IN.uv.xy;
				float2 cloudSpeed = IN.uv.zw;
				float2 uv_Main = baseUV + cloudSpeed;
				float2 uv_Detail =  baseUV * _CloudDetailSize + cloudSpeed;
				float2 uv_Edge = uv_Main  * _CloudEdgeSoftUnevenTexScale;

				half cloudEdgeSoftUneven = SAMPLE_TEXTURE2D(_CloudEdgeSoftUnevenTex, sampler_CloudEdgeSoftUnevenTex, uv_Edge).r;
				cloudEdgeSoftUneven = pow(cloudEdgeSoftUneven, 4);
				half edgeSmooth = lerp(_CloudEdgeSoftMin, _CloudEdgeSoftMax, cloudEdgeSoftUneven);
				half edgeSmoothMin = saturate(0.5 - edgeSmooth);
				half edgeSmoothMax = saturate(0.5 + edgeSmooth);

				half cloudMainShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Main).r;
				half cloudDetailShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Detail).r;
				//half detailLerp = (1 - abs(cloudMainShape - 0.5) * 2) * _CloudDetailIntensity;
				//half detailLerp = smoothstep(edgeSmoothMax, 0, cloudMainShape) * _CloudDetailIntensity;
				half detailIntensity = lerp(_CloudDetailIntensity_Few * _CloudDetailIntensity, _CloudDetailIntensity, _CloudFill);
				half detailLerp = (1 - abs(cloudMainShape - 0.5) * 2) * detailIntensity;
				detailLerp = saturate(detailLerp);
				half cloudShape = lerp(cloudMainShape, cloudDetailShape, detailLerp);
				//half cloudFillValue = _CloudFill * 2 - 1;
				half cloudFillValue = _CloudFillMax - (_CloudFillMax - _CloudFillMin) * (1 - _CloudFill);
				cloudShape = saturate(cloudShape + cloudFillValue);

				half cloudFinalShape = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShape);

				//cloud color
				half rimColorFactor = smoothstep(saturate(0.5 - _CloudRimEdgeSoft), saturate(0.5 + _CloudRimEdgeSoft), 1 - cloudShape);
				half3 cloudColor = lerp(_CloudColor, _CloudRimColor, rimColorFactor);

				float VDotL = dot(viewDirWS, sunDir);
				float sunIntensity = saturate(dot(_MainLightColor.rgb, 1));
				float nearSunFactor = smoothstep(_CloudNearSunGlowRadius, 0, abs(VDotL - 1)) * _CloudNearSunGlowIntensity * sunIntensity;
				nearSunFactor = pow(nearSunFactor, 4);
				half3 cloudLightedColor = lerp(_MainLightColor.rgb, _CloudLightColor_NearSun, saturate(nearSunFactor));
				
				float2 uvOffset = mul(float3x3(IN.WtoT0, IN.WtoT1, IN.WtoT2), normalize(viewDirWS - sunDir)).xy;
				uvOffset = uvOffset * smoothstep(0, 0.45, abs(VDotL - 1)) * _CloudLightUVOffset;
				float2 uv_MainLighted = uv_Main + uvOffset;
				half cloudMainShapeLighted = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_MainLighted).r;
				half detailLerpLighted = (1 - abs(cloudMainShapeLighted - 0.5) * 2) * detailIntensity;
				detailLerpLighted = saturate(detailLerpLighted);
				half cloudShapeLighted = lerp(cloudMainShapeLighted, cloudDetailShape, detailLerpLighted);
				cloudShapeLighted  = saturate(cloudShapeLighted + cloudFillValue);
				half cloudFinalShapeLighted = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShapeLighted);
				half cloudLightedFactor = sunIntensity * saturate(cloudFinalShape - cloudFinalShapeLighted);
				cloudColor = lerp(cloudColor, cloudLightedColor, cloudLightedFactor);

				cloudColor = lerp(_CloudColor, cloudColor, saturate(nearSunFactor + 0.1));

				return half4(cloudColor, cloudFinalShape);
			}
			ENDHLSL
		}
	}
}
