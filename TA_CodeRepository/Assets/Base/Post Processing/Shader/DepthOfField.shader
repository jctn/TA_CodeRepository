Shader "Code Repository/Post Processing/DepthOfField" 
{
	Properties 
	{
		_MainTex("Source", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		ZTest Always
		ZWrite Off 
		Cull Off

		HLSLINCLUDE
			#include "Common.hlsl"

			float4 _MainTex_TexelSize;
			float _BlurRange;

			half4 BlurFragment (Varyings input) : SV_Target
			{
				half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv).rgb;
				half3 sum = half3(0, 0, 0);
				sum += 0.4 * col;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(1, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(-1, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(2, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(-2, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;

				sum += 0.4 * col;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, 1) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, -1) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, 2) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, -2) * _MainTex_TexelSize.xy * _BlurRange).rgb;

				sum /= 2;
				return half4(sum, 1);
			}

			half4 MergeFragment (Varyings input) : SV_Target
			{
				half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv).rgb;
				half3 sum = half3(0, 0, 0);
				sum += 0.4 * col;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(1, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(-1, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(2, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(-2, 0) * _MainTex_TexelSize.xy * _BlurRange).rgb;

				sum += 0.4 * col;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, 1) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.2 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, -1) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, 2) * _MainTex_TexelSize.xy * _BlurRange).rgb;
				sum += 0.1 * SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, input.uv + half2(0, -2) * _MainTex_TexelSize.xy * _BlurRange).rgb;

				sum /= 2;
				return half4(sum, 1);
			}
		ENDHLSL

		Pass 
		{
			Name "Blur"

			HLSLPROGRAM
				#pragma vertex Vert
				#pragma fragment BlurFragment
			ENDHLSL
		}

		Pass 
		{
			Name "Merge"

			HLSLPROGRAM
				#pragma vertex Vert
				#pragma fragment MergeFragment
			ENDHLSL
		}
	}
}