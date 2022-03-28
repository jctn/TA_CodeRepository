Shader "ParticleLocalPosTest" 
{
	Properties 
	{

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
			#define MAX_PARTICLE_COUNT 10
		ENDHLSL

		Pass {
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float particleIdnex	: TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float3 posOS		: TEXCOORD1;
			};


			float4x4 M[MAX_PARTICLE_COUNT];
			float4x4 IM[MAX_PARTICLE_COUNT];

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.posOS = mul(IM[IN.particleIdnex], IN.positionOS).xyz; //得到局部坐标系，可以做顶点动画
				//OUT.posOS = IN.positionOS;
				//OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				IN.positionOS = mul(M[IN.particleIdnex], float4(OUT.posOS.xyz, 1));
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				return half4(IN.posOS, 1);
			}
			ENDHLSL
		}
	}
}