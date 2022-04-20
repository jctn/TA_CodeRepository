Shader "Code Repository/Scene/Cloud/StylizedCloud2D_Noise_Lighting"
{
	Properties 
	{
		[NoScaleOffset]_CloudShapeTex ("CloudShapeTex", 2D) = "white" {}
		_CloudSpeedX ("CloudSpeedX", Float) = 1
		_CloudSpeedY ("CloudSpeedY", Float) = 1
		_CloudFill ("CloudFill", Range(0, 1)) = 0.5
		//_CloudFillMax ("CloudFillMax", Float) = 1
		//_CloudFillMin ("CloudFillMin", Float) = -1
		[NoScaleOffset]_CloudEdgeSoftUnevenTex ("CloudEdgeSoftUnevenTex", 2D) = "white" {}
		_CloudEdgeSoftUnevenTexScale ("CloudEdgeSoftUnevenTexScale", Float) = 4
		_CloudEdgeSoftMax ("CloudEdgeSoftMax", Float) = 0.1
		_CloudEdgeSoftMin ("CloudEdgeSoftMin", Float) = 0.01
		_CloudSize ("CloudSize", FLoat) = 1
		_CloudDetailSize ("CloudDetailSize", Float) = 2
		_CloudDetailIntensity ("CloudDetailIntensity", Float) = 0.5
		//_CloudDetailIntensity_Few ("CloudDetailIntensity_Few", Float) = 3
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
				//half _CloudFillMax;
				//half _CloudFillMin;
				float _CloudEdgeSoftUnevenTexScale;
				half _CloudEdgeSoftMax;
				half _CloudEdgeSoftMin;
				float _CloudSize;
				float _CloudDetailSize;
				half _CloudDetailIntensity;
				//half _CloudDetailIntensity_Few;
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
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv * _CloudSize;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				//cloud shape
				float2 cloudSpeed = _Time.x * float2(_CloudSpeedX, _CloudSpeedY);
				float2 uv = IN.uv + cloudSpeed;
				float2 uv_Detail = IN.uv * _CloudDetailSize + cloudSpeed;

				half cloudEdgeSoftUneven = SAMPLE_TEXTURE2D(_CloudEdgeSoftUnevenTex, sampler_CloudEdgeSoftUnevenTex, IN.uv * _CloudEdgeSoftUnevenTexScale + cloudSpeed * 0.7 *_CloudEdgeSoftUnevenTexScale);
				cloudEdgeSoftUneven = pow(cloudEdgeSoftUneven, 4);
				half edgeSmooth = lerp(_CloudEdgeSoftMin, _CloudEdgeSoftMax, cloudEdgeSoftUneven);
				half edgeSmoothMin = 0.5 - edgeSmooth;
				half edgeSmoothMax = 0.5 + edgeSmooth;

				half cloudMainShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv).r;
				half cloudDetailShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Detail).r;
				//half detailLerp = (1 - abs(cloudMainShape - 0.5) * 2) * _CloudDetailIntensity;
				half detailLerp = smoothstep(edgeSmoothMax, 0, cloudMainShape) * _CloudDetailIntensity;
				detailLerp = saturate(detailLerp);
				half cloudShape = lerp(cloudMainShape, cloudDetailShape, detailLerp);
				half cloudFillValue = _CloudFill * 2 - 1;
				cloudShape += cloudFillValue;

				half cloudFinalShape = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShape);
				//half cloudFinalShape = smoothstep(0.5, 0.55, cloudMainShape);
				half3 finalColor = 1;
				return half4(finalColor, cloudFinalShape);
			}
			ENDHLSL
		}
	}
}
