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
		_HorizonColor ("Horizon Color", Color) = (0.12, 0.64, 0.94, 1)
		_HorizonHeight ("Horizon Height", Float) = 0.1
		_HorizonSoft ("Horizon Soft", Float) = 0.5
		_HorizonBrightness("Horizon Brightness", Float) = 1		
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
			half4 _HorizonColor;
			float _HorizonHeight, _HorizonBrightness, _HorizonSoft;
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
				float horizonSunMask = smoothstep(_HorizonHeight * 0.1 + _HorizonSoft * 0.1, 0, max(0, _MainLightPosition.y));
				float horizonMask = smoothstep(_HorizonHeight * 0.1 + _HorizonSoft * 0.1, 0, abs(IN.positionOS.y));
				horizonMask *= horizonSunMask;				
				half3 horizonSky = _HorizonColor.rgb * _HorizonBrightness;

				half3 finalColor = (1 - horizonMask) * gradientSky + horizonMask * horizonSky;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}