Shader "Code Repository/Dynamic Sky/StylizedCloud_YS" 
{
	Properties 
	{
		_CloudTex ("CloudTex", 2D) = "white" {}
		_DarkColor ("DarkColor", Color) = (0, 0, 0, 0)
		_BrightColor ("BrightColor", Color) = (1, 1, 1, 1)
		_RimColor ("RimColor", Color) = (1, 1, 1, 1)
		_LightColor ("LightColor", Color) = (1, 1, 1, 1)
		_CloudBrightness ("CloudBrightness", Float) = 1
		_DepthFade ("DepthFade", Float) = 1
		_DepthThresh ("DepthThresh", Float) = 1
		_AlphaBrightness ("AlphaBrightness", Float) = 1
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
			float4 _CloudTex_ST;
			half4 _DarkColor;
			half4 _BrightColor;
			half3 _RimColor;
			half3 _LightColor;
			half _CloudBrightness;
			float _DepthFade;
			float _DepthThresh;
			half _AlphaBrightness;	
			CBUFFER_END

			half _MHYZBias;
		ENDHLSL

		Pass 
		{
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv	: TEXCOORD0;
				float4 color		: COLOR;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 color	: TEXCOORD0;
				float2 uv : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
			};

			TEXTURE2D(_CloudTex);
			SAMPLER(sampler_CloudTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				float4 posCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionCS = posCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _CloudTex);
				OUT.color = IN.color;
				OUT.screenPos = ComputeScreenPos(posCS);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				half3 u_xlat16_0;
				half4 u_xlat1;
				half3 fianlColor;
				float2 u_xlat2;
				half3 cloudColor;
				half3 rimColor;
				float u_xlat6;
				float u_xlat10;
				half finalAlpha;		

				fianlColor.xyz = (-_DarkColor.xyz) + _BrightColor.xyz;
				cloudColor.xyz = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, IN.uv).xyw;
				fianlColor.xyz = cloudColor.xxx * fianlColor.xyz + _DarkColor.xyz;
				rimColor.xyz = cloudColor.yyy * _RimColor.xyz;
				fianlColor.xyz = rimColor.xyz + fianlColor.xyz;
				finalAlpha = cloudColor.z * IN.color.w;
				u_xlat1.xyz = IN.color.xyz * _CloudBrightness * fianlColor.xyz + cloudColor.xxx * _LightColor.xyz;
				u_xlat1.w = finalAlpha;
				return u_xlat1;
			}
			ENDHLSL
		}
	}
}