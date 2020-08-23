Shader "Custom/CRTshader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FallPos ("Fall",Vector) = (0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            name "アプデ"
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            #include "UnityCustomRenderTexture.cginc"
            float rand(float3 co){
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 56.787))) * 43758.5453);
            }
            float noise(float3 pos){
                float3 ip = floor(pos);
                float3 fp = smoothstep(0, 1, frac(pos));
                float4 a = float4(
                    rand(ip + float3(0, 0, 0)),
                    rand(ip + float3(1, 0, 0)),
                    rand(ip + float3(0, 1, 0)),
                    rand(ip + float3(1, 1, 0)));
                float4 b = float4(
                    rand(ip + float3(0, 0, 1)),
                    rand(ip + float3(1, 0, 1)),
                    rand(ip + float3(0, 1, 1)),
                    rand(ip + float3(1, 1, 1)));
             
                a = lerp(a, b, fp.z);
                a.xy = lerp(a.xy, a.zw, fp.y);
                return lerp(a.x, a.y, fp.x);
            }
            float perlin(float3 pos){
                return 
                    (noise(pos) * 32 +
                    noise(pos * 2 ) * 16 +
                    noise(pos * 4) * 8 +
                    noise(pos * 8) * 4 +
                    noise(pos * 16) * 2 +
                    noise(pos * 32) ) / 63;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _FallPos;
            
            fixed4 frag (v2f_customrendertexture i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_SelfTexture2D,i.globalTexcoord);
                if(distance(_FallPos.xz,i.globalTexcoord.rg)<0.03){
                    col.r += 1.0;
                }
                float wid = 1/_CustomRenderTextureWidth;
                float hei = 1/_CustomRenderTextureHeight;
                fixed4 col_up = tex2D(_SelfTexture2D,i.globalTexcoord + float2(0,hei));
                fixed4 col_down = tex2D(_SelfTexture2D,i.globalTexcoord - float2(0,hei));
                fixed4 col_right = tex2D(_SelfTexture2D,i.globalTexcoord + float2(wid,0));
                fixed4 col_left = tex2D(_SelfTexture2D,i.globalTexcoord - float2(wid,0));
                float p = 2 * col.r - col.g + (col_up.r/4 + col_down.r/4 + col_right.r/4 + col_left.r/4 - col.r);
                // apply fog
                //return fixed4(i.globalTexcoord,1);
                return  float4(p, col.r, 0, 0);
            }
            ENDCG
        }
    }
}