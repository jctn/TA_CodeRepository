Shader "Code Repository/ParticleCloud/ParticleCloud"
{
    Properties
    {
		[HDR]_OutLineColor("OutLineColor", Color) = (1, 1, 1, 1)
		[HDR]_CloudColor("CloudColor", Color) = (1, 1, 1, 1)
	    _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	    _EdgeIntensity ("Edge Intensity", Range(0, 5)) = 2
		_LightIntensity("Light Intensity", Range(0, 5)) = 1.5
		_Permeability("通透度", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}          

            Blend  One One, One Zero
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
            struct appdata_t 
            {
		        float2 texcoord : TEXCOORD0;
		        float4 vertex : POSITION;
		        half4 color: COLOR;
            };
 
            struct v2f 
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 scrPos : TEXCOORD1;
                half4 color: COLOR;
            };
       
            CBUFFER_START(UnityPerMaterial)
	        half _EdgeIntensity; 
            float4 _MainTex_ST;
			half4 _OutLineColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);  

            TEXTURE2D(_EdgeTex);
            SAMPLER(sampler_EdgeTex);  

	        v2f vert (appdata_t v)
	        {
		        v2f o;
		        o.vertex = TransformObjectToHClip(v.vertex.xyz);
		        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
		        o.scrPos = ComputeScreenPos(o.vertex);
		        o.color = v.color;
		        return o;
	        }   

	        half4 frag (v2f i) : SV_Target
	        {
		        half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy);
		        col.rgb = 0;
		        col.a *= i.color.a;
		        half4 edgeLit = SAMPLE_TEXTURE2D(_EdgeTex, sampler_EdgeTex, i.scrPos.xy / i.scrPos.w);;
		        col.rgb = edgeLit.rgb * col.a * _EdgeIntensity * _OutLineColor.rgb;
		        return col;
	        }
            ENDHLSL 
        }   

        Pass 
        {
            Blend SrcAlpha OneMinusSrcAlpha  
            ZWrite Off
            Tags{"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
            struct appdata_t 
            {
			    float2 texcoord : TEXCOORD0;
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			    half4 color: COLOR;
            };
 
            struct v2f 
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float2 cap : TEXCOORD1;
                float4 scrPos : TEXCOORD2;
                half4 color: COLOR;
            };
       
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
			half4 _CloudColor;
			half _LightIntensity;
			half _Permeability;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);  

            TEXTURE2D(_LightMatCap);
            SAMPLER(sampler_LightMatCap);  

            TEXTURE2D(_EdgeTex);
            SAMPLER(sampler_EdgeTex);  

            TEXTURE2D(_CloudFogTex);
            SAMPLER(sampler_CloudFogTex); 

		    v2f vert (appdata_t v)
		    {
			    v2f o;
			    o.vertex = TransformObjectToHClip(v.vertex.xyz);
			    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);				
			    float3 worldNorm = TransformObjectToWorldNormal(v.normal.xyz);
			    float3 viewNormal = TransformWorldToViewDir(worldNorm);
			    o.cap.xy = viewNormal.xy * 0.5 + 0.5;
			    o.scrPos = ComputeScreenPos(o.vertex);       
			    o.color = v.color;
			    return o;
		    }

		    half4 frag (v2f i) : SV_Target
		    {
                float2 scuv = i.scrPos.xy / i.scrPos.w;
				half4 mc = SAMPLE_TEXTURE2D(_LightMatCap, sampler_LightMatCap, i.cap) * _LightIntensity;
			    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy) * _CloudColor;
			    half4 edgeLit = SAMPLE_TEXTURE2D(_EdgeTex, sampler_EdgeTex, scuv);
				col.rgb = col.rgb * i.color.rgb * mc.rgb;
			    col.a *= i.color.a;
			    half4 fogCol = SAMPLE_TEXTURE2D(_CloudFogTex, sampler_CloudFogTex, scuv);
			    col.rgb = lerp(col.rgb, fogCol.rgb, saturate(edgeLit.r * _Permeability));	
		 	    return col;
		    }
            ENDHLSL
        }
    }
}