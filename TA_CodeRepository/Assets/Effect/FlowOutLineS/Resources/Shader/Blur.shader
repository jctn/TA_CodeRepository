Shader "SaintSeiya2/Effect/FlowOutLineS/Blur"
{
 
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
 
	SubShader
	{
		Tags {"RenderPipeline" = "UniversalPipeline" }
		//高斯模糊
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
 
			HLSLPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
            };

			struct v2f_blur
			{
				float4 pos : SV_POSITION;
				float2 uv  : TEXCOORD0;
				float4 uv01 : TEXCOORD1;
				float4 uv23 : TEXCOORD2;
				float4 uv45 : TEXCOORD3;
			};
 
			TEXTURE2D(_MainTex);            
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_TexelSize;
			CBUFFER_END

			float4 _offsets;
			int _isUp;
 
			v2f_blur vert_blur(appdata v)
			{
				v2f_blur o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);

				o.uv = v.uv;
				_offsets *= _MainTex_TexelSize.xyxy;
				o.uv01 = v.uv.xyxy + _offsets.xyxy * float4(1, 0.1 * _isUp + (1 - _isUp), -1, -1);
				o.uv23 = v.uv.xyxy + _offsets.xyxy * float4(1, 0.1 * _isUp + (1 - _isUp), -1, -1) * 2.0;
				o.uv45 = v.uv.xyxy + _offsets.xyxy * float4(1, 0.1 * _isUp + (1 - _isUp), -1, -1) * 3.0;
				return o;
			}

			half4 frag_blur(v2f_blur i) : SV_Target
			{
				half4 color = half4(0,0,0,0);
				color += 0.4 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				color += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.xy);
				color += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.zw);
				color += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.xy);
				color += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.zw);
				color += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.xy);
				color += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.zw);
				return color;
			}
			ENDHLSL
		}
	}
}