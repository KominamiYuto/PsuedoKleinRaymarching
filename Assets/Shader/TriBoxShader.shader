Shader "Custom/TriBoxShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Size("大きさ",Range(0.0,100.0)) = 2.0
        _BoxLength("距離",Range(0.0,100.0)) = 1.0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            
            Tags{"LightMode" = "ForwardBase"}
            Blend One Zero
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma geometry geom
            #include "UnityCG.cginc"
            #pragma target 5.0
            float _Size;
            float _BoxLength;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : normal;
                float3 tangent : tangent;
                uint vertID : SV_VertexID;
            };
            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : normal;
                float3 tangent : tangent;
                int vertID : TEXCOORD1;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal :TEXCOORD1;
                float3 worldpos : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                float4 vertex : SV_POSITION;
                float4 debug : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2g vert (appdata v)
            {
                v2g g;
                g.vertex = v.vertex;
                g.uv = v.uv;
                g.normal = v.normal;
                g.tangent = v.tangent;
                g.vertID = (int)v.vertID;
                return g;
            }
            
            [maxvertexcount(36)]
            void geom(triangle v2g input[3], inout TriangleStream<v2f> outStream){
                v2g v = input[0];
                v2f o[8];
                float3 worldposition = float3(sin(_Time.x),sin(_Time.y),sin(_Time.z));
                [unroll(2)]
                for(int j=0;j<=1;j++){
                    [unroll(4)]
                    for(int i=0;i<=3;i++){
                        o[i+j*4].normal = UnityObjectToWorldNormal(v.normal);
                        
                        float4 worldpos = mul(unity_ObjectToWorld,v.vertex);
                        worldpos.x += cos((i*_Time.z)/2) * _Size + v.vertID;
                        worldpos.y += sin((i*_Time.z)/2) * _Size + v.vertID/5;
                        worldpos.z += (j*2-1) * _Size * 1.414/2 + v.vertID/10;
                        o[i+j*4].worldpos = worldpos;
                        o[i+j*4].vertex = UnityWorldToClipPos(worldpos);
                        o[i+j*4].uv = v.uv;
                        o[i+j*4].debug = float4(0.25 * (i+1),j,0.0,1.0);
                    }

                }
                float3 nor = cross(normalize(o[2].worldpos-o[0].worldpos),normalize(o[2].worldpos-o[0].worldpos));
                o[0].normal = nor;
                o[1].normal = nor;
                o[2].normal = nor;
                o[3].normal = nor;

                outStream.Append(o[0]);
                outStream.Append(o[2]);
                outStream.Append(o[1]);
                outStream.RestartStrip();
                outStream.Append(o[0]);
                outStream.Append(o[3]);
                outStream.Append(o[2]);
                outStream.RestartStrip();
                nor = cross(normalize(o[1].worldpos-o[0].worldpos),normalize(o[5].worldpos-o[0].worldpos));
                o[0].normal = nor;
                o[1].normal = nor;
                o[4].normal = nor;
                o[5].normal = nor;
                
                outStream.Append(o[0]);
                outStream.Append(o[1]);
                outStream.Append(o[5]);
                outStream.RestartStrip();
                outStream.Append(o[0]);
                outStream.Append(o[5]);
                outStream.Append(o[4]);
                outStream.RestartStrip();
                nor = cross(normalize(o[2].worldpos-o[1].worldpos),normalize(o[6].worldpos-o[1].worldpos));
                o[1].normal = nor;
                o[2].normal = nor;
                o[5].normal = nor;
                o[6].normal = nor;
                
                outStream.Append(o[1]);
                outStream.Append(o[2]);
                outStream.Append(o[6]);
                outStream.RestartStrip();
                outStream.Append(o[1]);
                outStream.Append(o[6]);
                outStream.Append(o[5]);
                outStream.RestartStrip();
                nor = cross(normalize(o[3].worldpos-o[2].worldpos),normalize(o[7].worldpos-o[2].worldpos));
                o[2].normal = nor;
                o[3].normal = nor;
                o[6].normal = nor;
                o[7].normal = nor;
                
                outStream.Append(o[2]);
                outStream.Append(o[3]);
                outStream.Append(o[7]);
                outStream.RestartStrip();
                outStream.Append(o[2]);
                outStream.Append(o[7]);
                outStream.Append(o[6]);
                outStream.RestartStrip();
                nor = cross(normalize(o[0].worldpos-o[3].worldpos),normalize(o[4].worldpos-o[3].worldpos));
                o[0].normal = nor;
                o[3].normal = nor;
                o[4].normal = nor;
                o[7].normal = nor;
                
                outStream.Append(o[3]);
                outStream.Append(o[0]);
                outStream.Append(o[4]);
                outStream.RestartStrip();
                outStream.Append(o[3]);
                outStream.Append(o[4]);
                outStream.Append(o[7]);
                outStream.RestartStrip();
                nor = cross(normalize(o[5].worldpos-o[4].worldpos),normalize(o[6].worldpos-o[4].worldpos));
                o[4].normal = nor;
                o[5].normal = nor;
                o[6].normal = nor;
                o[7].normal = nor;
                
                outStream.Append(o[4]);
                outStream.Append(o[5]);
                outStream.Append(o[6]);
                outStream.RestartStrip();
                outStream.Append(o[4]);
                outStream.Append(o[6]);
                outStream.Append(o[7]);
                outStream.RestartStrip();
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                float3 LightDir = normalize(UnityWorldSpaceLightDir(i.worldpos));
                float VdotN = dot(LightDir,i.normal);
                col.rgb *= VdotN;
                //col = i.debug;
                return col;
            }
            ENDCG
        }
        
    }
}
