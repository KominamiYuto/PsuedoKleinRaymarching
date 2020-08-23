Shader "Custom/Hanabishader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Len("len",Range(0.0,100.0)) = 0.0
        _ColorDecay("色減衰",Range(0.0,1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Len;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if(_Len > 0){
                    discard;
                }
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col = fixed4(.0,.0,.0,.0);
                return col;
            }
            ENDCG
        }
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma geometry geom

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldpos : TEXCOORD2;
                float3 normal : TEXCOORD3;
                };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Len;
            float _ColorDecay;

            appdata vert (appdata v)
            {
                return v;
            }
            [maxvertexcount(6)]
            void geom(triangle appdata input[3],inout PointStream<v2f> outStream){
                v2f o[3];
                float4 worldpos;
                [unroll(3)]
                for(int i = 0;i<3;i++){
                    worldpos = mul(unity_ObjectToWorld,input[i].vertex +  float4(input[i].vertex.xyz* (_Len),0));
                    o[i].worldpos = worldpos;
                    o[i].vertex = UnityWorldToClipPos(worldpos);
                    o[i].normal = UnityObjectToWorldNormal(input[i].normal);
                    outStream.Append(o[i]);
                }
                [unroll(3)]
                for(i = 0;i<3;i++){
                    worldpos = mul(unity_ObjectToWorld,input[i].vertex + float4(input[i].vertex * ( _Len) + float3(input[i].vertex.x,0,input[i].vertex.z) * _Len,0));
                    o[i].worldpos = worldpos;
                    o[i].vertex = UnityWorldToClipPos(worldpos);
                    o[i].normal = UnityObjectToWorldNormal(input[i].normal);
                    outStream.Append(o[i]);
                }
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(0,1,1,1) - _ColorDecay;
                return col;
            }
            ENDCG
        }
    }
}
