Shader "Code Repository/Base/DepthToWorldPosTemplate" 
{
	Properties 
	{
		[Enum(Self, 0, Way1, 1, Way2, 2, Way3, 3, Way4, 4)]_ShowWorldPosWay("ShowWorldPosWay", Float) = 0
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
			uint _ShowWorldPosWay;
			CBUFFER_END

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			//������Way1Ϊ��ʽ���ƣ��ʺ�Ͷ���������way2-way4ʵ�ʶ�����������������������������������������������������������ֻ꣬�ʺ�͸�������
			//way1����ps������˾���˷���
			//Way2:��ps��û�о���˷�
			//way3����ps��û�о���˷���
			//way4����ps��û�о���˷���
			//GetPosWOrtho,��������µ��󷨡�
			//�����ֻ��͸���������2-4�����ֻ�����������GetPosWOrtho�����׷��������1

			//world = M ^-1 * ndc * Clip.w
			//1 = world.w = (M ^-1 * ndc).w * Clip.w ==> Clip.w = 1/(M ^-1 * ndc).w
			//==>world = M ^-1 * ndc * (M ^-1 * ndc).w
			//https://blog.csdn.net/puppet_master/article/details/77489948
			float3 GetPosW1(float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				#if UNITY_REVERSED_Z
					depthTextureValue = 1 - depthTextureValue;
				#endif
				float4 ndc = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, depthTextureValue * 2 - 1, 1); //unity ndc z[-1, 1]
				float4 worldSpacePos = mul(UNITY_MATRIX_I_V, mul(unity_CameraInvProjection, ndc));
				worldSpacePos /= worldSpacePos.w;
				return worldSpacePos.xyz;
			}
			
			//https://zhuanlan.zhihu.com/p/92315967 ���������������㵽far plane������,ͨ�����������εõ����������������
			float3 GetPosW2(float3 farRayWS, float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float normalDepth = Linear01Depth(depthTextureValue, _ZBufferParams); //_ZBufferParams������תz�Ĳ�����Linear01Depthֻ������Ͷ�����
				float3 worldSpacePos = _WorldSpaceCameraPos + farRayWS * normalDepth; //����������
				return worldSpacePos;
			}

			//�������������㵽far plane������,ͨ�����������εõ�������������������������NDC1�ķ�ʽ
			float3 GetPosW3(float3 farRayWS, float2 screenPos)
			{
				return GetPosW2(farRayWS, screenPos);
			}

			//https://zhuanlan.zhihu.com/p/92315967 ,������ռ����ؽ��ķ�ʽ
			float3 GetPosW4(float3 rayWS, float viewZ, float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float eyeDepth = LinearEyeDepth(depthTextureValue, _ZBufferParams); //_ZBufferParams������תz�Ĳ�����LinearEyeDepthֻ������Ͷ�����
				float3 targetRayWS = -(eyeDepth / viewZ) * rayWS; //targetRayWS/rayWS = eyeDepth / viewZ,����������
				float3 worldSpacePos = _WorldSpaceCameraPos + targetRayWS;
				return worldSpacePos;
			}

			float3 GetPosWOrtho(float2 screenPos)
			{
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				#if UNITY_REVERSED_Z
					depthTextureValue = 1 - depthTextureValue;
				#endif
				float zView = -lerp(_ProjectionParams.y, _ProjectionParams.z, depthTextureValue);
				float2 xyView = (screenPos.xy * 2 - 1) * unity_OrthoParams.xy;
				float4 posView = float4(xyView, zView, 1);
				return mul(UNITY_MATRIX_I_V, posView).xyz;
			}
		ENDHLSL

		Pass {
			Name "Unlit"
			Tags { "LightMode"="SRPDefaultUnlit" }

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			// Structs
			struct Attributes 
			{
				float4 positionOS	: POSITION;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float3 positionWS	: TEXCOORD0;
				float4 positionSS	: TEXCOORD1;
				float3 farRayWS		: TEXCOORD2;//�����������㵽far plane������
				float3 rayWS		: TEXCOORD3;//�������ǰ���������
				float posZView		: TEXCOORD4;//��ǰ����۲�ռ�zֵ
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			Varyings UnlitPassVertex(Attributes IN) 
			{
				Varyings OUT = (Varyings)0;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);

				if(_ShowWorldPosWay == 2)
				{
					float2 screenPos = OUT.positionSS.xy / OUT.positionSS.w;
					float3 farPlaneNDC = float3(screenPos.x * 2 - 1, screenPos.y * 2 - 1, 1);
					float3 farPlaneClip = farPlaneNDC * _ProjectionParams.z;//��͸��ͶӰ�У�Զƽ���clip.w = _ProjectionParams.z����׶��far)���õ�λ��clip�ռ�ĵ�
					OUT.farRayWS = mul((float3x3)UNITY_MATRIX_I_V, mul(unity_CameraInvProjection, farPlaneClip.xyzz).xyz).xyz;//�õ�ָ��far plane������
				}
				else if(_ShowWorldPosWay == 3)
				{
					float2 screenPos = OUT.positionSS.xy / OUT.positionSS.w;
					float4 farPlaneNDC = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, 1, 1);
					float4 farPosWS = mul(UNITY_MATRIX_I_V, mul(unity_CameraInvProjection, farPlaneNDC));
					farPosWS /= farPosWS.w;
					OUT.farRayWS = farPosWS.xyz - _WorldSpaceCameraPos.xyz;//�õ�ָ��far plane������
				}
				else if(_ShowWorldPosWay == 4)
				{
					OUT.rayWS =  TransformObjectToWorld(IN.positionOS.xyz) - _WorldSpaceCameraPos;
					OUT.posZView = TransformWorldToViewDir(OUT.rayWS).z;
				}
				return OUT;
			}

			half4 UnlitPassFragment(Varyings IN) : SV_Target 
			{
				if(_ShowWorldPosWay == 1)
				{
					return half4(GetPosW1(IN.positionSS.xy/IN.positionSS.w), 1);
				}
				else if(_ShowWorldPosWay == 2)
				{
					float3 posInOrtho = GetPosWOrtho(IN.positionSS.xy/IN.positionSS.w);	
					float3 posInPers = GetPosW2(IN.farRayWS, IN.positionSS.xy/IN.positionSS.w);
					return half4(lerp(posInPers, posInOrtho, unity_OrthoParams.w), 1);
				}
				else if(_ShowWorldPosWay == 3)
				{
					float3 posInOrtho = GetPosWOrtho(IN.positionSS.xy/IN.positionSS.w);	
					float3 posInPers = GetPosW3(IN.farRayWS, IN.positionSS.xy/IN.positionSS.w);
					return half4(lerp(posInPers, posInOrtho, unity_OrthoParams.w), 1);
				}
				else if(_ShowWorldPosWay == 4)
				{
					float3 posInOrtho = GetPosWOrtho(IN.positionSS.xy/IN.positionSS.w);	
					float3 posInPers = GetPosW4(IN.rayWS, IN.posZView, IN.positionSS.xy/IN.positionSS.w);
					return half4(lerp(posInPers, posInOrtho, unity_OrthoParams.w), 1);
				}
				return half4(IN.positionWS, 1);
			}
			ENDHLSL
		}
	}
}