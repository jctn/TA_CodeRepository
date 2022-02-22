//https://github.com/QianMo/X-PostProcessing-Library/blob/master/Assets/X-PostProcessing/Effects/DualKawaseBlur/Shader/DualKawaseBlur.shader
Shader "Code Repository/Scene/SimpleStylizedWater/Reflection_DualKawaseBlur" 
{
	Properties 
	{
		_MainTex ("MainTex", 2D) = "white" {}
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
		}

		Cull Off ZWrite Off ZTest Always

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		half _Offset;
		float4 _MainTex_TexelSize;
		TEXTURE2D(_MainTex);            
		SAMPLER(sampler_MainTex);

		struct Attributes 
		{
			float4 positionOS	: POSITION;
			float2 uv		    : TEXCOORD0;
		};

		struct Varyings_DownSample
		{
			float4 positionCS: SV_POSITION;
			float2 uv: TEXCOORD0;
			float4 uv01: TEXCOORD1;
			float4 uv23: TEXCOORD2;
		};
	
	
		struct Varyings_UpSample
		{
			float4 positionCS: SV_POSITION;
			float4 uv01: TEXCOORD0;
			float4 uv23: TEXCOORD1;
			float4 uv45: TEXCOORD2;
			float4 uv67: TEXCOORD3;
		};

		Varyings_DownSample Vert_DownSample(Attributes v)
		{
			Varyings_DownSample o;
			o.positionCS = TransformObjectToHClip(v.positionOS.xyz);	
			
			float2 uv = v.uv;		
			_MainTex_TexelSize *= 0.5;
			float2 offset = float2(1 + _Offset, 1 + _Offset);
			o.uv = uv;
			o.uv01.xy = uv - _MainTex_TexelSize.xy * offset;
			o.uv01.zw = uv + _MainTex_TexelSize.xy * offset;
			o.uv23.xy = uv - float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;
			o.uv23.zw = uv + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;
		
			return o;
		}

		half4 Frag_DownSample(Varyings_DownSample i): SV_Target
		{
			half4 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * 4;
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.zw);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.zw);
		
			return sum * 0.125;
		}

		Varyings_UpSample Vert_UpSample(Attributes v)
		{
			Varyings_UpSample o;
			o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
		
			float2 uv = v.uv;
			_MainTex_TexelSize *= 0.5;
			float2 offset = float2(1 + _Offset, 1 + _Offset);
		
			o.uv01.xy = uv + float2(-_MainTex_TexelSize.x * 2, 0) * offset;
			o.uv01.zw = uv + float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y) * offset;
			o.uv23.xy = uv + float2(0, _MainTex_TexelSize.y * 2) * offset;
			o.uv23.zw = uv + _MainTex_TexelSize.xy * offset;
			o.uv45.xy = uv + float2(_MainTex_TexelSize.x * 2, 0) * offset;
			o.uv45.zw = uv + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;
			o.uv67.xy = uv + float2(0, -_MainTex_TexelSize.y * 2) * offset;
			o.uv67.zw = uv - _MainTex_TexelSize.xy * offset;
		
			return o;
		}
	
		half4 Frag_UpSample(Varyings_UpSample i): SV_Target
		{
			half4 sum = 0;
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.zw) * 2;
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.zw) * 2;
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.zw) * 2;
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv67.xy);
			sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv67.zw) * 2;
		
			return sum * 0.0833;
		}
		ENDHLSL

		Pass
		{
			HLSLPROGRAM
			
			#pragma vertex Vert_DownSample
			#pragma fragment Frag_DownSample
			
			ENDHLSL
			
		}
		
		Pass
		{
			HLSLPROGRAM
			
			#pragma vertex Vert_UpSample
			#pragma fragment Frag_UpSample
			
			ENDHLSL
			
		}
	}
}