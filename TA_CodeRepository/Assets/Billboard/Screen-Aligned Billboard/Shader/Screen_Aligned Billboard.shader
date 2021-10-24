﻿Shader "Code Repository/Screen_Aligned Billboard"
{
    Properties
    {
        _Color("Color(RGB)",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "gary"{}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Transparent"
        }
        
        Pass
        {
            Tags 
            { 
                
            }
            
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha,  One Zero
            Cull Back
            ZTest LEqual
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;  
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
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				//Billboard
				float3 posNewOS = mul((float3x3)UNITY_MATRIX_M, v.positionOS); //新空间下局部坐标
				float3 centerPosVS = TransformWorldToView(TransformObjectToWorld(float3(0, 0, 0)));	
				//[right,up,foward],新空间的标准正交基。
				//Screen_Aligned Billboard下,与相机的view plane对齐。
				//up-相机up，right-相机right，forward-相机forwad
				float3 right = float3(1, 0, 0);
				float3 up = float3(0, 1, 0);
				float3 forward = float3(0, 0, 1);
				float3x3 newViewMatrix = float3x3(right, up, forward);
				newViewMatrix = transpose(newViewMatrix);

				float3 posVS_NoTranslation = mul(newViewMatrix, posNewOS);
				o.positionCS = TransformWViewToHClip(posVS_NoTranslation + centerPosVS);

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
