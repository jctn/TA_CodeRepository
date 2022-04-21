Shader "Code Repository/Scene/Stylized Dynamic Sky" 
{
	Properties 
	{
		[Header(SkyGradient)]
		_TopColor_Day("Day Top Color", Color) = (0.12, 0.64, 0.94, 1)
		_BottomColor_Day("Day Bottom Color", Color) = (0.65, 0.84, 0.95, 1)
		_TopColor_Night("Night Top Color", Color) = (0.4,1,1,1)
		_BottomColor_Night("Night Bottom Color", Color) = (0,0.8,1,1)
		_GradientScale ("Gradient Scale", Float) = 3

		[Header(Horizon)]
		_HorizonColor_Day ("Day Horizon Color", Color) = (0.12, 0.64, 0.94, 1)
		_HorizonHeight_Day ("Day Horizon Height", Float) = 0.1
		_HorizonSoft_Day ("Day Horizon Soft", Float) = 0.5
		_HorizonBrightness_Day("Day Horizon Brightness", Float) = 1	
		_HorizonColor_Night ("Night Horizon Color", Color) = (0.12, 0.64, 0.94, 1)
		_HorizonHeight_Night ("Night Horizon Height", Float) = 0.1
		_HorizonSoft_Night ("Night Horizon Soft", Float) = 0.5
		_HorizonBrightness_Night("Night Horizon Brightness", Float) = 1			
	}
	SubShader 
	{
		Tags 
		{
			"Queue"="Geometry"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			half4 _TopColor_Day, _BottomColor_Day, _BottomColor_Night, _TopColor_Night;
			float _GradientScale;
			half4 _HorizonColor_Day, _HorizonColor_Night;
			float _HorizonHeight_Day, _HorizonBrightness_Day, _HorizonSoft_Day, _HorizonHeight_Night, _HorizonBrightness_Night, _HorizonSoft_Night;
			CBUFFER_END
		ENDHLSL

		Pass 
		{
			Cull Off
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			struct Attributes 
			{
				float4 positionOS : POSITION;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 positionOS : TEXCOORD0;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionOS = IN.positionOS.xyz;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				//sky gradient
				float gradient = 1 - exp(-max(0, IN.positionOS.y) * _GradientScale);
				float3 gradientDay = lerp(_BottomColor_Day.rgb, _TopColor_Day.rgb, gradient);
				float3 gradientNight = lerp(_BottomColor_Night.rgb, _TopColor_Night.rgb, gradient);
				float3 gradientSky = lerp(gradientNight, gradientDay, saturate(_MainLightPosition.y));

				//sky horizon
				//强度变化
				float sunHeight = abs(_MainLightPosition.y);
				float horizonSunMaskDay = smoothstep(0, 0.2, sunHeight) + smoothstep(0.4, 0.2, sunHeight) - 1;
				float horizonSunMaskNight = smoothstep(0, 0.1, sunHeight) + smoothstep(0.2, 0.1, sunHeight) - 1;
				//范围限定
				float posHeight = abs(IN.positionOS.y);
				float horizonMaskDay = smoothstep(_HorizonHeight_Day * 0.1 + _HorizonSoft_Day * 0.1, 0, posHeight);
				float horizonNight = smoothstep(_HorizonHeight_Night * 0.1 + _HorizonSoft_Night * 0.1, 0, posHeight);
				//sky颜色
				half3 horizonSkyDay = _HorizonColor_Day.rgb * _HorizonBrightness_Day;
				half3 horizonSkyNight = _HorizonColor_Night.rgb * _HorizonBrightness_Night;

				float nightOrDay = step(0, _MainLightPosition.y);
				float horizonSunMask = lerp(horizonSunMaskNight, horizonSunMaskDay, nightOrDay);				
				float horizonMask = lerp(horizonNight, horizonMaskDay, nightOrDay);
				horizonMask *= horizonSunMask;
				half3 horizonSky = lerp(horizonSkyNight, horizonSkyDay, nightOrDay);

				half3 finalColor = (1 - horizonMask) * gradientSky + horizonMask * horizonSky;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}