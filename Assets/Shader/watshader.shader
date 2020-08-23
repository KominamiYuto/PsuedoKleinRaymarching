// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/WaterSurfshader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        [PowerSlider(2.0)]_Ambient("アンビエント",Range(0.03,1)) = 0.03
        _HighLightPow("ハイライトの強さ",Range(0.03,1.0)) = 1.0
        _SpecColor("ハイライトの色",Color) = (1,1,1,1)
        [PowerSlider(2.0)]_size("大きさ",Range(1.0,100.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 300
        CGINCLUDE
        
        #pragma exclude_renderers gles
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fwdbase
        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        float _Ambient;
        float4 _LightColor0;
        float4 _Color;
        float4 _Burst;
        float _Burstuv;
        float _HighLightPow;
        float _size;
        
        struct appdata{
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float4 nor : NORMAL;
            float4 tangent :TANGENT;
            float2 texcoord1: TEXCOORD1;
        };
        struct v2f{
            float4 pos: SV_POSITION;
            float2 uv:TEXCOORD0;
            float3 nor:TEXCOORD1;
            float3 tang:TEXCOORD2;
            float3 binor: TEXCOORD3;
            float4 worldpos:TEXCOORD4;
            LIGHTING_COORDS(5,6)
        };
        float random (fixed2 p){ 
            return frac(sin(dot(p, fixed2(12.9898,78.233))) * 43758.5453);
        }
        float Fresnel(float f0, float u)
        {
            return f0 + (1-f0) * pow(1-u, 5);
        }
        v2f vert(appdata v){
            v2f o;
            UNITY_INITIALIZE_OUTPUT(v2f, o);
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.nor = UnityObjectToWorldNormal(v.nor);
            o.tang = normalize(mul(unity_ObjectToWorld,v.tangent.xyz));
            o.binor = normalize(cross(o.nor,o.tang))*v.tangent.w;
            o.worldpos = mul(unity_ObjectToWorld,v.vertex);
            TRANSFER_VERTEX_TO_FRAGMENT(o);
            return o;
        }
        
        float4 _SpecColor;
        sampler2D _GrabTexture;
        fixed4 frag(v2f i) : SV_Target{
            float3x3 tangentTransform = float3x3(i.tang,i.binor,i.nor);
            float3 normalLocal = float3(0.0,0.0,1.0);
            float2 waterpos = float2(0.5,0.5);
            float len;
            [unroll(6)]
            for(int j = 0;j<6;j++){
                float2 waterpos = float2(0.5 + 0.7 * cos(j * UNITY_PI/3), 0.5 + 0.7 * sin(j * UNITY_PI/3));
                len = distance(i.uv, waterpos);
                normalLocal += float3((i.uv.x - waterpos.x)/len * cos((len-_Time.x) * _size * (j + 0.5)),(i.uv.y - waterpos.y)/len * cos((len-_Time.x) * _size* (j + 0.5)),-1.0);
            };
            normalLocal.z = -1.0;
            float3 normalDirection = mul(normalize(normalLocal),tangentTransform);
            normalDirection = normalize(UnityObjectToWorldNormal(normalize(normalLocal)));
            float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldpos));
            float lightLen = length(lightDir);
            //↓再考の余地あり
            float NdotL = dot(normalDirection,normalize(_WorldSpaceLightPos0.xyz-i.worldpos.xyz));
            
            float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldpos));
            float NdotV = dot(normalDirection,viewDir);
            
            float3 R = -1.0*lightDir + 2.0*NdotL*normalDirection;
            float VdotR = dot(viewDir,R);
            float specularP = pow(max(0,VdotR),15);
            float4 specular = min(1.0,specularP) * _SpecColor *_LightColor0 * _HighLightPow;
            //attenは自動的に宣言される
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldpos);
            float diff = max(_Ambient,NdotL);
            fixed4 color = /*_LightColor0 * */ diff * _Color;
            color += max(0,NdotL)*specular;
            //return color * attenuation;
            float F = Fresnel(0.02, NdotL);
            color *= F;
            return fixed4(color);
        }
        ENDCG
        Pass{
            Tags{"LightMode" = "ForwardBase" "ForceNoShadowCasting"="True" }
            Cull Off
            CGPROGRAM
            ENDCG
        }
        Pass{
            Tags{"LightMode" = "ForwardAdd" "ForceNoShadowCasting"="True"}
            Blend One One
            Cull Off Zwrite Off
            CGPROGRAM
            ENDCG
        }
        UsePass "VertexLit/SHADOWCASTER"    
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 150
        Pass{
            Tags{"LightMode" = "ForwardBase" "ForceNoShadowCasting"="True" }
            Cull Off
            CGPROGRAM
            ENDCG
        }
        Pass{
            Tags{"LightMode" = "ForwardAdd" "ForceNoShadowCasting"="True"}
            Blend One One
            Cull Off Zwrite Off
            CGPROGRAM
            ENDCG
        }
        UsePass "VertexLit/SHADOWCASTER"
    }
    FallBack "Diffuse"
}
