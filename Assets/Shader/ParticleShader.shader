Shader "Unlit/ParticleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        [PowerSlider(2.0)]_Ambient("アンビエント",Range(0.03,1)) = 0.03
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
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 :TEXCOORD1;
                float4 nor : NORMAL;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 :TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 nor:TEXCOORD1;
                float3 worldpos:TEXCOORD4;
            };
            struct Input
            {
                float2 uv_MainTex;
                float2 uv2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Ambient;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 = v.uv2;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.nor = UnityObjectToWorldNormal(v.nor);
                o.worldpos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }
            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.uv2.x;
                c = fixed4(1-IN.uv2.y/10,0,IN.uv2.y/10,1);
                o.Albedo = c.rgb;
                o.Metallic = 0;
                o.Smoothness = 0.5;
                o.Alpha = c.a;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col = fixed4(i.uv2.x,1,1,1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                Input surfIN;
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldpos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldpos));
            
                UNITY_INITIALIZE_OUTPUT(Input,surfIN);
                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
                o.Albedo = 0.0;
                o.Emission = 1.0;
                o.Alpha = 1.0;
                o.Occlusion = 1.0;
                o.Normal = i.nor;
                surfIN.uv2 = i.uv2;
                surf(surfIN, o);
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldpos)
                fixed4 c = 0;
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 1;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = lightDir;
                gi.light.color *= atten;
            
                c += LightingStandard(o, viewDir, gi);
                c.a = 1.0;
                UNITY_APPLY_FOG(i.fogCoord, c);
                UNITY_OPAQUE_ALPHA(c.a);
                return c;
            }
            ENDCG
        }
    }
}
