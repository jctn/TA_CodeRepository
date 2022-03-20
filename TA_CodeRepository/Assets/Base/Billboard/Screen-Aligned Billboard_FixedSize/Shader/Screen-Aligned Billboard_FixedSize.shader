Shader "Code Repository/Base/Screen-Aligned Billboard_FixedSize"
{
    Properties
    {
        _Color("Color(RGB)",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "gary"{}
		_Size("Size", Vector) = (2, 1, 0, 0)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Transparent"
        }
        
        //效果上，会跟随相机的z轴旋转，公告牌始终平行视平面，无论处于视图哪个位置都不会有畸形或形变，看起来有时反物理,在NDC空间，固定大小
        Pass
        {
            Tags 
            { 
                
            }
            
            Blend SrcAlpha OneMinusSrcAlpha,  One Zero
            Cull Off
            ZTest LEqual
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
			float4 _Size;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);       
            SAMPLER(sampler_MainTex); 

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv :TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv :TEXCOORD0;
            };
            
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
				if (_ProjectionParams.x < 0)
					v.uv.y = 1 - v.uv.y;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);

				float4 centerPosCS = TransformObjectToHClip(float3(0, 0, 0));
				centerPosCS /= centerPosCS.w; //结果：[-1, 1],centerPosCS.w = 1
				float ratio = _ScreenParams.x / _ScreenParams.y;
				float2 size = v.positionOS.xy * _Size.xy;
				size.x = size.x / ratio;		
				o.positionCS = centerPosCS;
				o.positionCS.xy += size;
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET 
            {    
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 c = _Color * mainTex;
                return c;
            }
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
