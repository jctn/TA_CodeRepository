Shader "Hidden/AfterImage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex("MaskTex", 2D) = "white" {}
        _AfterImageRT("Texture", 2D) = "white" {}
        _AfterImageIntensity("残影亮度", Range(0, 1)) = 0.5
        _AfterImageRemoveSpeed("残影消散速度", Range(0, 1)) = 0.1
        _BlurRadius("模糊半径", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        //0,遮罩pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return half4(1, 0, 0, 1);
            }
            ENDCG
        }

        //1,扣取人物pass
        Pass
        {
            Blend One OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            float _AfterImageRemoveSpeed;
            float _IsWriteAfterImage; //控制残影写入残影RT

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                half maskCol = tex2D(_MaskTex, i.uv).r * _IsWriteAfterImage;
                col = col * maskCol;
                col.a = _AfterImageRemoveSpeed;
                return col;
            }
            ENDCG
        }

        //2,混合pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _AfterImageRT;
            float4 _AfterImageRT_TexelSize;
            float _AfterImageIntensity;
            sampler2D _MaskTex;
            float _BlurRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half3 SimpleBlur(sampler2D tex, float2 uv)
            {
                half3 col = tex2D(tex, uv).rgb;
                col += tex2D(tex, uv + _BlurRadius * _AfterImageRT_TexelSize.xy * float2(1, 1)).rgb;
                col += tex2D(tex, uv + _BlurRadius * _AfterImageRT_TexelSize.xy * float2(-1, 1)).rgb;
                col += tex2D(tex, uv + _BlurRadius * _AfterImageRT_TexelSize.xy * float2(-1, -1)).rgb;
                col += tex2D(tex, uv + _BlurRadius * _AfterImageRT_TexelSize.xy * float2(1, -1)).rgb;
                col *= 0.2;
                return col;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                half3 afterImageCol = SimpleBlur(_AfterImageRT, i.uv).rgb;
                half maskCol = tex2D(_MaskTex, i.uv).r;
                afterImageCol *= (1 - maskCol);
                col= half4(col.rgb + afterImageCol * _AfterImageIntensity, col.a);
                return col;
            }
            ENDCG
        }
    }
}
