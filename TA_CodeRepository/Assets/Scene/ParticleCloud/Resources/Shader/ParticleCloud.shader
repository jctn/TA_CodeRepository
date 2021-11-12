Shader "Unlit/ParticleCloud"
{
    Properties
    {
		[HDR]_OutLineColor("OutLineColor", Color) = (1, 1, 1, 1)
		[HDR]_CloudColor("CloudColor", Color) = (1, 1, 1, 1)
	    _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	    _EdgeIntensity ("Edge Intensity", Float) = 2
		_LightIntensity("Light Intensity", Float) = 1.5
		_Permeability("通透度", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}          

            Blend  One One, One Zero
            //Blend  OneMinusDstColor One, One Zero
			//Blend  One OneMinusSrcColor, One Zero
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            struct appdata_t 
            {
		        fixed2 texcoord : TEXCOORD0;
		        fixed4 vertex : POSITION;
		        fixed4 color: COLOR;
            };
 
            struct v2f 
            {
                float4 vertex : SV_POSITION;
                fixed2 texcoord : TEXCOORD0;
                fixed4 scrPos : TEXCOORD1;
                fixed4 color: COLOR;
            };
       
	        sampler2D _MainTex; 
	        half _EdgeIntensity; 
            sampler2D _EdgeTex;
            float4 _MainTex_ST;
			half4 _OutLineColor;

	        v2f vert (appdata_t v)
	        {
		        v2f o;
		        o.vertex = UnityObjectToClipPos(v.vertex);
		        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
		        o.scrPos = ComputeScreenPos(o.vertex);
		        o.color = v.color;
		        return o;
	        }   

	        half4 frag (v2f i) : SV_Target
	        {
		        half4 col = tex2D(_MainTex, i.texcoord.xy);
		        col.rgb = 0;
		        col.a *= i.color.a;
		        half4 edgeLit = tex2D(_EdgeTex, i.scrPos.xy / i.scrPos.w);	
		        col.rgb = edgeLit.rgb * col.a * _EdgeIntensity * _OutLineColor.rgb;
		        return col;
	        }
            ENDCG
        }   

        Pass 
        {
            Blend SrcAlpha OneMinusSrcAlpha  
            ZWrite Off
            Tags{"LightMode" = "SRPDefaultUnlit"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
 
            struct appdata_t 
            {
			    fixed2 texcoord : TEXCOORD0;
			    fixed4 vertex : POSITION;
			    fixed4 normal : NORMAL;
			    fixed4 color: COLOR;
            };
 
            struct v2f 
            {
                float4 vertex : SV_POSITION;
                fixed2 texcoord : TEXCOORD0;
                fixed2 cap : TEXCOORD3;
                fixed4 scrPos : TEXCOORD2;
                fixed4 color: COLOR;
            };
       
            sampler2D _MainTex;
            sampler2D _LightMatCap;
            sampler2D _EdgeTex;
			sampler2D _CloudFogTex;
            float4 _MainTex_ST;
			half4 _CloudColor;
			half _LightIntensity;
			half _Permeability;

		    v2f vert (appdata_t v)
		    {
			    v2f o;
			    o.vertex = UnityObjectToClipPos(v.vertex);
			    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			    fixed2 capCoord;					
			    fixed3 worldNorm = normalize(unity_WorldToObject[0].xyz * v.normal.x + unity_WorldToObject[1].xyz * v.normal.y + unity_WorldToObject[2].xyz * v.normal.z);
			    worldNorm = mul((fixed3x3)UNITY_MATRIX_V, worldNorm);
			    o.cap.xy = worldNorm.xy * 0.5 + 0.5;
			    o.scrPos = ComputeScreenPos(o.vertex);       
			    o.color = v.color;
			    return o;
		    }

		    half4 frag (v2f i) : SV_Target
		    {
				half4 mc = tex2D(_LightMatCap, i.cap) * _LightIntensity;
			    half4 col = tex2D(_MainTex, i.texcoord.xy) * _CloudColor;
			    half4 edgeLit = tex2D(_EdgeTex, i.scrPos.xy / i.scrPos.w);
				col.rgb = col.rgb * i.color * mc.rgb;
			    col.a *= i.color.a;
			    half4 fogCol = tex2D(_CloudFogTex, i.scrPos.xy / i.scrPos.w);	
			    col.rgb = lerp(col.rgb, fogCol.rgb, saturate(edgeLit.r * _Permeability));	
		 	    return col;
		    }
            ENDCG
        }
    }
}
