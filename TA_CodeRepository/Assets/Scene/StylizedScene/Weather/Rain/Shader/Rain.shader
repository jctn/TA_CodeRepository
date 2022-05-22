Shader "Code Repository/Scene/Rain" 
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

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			half3 _RainColor;
			float4 _RainScale_Layer12;
			float4 _RainScale_Layer34;
			float4 _RotateSpeed;
			float4 _RotateAmount;
			float4 _DropSpeed;
			float4 _RainDepthStart;
			float4 _RainDepthRange;

			float4x4 _SceneDepthCamMatrixVP;

			TEXTURE2D(_RainHeightmap);
			SAMPLER(sampler_RainHeightmap);

			TEXTURE2D(_DistortionTexture);
			SAMPLER(sampler_DistortionTexture);

			TEXTURE2D(_NoiseTexture);
			SAMPLER(sampler_NoiseTexture);			
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			//SAMPLER(sampler_linear_repeat).

			TEXTURE2D(_RainShapeTex);
			SAMPLER(sampler_RainShapeTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_SceneDepthTex);
			SAMPLER(sampler_SceneDepthTex);

			float CalcSceneDepth(float4 screenPosition)
			{
				float2 screenPos = screenPosition.xy / screenPosition.w;
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float eyeDepth = LinearEyeDepth(depthTextureValue, _ZBufferParams);
				return eyeDepth;
			}

			float RainHeightDepthMapTest(float3 virtualPosWS)
			{
				float4 posCS = mul(_SceneDepthCamMatrixVP, float4(virtualPosWS, 1.0));
				float3 posNDC = 0.5 * posCS.xyz / posCS.w + 0.5;
				float sceneDepth = SAMPLE_TEXTURE2D(_SceneDepthTex, sampler_SceneDepthTex, posNDC.xy).r;
				#if UNITY_REVERSED_Z
					sceneDepth = 1.0 - sceneDepth;
				#endif
				return step(posNDC.z, sceneDepth - 0.02);
			}
		ENDHLSL

		Pass
		{
			Name "Rain Mask"

			//Cull Off
			//ZWrite Off
			//ZTest Always

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 UV				: TEXCOORD0;	
				float4 UVLayer12		: TEXCOORD1;
				float4 UVLayer34		: TEXCOORD2;
				//float4 DistoUV			: TEXCOORD3;
				//float4 BlendUV			: TEXCOORD4;
				float4 ScreenPosition	: TEXCOORD5;
				float4 ViewDirVS		: TEXCOORD6;
				float3 posWS : TEXCOORD7;
				float3 posOS : TEXCOORD8;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.UV = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;


				OUT.ScreenPosition = ComputeScreenPos(OUT.positionCS);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 posVS = TransformWorldToView(posWS);
				OUT.ViewDirVS.xyz = posWS - _WorldSpaceCameraPos.xyz;
				OUT.ViewDirVS.w = -posVS.z;
				OUT.posWS = posWS;
				OUT.posOS = IN.positionOS.xyz;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				////// Layer 3
				////float2 NoiseUV = SAMPLE_TEXTURE2D(_DistortionTexture, sampler_DistortionTexture, IN.DistoUV.xy).rg + SAMPLE_TEXTURE2D(_DistortionTexture, sampler_DistortionTexture, IN.DistoUV.zw).rg;
				////NoiseUV = NoiseUV * IN.UV.y * 2.0f + float2(1.5f, 0.7f) * IN.UV.xy + float2(0.1f, -0.2f) * _Time.yy;
				////float LayerMask3 = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,  NoiseUV) + 0.32f;
				////LayerMask3 = saturate(pow(2.0f * LayerMask3, 2.95f) * 0.6f);

				////// Layer 4
				////float LayerMask4 = tex2D(NoiseTexture, BlendUV.xy)
				////				   + tex2D(NoiseTexture, BlendUV.zw) + 0.37f;

				// Layers12 view depth test
				float backDepthVS = CalcSceneDepth(IN.ScreenPosition);
				float2 virtualDepth = 0;
				virtualDepth.x = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer12.xy).r * _RainDepthRange.x + _RainDepthStart.x + 0.01;
				virtualDepth.y = SAMPLE_TEXTURE2D(_RainHeightmap, sampler_RainHeightmap, IN.UVLayer12.zw).r * _RainDepthRange.z + _RainDepthStart.y;
				float2 occlusionDistance = step(virtualDepth, backDepthVS - 0.2);

				// Calc layers12 virtual position
				float2 depthRatio = virtualDepth / IN.ViewDirVS.z;
				float3 virtualPosition1WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.x;
				float3 virtualPosition2WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.y;

				// Layers12 heigth depth test
				float2 occlusionHeight = 0;
				occlusionHeight.x = RainHeightDepthMapTest(virtualPosition1WS);
				occlusionHeight.y = RainHeightDepthMapTest(virtualPosition2WS);

				half4 maskColor = float4(occlusionDistance * occlusionHeight, 0, 0);
				return maskColor;
			}
			ENDHLSL
		}

		//Pass
		//{
		//	Name "Rain Merge"
		//	HLSLPROGRAM
		//	#pragma vertex vertex
		//	#pragma fragment fragment

		//	struct Attributes 
		//	{
		//		float4 positionOS	: POSITION;
		//		float2 uv		    : TEXCOORD0;
		//	};

		//	struct Varyings 
		//	{
		//		float4 positionCS 	: SV_POSITION;
		//		float2 uv			: TEXCOORD0;	
		//		float4 UVLayer12	: TEXCOORD1;
		//		float4 UVLayer34	: TEXCOORD2;
		//	};

		//	Varyings vertex(Attributes IN) 
		//	{
		//		Varyings OUT;
		//		OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
		//		OUT.uv = IN.uv;

		//		float4 UVLayer12 = IN.uv.xyxy;
		//		float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
		//		float4 Cosines = float4(cos(SinT), sin(SinT));
		//		float4 CenteredUV = UVLayer12 - 0.5;
		//		float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
		//								 , dot(Cosines.zx, CenteredUV.xy)
		//								 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
		//								 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
		//		UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
		//		UVLayer12 *= _RainScale_Layer12;
		//		OUT.UVLayer12 = UVLayer12;

		//		float4 UVLayer34 = IN.uv.xyxy;
		//		SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
		//		Cosines = float4(cos(SinT), sin(SinT));
		//		CenteredUV = UVLayer34 - 0.5;
		//		RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
		//								 , dot(Cosines.zx, CenteredUV.xy)
		//								 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
		//								 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
		//		UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
		//		UVLayer34 *= _RainScale_Layer34;
		//		OUT.UVLayer34 = UVLayer34;
		//		return OUT;
		//	}

		//	half4 fragment(Varyings IN) : SV_Target 
		//	{
		//		half4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

		//		half4 mask = 1;

		//		half4 layer = 0;
		//		layer.x = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.xy).r;
		//		layer.y = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.zw).r;
		//		layer.z = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.xy).r;
		//		layer.w = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.zw).r;

		//		half rainShape = dot(layer, mask);
		//		rainShape = saturate(rainShape);

		//		half3 finalColor = lerp(mainTexColor.rgb, _RainColor, rainShape);
		//		return half4(finalColor, mainTexColor.a);
		//	}
		//	ENDHLSL
		//}
	}
}