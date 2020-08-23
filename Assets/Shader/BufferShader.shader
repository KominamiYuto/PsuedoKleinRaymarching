Shader "Custom/BufferShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _subtex("Texture",2D) = "white" {}
        _lightUV("ライトのuv座標",Vector) = (1,0,1,0)
        _gause("ブラー",Range(1,100)) = 1
        _gauseAddX("X方向ブラー",Range(-1,1))=0
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

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
            sampler2D _subtex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_subtex, i.uv);
                return fixed4(1,1,1,1) - fixed4(col.x,col.x,col.x,0)*100;
            }
            ENDCG
        }
        
        GrabPass{}
        Pass{
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
            float4 _MainTex_ST;
            float2 _lightUV;
            sampler2D _GrabTexture;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 tmpcolor = fixed4(0,0,0,0);
                [unroll(100)]
                for(float j = 0;j<100;j++){
                    float2 getpixeluv = lerp(_lightUV,i.uv,float2(j/100,j/100));
                    tmpcolor += tex2D(_GrabTexture, getpixeluv);
                }
                //float2 getpixeluv = lerp(_lightUV,i.uv,float2(0.5,0.5));
                //tmpcolor = tex2D(_GrabTexture, getpixeluv);
                tmpcolor/=100;
                fixed4 depthcol = tex2D(_GrabTexture, i.uv);
                fixed4 col = tex2D(_MainTex, i.uv);
                col += tmpcolor;
                col += depthcol;
                return col;
            }
            ENDCG
        }
        GrabPass{}
        Pass{
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
            sampler2D _GrabTexture;
            int _gause;
            float _gauseAddX;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_GrabTexture, i.uv);
                
                //fixed4 col = fixed4(0,0,0,1);
                for(int j = 0;j<_gause;j++){
                    col += tex2D(_GrabTexture, float2(i.uv.x+_gauseAddX*j/_gause+(_ScreenParams.z-1.0)*(j-_gause/2),i.uv.y));
                }
                for(int j = 0;j<_gause;j++){
                    col += tex2D(_GrabTexture, float2(i.uv.x+_gauseAddX*j/_gause,i.uv.y+(_ScreenParams.w-1.0)*(j-_gause/2)));
                }
                col/=_gause*2;
                return col;
            }
            ENDCG
        }
    }
}