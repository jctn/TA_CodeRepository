Shader "Code Repository/Effect/FlowOutLineS/Billboard"
{
    Properties
	{
		[HDR]_FlowOutLineColor("FlowOutLineColor", Color) = (1, 1, 1, 1)
        _ColorHDRFactor("ColorHDR模拟", Float) = 0	
        _AlphaFactor("_AlphaFactor", Float) = 1        
        _DistortFactor("xy=Range, zw=strength", Vector) = (0, 1, 0, 1)
        //_MsakTexMask("_MsakTexMask", Vector) = (0, 0, 0, 0)
        _OpenMask("OpenMask", Int) = 1
        _NoiseTex("_NoiseTex", 2D) = "white" {}
        _NoiseTex_TO("_NoiseTex_TO", Vector) = (0, 0, 0, 0)
        _RotationAndFlow("RotationAndFlow", Vector) = (0, 0, 1, 0.5)
        _DebugNoise ("DebugNoise", Int) = 0
        _BillboardSize("_BillboardSize", Vector) = (3, 4, 0, 0)
        [Enum(On, 4, Off, 8)]_BillboardZTest("ZTest", Float) = 4
        _SceneIndex("SceneIndex", Int) = 0
	}

    SubShader
    {   
        Tags {"Queue" = "Transparent" "DisableBatching" = "True" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest[_BillboardZTest]
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

			TEXTURE2D(_TemporaryRT0);            
			SAMPLER(sampler_TemporaryRT0);

			TEXTURE2D(_MaskTex);            
			SAMPLER(sampler_MaskTex);

			TEXTURE2D(_NoiseTex);            
			SAMPLER(sampler_NoiseTex);

			CBUFFER_START(UnityPerMaterial)
			half4 _FlowOutLineColor;
			float _ColorHDRFactor;
            half _AlphaFactor;
            float4 _DistortFactor;
            int _OpenMask;
            float4 _NoiseTex_TO;
            float4 _RotationAndFlow; //rotation, flowdir, floawSpeed
            int _DebugNoise;
            //float4 _MsakTexMask;            
            float2 _BillboardSize;
            int _SceneIndex;
			CBUFFER_END

            #define MAX_FLOWITEM_COUNT 8
            float4 _MsakTexMasks[MAX_FLOWITEM_COUNT];

            v2f vert (appdata v)
            {
				v2f o;
                o.vertex = TransformWViewToHClip(TransformWorldToView(TransformObjectToWorld(float3(0 , 0, 0))) + float3(v.vertex.x * _BillboardSize.x, v.vertex.y * _BillboardSize.y, 0.0));
                o.uv = ComputeScreenPos (o.vertex);
                o.uv1 = v.uv;
                //流动
                float dp2 = max(FLT_MIN, dot(_RotationAndFlow.yz, _RotationAndFlow.yz));
                float2 dir = _RotationAndFlow.yz * rsqrt(dp2);
                o.uv1 -= _Time.y * _RotationAndFlow.w * 0.5 * dir;
                //旋转
                float radianR = _RotationAndFlow.x * PI / 180;
                float cosR = cos(radianR);
                float sinR = sin(radianR);
                float2x2 rMatrix = float2x2(cosR, -sinR, sinR, cosR);
                o.uv1 = mul(rMatrix, o.uv1 - float2(0.5, 0.5)) + float2(0.5, 0.5);
                //tilling offset
                o.uv1 = o.uv1 * _NoiseTex_TO.xy + _NoiseTex_TO.zw;
				return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.uv.xy / i.uv.w;
				half2 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1).rg;
                half4 noiseCol = half4(noise.x, noise.x, noise.x, 1);
				noise *= _DistortFactor.xy;

				float2 uv = screenUV;
				uv.xy -= noise;
				uv.xy = lerp(screenUV, uv, _DistortFactor.zw);

                half4 maskColor = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, screenUV);
                half4 blurColor = SAMPLE_TEXTURE2D(_TemporaryRT0, sampler_TemporaryRT0, uv);
                half maskValue = dot(maskColor, _MsakTexMasks[_SceneIndex]);
				half outlineValue = dot(blurColor, _MsakTexMasks[_SceneIndex]);
				//half4 outlineColor = half4(_FlowOutLineColor.rgb * pow(2, _ColorHDRFactor), _FlowOutLineColor.a) * outlineValue;
                half4 outlineColor = half4(_FlowOutLineColor.rgb * pow(2, _ColorHDRFactor), _FlowOutLineColor.a * outlineValue);
                outlineColor.a = clamp(0, 1, outlineColor.a * _AlphaFactor);
                outlineColor.a *= lerp(1, step(maskValue, 0), _OpenMask);

                half4 finalCol = lerp(outlineColor, noiseCol, _DebugNoise);
                return finalCol;
            }
            ENDHLSL
        }
    }
}
