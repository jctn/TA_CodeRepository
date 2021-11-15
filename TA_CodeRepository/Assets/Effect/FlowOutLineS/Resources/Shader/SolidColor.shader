Shader "SaintSeiya2/Effect/FlowOutLineS/SolidColor"
{
    Properties
	{
		[HDR]_SolidColor("_SolidColor", Color) = (1, 1, 1, 1)
        _SolidColorHDRFactor("_SolidColorHDR模拟", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
        [Enum(Off, 0, On, 1)]_ZWrite("_ZWrite", Float) = 1
        _ColorMask("_ColorMask", Float) = 15
        [HideInInspector]_Scale("_Scale",Float) = 0.01
	}

    SubShader
    {
        Blend One Zero,One Zero
        ZTest[_ZTest]
        ZWrite[_ZWrite]
        Pass
        {
            ColorMask[_ColorMask]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

			CBUFFER_START(UnityPerMaterial)
			float4  _SolidColor;
            float _SolidColorHDRFactor;
			CBUFFER_END

            v2f vert (appdata v)
            {
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 finalColor = _SolidColor.rgb * pow(2,_SolidColorHDRFactor);
                return float4(finalColor, _SolidColor.a);
            }
            ENDHLSL
        }

        //如果添加外发光的物体有外扩描边，且不希望外发光挡住外描边，须把pass替换为同样算法的外扩描边算法
        Pass
        {
            ColorMask[_ColorMask]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

			CBUFFER_START(UnityPerMaterial)
			float4  _SolidColor;
            float _SolidColorHDRFactor;
			CBUFFER_END

            v2f vert (appdata v)
            {
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 finalColor = _SolidColor.rgb * pow(2,_SolidColorHDRFactor);
                return float4(finalColor, _SolidColor.a);
            }
            ENDHLSL
        }
    }
}
