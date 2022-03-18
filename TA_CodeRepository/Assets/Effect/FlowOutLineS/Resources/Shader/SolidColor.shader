Shader "Code Repository/Effect/FlowOutLineS/SolidColor"
{
    Properties
	{
		_SolidColor("_SolidColor", Color) = (1, 1, 1, 1)
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
        [Enum(Off, 0, On, 1)]_ZWrite("_ZWrite", Float) = 1
        _ColorMask("_ColorMask", Float) = 15
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
			half4  _SolidColor;
			CBUFFER_END

            v2f vert (appdata v)
            {
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				return _SolidColor;
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
			half4  _SolidColor;
			CBUFFER_END

            v2f vert (appdata v)
            {
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				return _SolidColor;
            }
            ENDHLSL
        }
    }
}
