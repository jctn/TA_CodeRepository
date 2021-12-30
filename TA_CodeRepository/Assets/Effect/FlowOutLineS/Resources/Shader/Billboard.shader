Shader "Code Repository/Effect/FlowOutLineS/Billboard"
{
    Properties
	{
		_FlowOutLineColor("FlowOutLineColor", Color) = (1, 1, 1, 1)
        _ColorHDRFactor("ColorHDR模拟", Float) = 0		
        _NoiseTex("_NoiseTex", 2D) = "white" {}
        _DistortFactor("xy=Range, zw=strength", Vector) = (0, 1, 0, 1)
        _DistortTimeFactor("_DistortTimeFactor", Float) = 1
        _MsakTexMask("_MsakTexMask", Vector) = (0, 0, 0, 0)
        _NoiseTex_TO("_NoiseTex_TO", Vector) = (0, 0, 0, 0)
        _BillboardSize("_BillboardSize", Vector) = (3, 4, 0, 0)
        _AlphaFactor("_AlphaFactor", Float) = 1
        //[Enum(UnityEngine.Rendering.BlendMode)]_BillboardSrcBlend("SrcBlend", Float) = 5
        //[Enum(UnityEngine.Rendering.BlendMode)]_BillboardDstBlend("DstBlend", Float) = 10
        [Enum(On, 1, Off, 0)]_BillboardZTest("ZTest", Float) = 1
	}

    SubShader
    {   
        Tags {"Queue" = "Transparent" "DisableBatching" = "True" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            //Blend[_BillboardSrcBlend][_BillboardDstBlend]
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
            float4 _DistortFactor;
            float _DistortTimeFactor;
            float4 _NoiseTex_TO;
            float4 _MsakTexMask;
            float2 _BillboardSize;
            half _AlphaFactor;
			CBUFFER_END

            v2f vert (appdata v)
            {
				v2f o;
                o.vertex = TransformWViewToHClip(TransformWorldToView(TransformObjectToWorld(float3(0 , 0, 0))) + float3(v.vertex.x * _BillboardSize.x, v.vertex.y * _BillboardSize.y, 0.0));
                o.uv = ComputeScreenPos (o.vertex);
                o.uv1 = v.uv * _NoiseTex_TO.xy + _NoiseTex_TO.zw;
                o.uv1.y -= _Time.y * _DistortTimeFactor;
				return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.uv.xy / i.uv.w;
                //float2 newUV = screenUV * _NoiseTex_TO.xy + _NoiseTex_TO.zw;
				//newUV.y -= _Time.y * _DistortTimeFactor;
				float2 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1).rg;
				noise *= _DistortFactor.xy;

				float2 uv = screenUV;
				uv.xy -= noise;
				uv.xy = lerp(screenUV, uv, _DistortFactor.zw);

                half4 maskColor = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, screenUV);
                half4 blurColor = SAMPLE_TEXTURE2D(_TemporaryRT0, sampler_TemporaryRT0, uv);
                half maskValue = dot(maskColor, _MsakTexMask);
				half outlineValue = dot(blurColor, _MsakTexMask);
				half4 outlineColor = half4(_FlowOutLineColor.rgb * pow(2, _ColorHDRFactor), _FlowOutLineColor.a) * outlineValue;
                //return distortColor * step(maskValue, 0);
                half4 c = outlineColor * step(maskValue, 0);
                c.a = clamp(0, 1, c.a * _AlphaFactor);
                return c;
            }
            ENDHLSL
        }
    }
}
