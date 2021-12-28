// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code
Shader "Custom/URP_Unlit" 
{
	Properties 
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
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
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Unlit"
			//Tags { "LightMode"="SRPDefaultUnlit" } // (is default anyway)
			//Stencil
			//{
			//	Ref referenceValue //�ο�ֵ
			//	ReadMask  readMask  //��ȡ���룬ȡֵ��ΧҲ��0-255��������Ĭ��ֵΪ255��������λ11111111������ȡ��ʱ�򲻶�referenceValue��stencilBufferValue����Ч������ȡ�Ļ���ԭʼֵ,(ref & readMask) comparisonFunction (stencilBufferValue & readMask)
			//	WriteMask writeMask  //������룬��д��ģ�建��ʱ���������������λ�롾&������writeMaskȡֵ��Χ��0-255��������Ĭ��ֵҲ��255�������޸�stencilBufferValueֵʱ��д�����Ȼ��ԭʼֵ
			//	Comp comparisonFunction  //�������ؼ����У�Greater��>����GEqual��>=����Less��<����LEqual��<=����Equal��=����NotEqual��!=����Always���������㣩��Never�����ǲ����㣩
			//	Pass stencilOperation  //���������Ĵ���Keep��Invert
			//	Fail stencilOperation  //�����������Ĵ���
			//	ZFail stencilOperation  //��Ȳ���ʧ�ܺ�Ĵ���
			//}
			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
			};

			// Textures, Samplers & Global Properties
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			// Vertex Shader
			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				// Or :
				//OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

				return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}
	}
}