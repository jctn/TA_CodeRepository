Shader "Code Repository/ParticleCloud/MatCapSpher_Tex"
{
    Properties
    {
    }

    SubShader
    {
        Cull Off

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

            sampler2D _MatCapMainTex;
            float4x4 _MVPMatrix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(_MVPMatrix, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MatCapMainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
