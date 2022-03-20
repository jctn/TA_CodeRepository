Shader "Code Repository/Scene/CustomSkyBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="AlphaTest+1"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			float4 _MainTex_HDR;
			CBUFFER_END
		ENDHLSL

		Pass 
		{
			Name "CustomSkyBox"

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

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
	
			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				#if UNITY_REVERSED_Z
					OUT.positionCS.z = 0.000001 * OUT.positionCS.w;
				#else
					OUT.positionCS.z = 0.999999 * OUT.positionCS.w;
				#endif
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
				return col;
				//half3 col_hdr = DecodeHDR(col, _MainTex_HDR);
				//return half4(col_hdr, 1);
			}
			ENDHLSL
		}
	}
}
