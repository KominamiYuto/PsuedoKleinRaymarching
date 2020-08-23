// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent"
            "DisableBatching" = "True"
        }
        LOD 300
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
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
                float3 worldpos : TEXCOORD2;
                float4 projpos :TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            float _Debug;
            struct camerapos{
                float3 forward;
                float3 up;
                float3 right;
                float near;
            };
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float maxlen;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.worldpos = mul(unity_ObjectToWorld,v.vertex);
                o.projpos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.projpos.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                //1/6 = 0.166666...
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float distancefunc(float3 p){
                float3 csize = float3(0.90756, 0.92436, 0.90756);
                float size = 1.0;
                float3 c = float3(0,0,0);
                float defactor = 1.0;
                float3 offset = float3(0,0,0);
                float3 ap = p + 1.0;
                [unroll(15)]
                for (int i = 0; i < 15; i++) {
                    ap = p;
                    p = 2.0 * clamp(p, -csize, csize) - p;
                    float r2 = dot(p, p);
                    float k = max(size / r2, 1.0);
                    p *= k;
                    defactor *= k;
                    p += c;
                }
                float r = abs(0.5 * abs(p.y - offset.y) / defactor);
                //float r = abs(0.5 * log(length(p))*length(p) / defactor);
                return r;
            }
            inline float smoothdistancefunc(float3 pos,float maxlen){
                return smin(distancefunc(pos),maxlen,1);
            }
            inline float3 GetNormal(float3 pos,float maxlen){
                const float d = 0.001;
                return normalize(float3(
                    smoothdistancefunc(pos + float3(d,0,0),maxlen) - smoothdistancefunc(pos + float3(-d,0,0),maxlen),
                    smoothdistancefunc(pos + float3(0,d,0),maxlen) - smoothdistancefunc(pos + float3(0,-d,0),maxlen),
                    smoothdistancefunc(pos + float3(0,0,d),maxlen) - smoothdistancefunc(pos + float3(0,0,-d),maxlen)
                    ));

            }
            inline float3 GetNormal(float3 pos){
                const float d = 0.001;
                return normalize(float3(
                    distancefunc(pos + float3(d,0,0)) - distancefunc(pos + float3(-d,0,0)),
                    distancefunc(pos + float3(0,d,0)) - distancefunc(pos + float3(0,-d,0)),
                    distancefunc(pos + float3(0,0,d)) - distancefunc(pos + float3(0,0,-d))
                    ));
            }
            void frag (v2f i,out fixed4 Colorbuff:SV_Target, out float Depthbuff : SV_Depth)
            {
                float2 screenpos = 2* (i.projpos.xy/i.projpos.w -0.5);
                screenpos.x *= _ScreenParams.x/_ScreenParams.y;
                //float2 screenpos = (i.vertex.xy*2-_ScreenParams)/min(_ScreenParams.x,_ScreenParams.y);
                float depth = LinearEyeDepth(
                                SAMPLE_DEPTH_TEXTURE_PROJ(
                                    _CameraDepthTexture,
                                    UNITY_PROJ_COORD(i.projpos))
                                );
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //カメラ定義
                camerapos camerapos;
                camerapos.forward = -UNITY_MATRIX_V[2].xyz;
                camerapos.up = UNITY_MATRIX_V[1].xyz;
                camerapos.right = UNITY_MATRIX_V[0].xyz;
                camerapos.near = abs(UNITY_MATRIX_P[1].y);
                //レイ定義
                ray ray;
                ray.normalizedDir = normalize(camerapos.right*screenpos.x +
                                              camerapos.up*screenpos.y +
                                              camerapos.forward*camerapos.near);
                ray.pos = _WorldSpaceCameraPos +  ray.normalizedDir;
                ray.len = length(ray.pos - _WorldSpaceCameraPos);
                ray.maxlen = depth/dot(ray.normalizedDir,camerapos.forward);
                ray.pos += (ray.maxlen - 1) * ray.normalizedDir;
                ray.len += ray.maxlen - 1;
                float dist = smoothdistancefunc(ray.pos,ray.maxlen);
                dist = distancefunc(ray.pos);
                ray.pos += dist * ray.normalizedDir;
                ray.len += dist;
                clip(0.001-dist);
                //clip(ray.maxlen-ray.len);
                
                float3 normal = GetNormal(ray.pos,ray.maxlen);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = dot(normal,lightDir);
                float diffuse = max(0,NdotL);
                col *= diffuse;
                ray.normalizedDir = reflect(ray.normalizedDir, normal);
                //Reflection Probe
                half4 refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
                refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                Colorbuff =  col*0.7 + refColor*0.9;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                float3 Objectpos = ray.pos;
                ray.pos += ray.normalizedDir*0.01;
                for(int j = 0;j<50;j++){
                    dist = distancefunc(ray.pos);
                    ray.pos += dist*ray.normalizedDir;
                    ray.len += dist;
                    if(dist<0.001){
                        break;
                    }
                }
                if(dist<0.001){
                    normal = GetNormal(ray.pos);
                    lightDir = normalize(_WorldSpaceLightPos0.xyz);
                    NdotL = dot(normal,lightDir);
                    diffuse = max(0,NdotL);
                    ray.normalizedDir = reflect(ray.normalizedDir, normal);
                    refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
                    refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                    Colorbuff += refColor*0.64 + diffuse*0.8;
                }
                float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(Objectpos,1.0));
                Depthbuff = vpDepthPos.z/vpDepthPos.w;
            }
            ENDCG
        }
        
        Pass{
            Tags{"LightMode" = "ShadowCaster"}
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
                float3 worldpos : TEXCOORD2;
                float4 projpos :TEXCOORD3;
            };
            struct camerapos{
                float3 forward;
                float3 up;
                float3 right;
                float near;
            };
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.worldpos = mul(unity_ObjectToWorld,v.vertex);
                o.projpos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.projpos.z);
                return o;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                //1/6 = 0.166666...
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float distancefunc(float3 p){
                float3 csize = float3(0.90756, 0.92436, 0.90756);
                float size = 1.0;
                float3 c = float3(0,0,0);
                float defactor = 1.0;
                float3 offset = float3(0,0,0);
                float3 ap = p + 1.0;
                for (int i = 0; i < 12; i++) {
                    ap = p;
                    p = 2.0 * clamp(p, -csize, csize) - p;
                    float r2 = dot(p, p);
                    float k = max(size / r2, 1.0);
                    p *= k;
                    defactor *= k;
                    p += c;
                }
                float r = abs(0.5 * abs(p.y - offset.y) / defactor);
                //float r = abs(0.5 * log(length(p))*length(p) / defactor);
                return r;
            }
            float frag (v2f i): SV_Depth
            {
                float2 screenpos = 2* (i.projpos.xy/i.projpos.w -0.5);
                screenpos.x *= _ScreenParams.x/_ScreenParams.y;
                //カメラ定義
                camerapos camerapos;
                camerapos.forward = -UNITY_MATRIX_V[2].xyz;
                camerapos.up = UNITY_MATRIX_V[1].xyz;
                camerapos.right = UNITY_MATRIX_V[0].xyz;
                camerapos.near = abs(UNITY_MATRIX_P[1].y);
                //レイ定義
                ray ray;
                ray.normalizedDir = normalize(camerapos.right*screenpos.x +
                                              camerapos.up*screenpos.y +
                                              camerapos.forward*camerapos.near);
                ray.pos = _WorldSpaceCameraPos +  ray.normalizedDir;
                ray.len = length(ray.pos - _WorldSpaceCameraPos);
                float dist = 0;
                for(int j = 0;j<80;j++){
                    dist = distancefunc(ray.pos);
                    ray.pos += dist * ray.normalizedDir;
                    ray.len += dist;
                    if(dist<0.001){
                        break;
                    }
                }
                clip(0.001-dist);
                float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(ray.pos,1.0));
                return vpDepthPos.z/vpDepthPos.w;
            }
            ENDCG
        }
    }
    
    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent"
            "DisableBatching" = "True"
        }
        LOD 150
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
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
                float3 worldpos : TEXCOORD2;
                float4 projpos :TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            float _Debug;
            struct camerapos{
                float3 forward;
                float3 up;
                float3 right;
                float near;
            };
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float maxlen;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.worldpos = mul(unity_ObjectToWorld,v.vertex);
                o.projpos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.projpos.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            inline float distancefunc(float3 p){
                float3 csize = float3(0.90756, 0.92436, 0.90756);
                float size = 1.0;
                float3 c = float3(0,0,0);
                float defactor = 1.0;
                float3 offset = float3(0,0,0);
                float3 ap = p + 1.0;
                [unroll(8)]
                for (int i = 0; i < 12; i++) {
                    ap = p;
                    p = 2.0 * clamp(p, -csize, csize) - p;
                    float r2 = dot(p, p);
                    float k = max(size / r2, 1.0);
                    p *= k;
                    defactor *= k;
                    p += c;
                }
                float r = abs(0.5 * abs(p.y - offset.y) / defactor);
                //float r = abs(0.5 * log(length(p))*length(p) / defactor);
                return r;
            }
            inline float3 GetNormal(float3 pos){
                const float d = 0.001;
                return normalize(float3(
                    distancefunc(pos + float3(d,0,0)) - distancefunc(pos + float3(-d,0,0)),
                    distancefunc(pos + float3(0,d,0)) - distancefunc(pos + float3(0,-d,0)),
                    distancefunc(pos + float3(0,0,d)) - distancefunc(pos + float3(0,0,-d))
                    ));
            }
            void frag (v2f i,out fixed4 Colorbuff:SV_Target, out float Depthbuff : SV_Depth)
            {
                float2 screenpos = 2* (i.projpos.xy/i.projpos.w -0.5);
                screenpos.x *= _ScreenParams.x/_ScreenParams.y;
                //float2 screenpos = (i.vertex.xy*2-_ScreenParams)/min(_ScreenParams.x,_ScreenParams.y);
                float depth = LinearEyeDepth(
                                SAMPLE_DEPTH_TEXTURE_PROJ(
                                    _CameraDepthTexture,
                                    UNITY_PROJ_COORD(i.projpos))
                                );
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //カメラ定義
                camerapos camerapos;
                camerapos.forward = -UNITY_MATRIX_V[2].xyz;
                camerapos.up = UNITY_MATRIX_V[1].xyz;
                camerapos.right = UNITY_MATRIX_V[0].xyz;
                camerapos.near = abs(UNITY_MATRIX_P[1].y);
                //レイ定義
                ray ray;
                ray.normalizedDir = normalize(camerapos.right*screenpos.x +
                                              camerapos.up*screenpos.y +
                                              camerapos.forward*camerapos.near);
                ray.pos = _WorldSpaceCameraPos +  ray.normalizedDir;
                ray.len = length(ray.pos - _WorldSpaceCameraPos);
                ray.maxlen = depth/dot(ray.normalizedDir,camerapos.forward);
                ray.pos += (ray.maxlen - ray.len-1) * ray.normalizedDir;
                ray.len += ray.maxlen - ray.len-1;
                float dist = distancefunc(ray.pos);
                dist = distancefunc(ray.pos);
                ray.pos += dist * ray.normalizedDir;
                ray.len += dist;
                
                clip(0.001-dist);
                //clip(ray.maxlen-ray.len);
                
                float3 normal = GetNormal(ray.pos);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = dot(normal,lightDir);
                float diffuse = max(0,NdotL);
                col *= diffuse;
                ray.normalizedDir = reflect(ray.normalizedDir, normal);
                //Reflection Probe
                half4 refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
                refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                Colorbuff =  col + refColor*0.8;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                float3 Objectpos = ray.pos;
                ray.pos += ray.normalizedDir*0.01;
                [unroll(3)]
                for(int j = 0;j<3;j++){
                    dist = distancefunc(ray.pos);
                    ray.pos += dist*ray.normalizedDir;
                    ray.len += dist;
                    if(dist<0.001){
                        break;
                    }
                }
                if(dist<0.001){
                    normal = GetNormal(ray.pos);
                    lightDir = normalize(_WorldSpaceLightPos0.xyz);
                    NdotL = dot(normal,lightDir);
                    diffuse = max(0,NdotL);
                    ray.normalizedDir = reflect(ray.normalizedDir, normal);
                    refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
                    refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                    Colorbuff += refColor*0.64 + diffuse*0.8;
                }
                float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(Objectpos,1.0));
                Depthbuff = vpDepthPos.z/vpDepthPos.w;
            }
            ENDCG
        }
        
        Pass{
            Tags{"LightMode" = "ShadowCaster"}
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
                float3 worldpos : TEXCOORD2;
                float4 projpos :TEXCOORD3;
            };
            struct camerapos{
                float3 forward;
                float3 up;
                float3 right;
                float near;
            };
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.worldpos = mul(unity_ObjectToWorld,v.vertex);
                o.projpos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.projpos.z);
                return o;
            }
            inline float distancefunc(float3 p){
                float3 csize = float3(0.90756, 0.92436, 0.90756);
                float size = 1.0;
                float3 c = float3(0,0,0);
                float defactor = 1.0;
                float3 offset = float3(0,0,0);
                float3 ap = p + 1.0;
                [unroll(8)]
                for (int i = 0; i < 8; i++) {
                    ap = p;
                    p = 2.0 * clamp(p, -csize, csize) - p;
                    float r2 = dot(p, p);
                    float k = max(size / r2, 1.0);
                    p *= k;
                    defactor *= k;
                    p += c;
                }
                float r = abs(0.5 * abs(p.y - offset.y) / defactor);
                //float r = abs(0.5 * log(length(p))*length(p) / defactor);
                return r;
            }
            float frag (v2f i): SV_Depth
            {
                float2 screenpos = 2* (i.projpos.xy/i.projpos.w -0.5);
                screenpos.x *= _ScreenParams.x/_ScreenParams.y;
                //カメラ定義
                camerapos camerapos;
                camerapos.forward = -UNITY_MATRIX_V[2].xyz;
                camerapos.up = UNITY_MATRIX_V[1].xyz;
                camerapos.right = UNITY_MATRIX_V[0].xyz;
                camerapos.near = abs(UNITY_MATRIX_P[1].y);
                //レイ定義
                ray ray;
                ray.normalizedDir = normalize(camerapos.right*screenpos.x +
                                              camerapos.up*screenpos.y +
                                              camerapos.forward*camerapos.near);
                ray.pos = _WorldSpaceCameraPos +  ray.normalizedDir;
                ray.len = length(ray.pos - _WorldSpaceCameraPos);
                float dist = 0;
                [unroll(30)]
                for(int j = 0;j<30;j++){
                    dist = distancefunc(ray.pos);
                    ray.pos += dist * ray.normalizedDir;
                    ray.len += dist;
                    if(dist<0.001){
                        break;
                    }
                }
                clip(0.001-dist);
                float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(ray.pos,1.0));
                return vpDepthPos.z/vpDepthPos.w;
            }
            ENDCG
        }
    }
}
