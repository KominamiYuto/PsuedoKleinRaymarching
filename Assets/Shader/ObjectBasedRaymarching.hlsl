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
struct camerapos{
    float3 forward;
    float3 up;
    float3 right;
    float near;
};
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    o.worldpos = mul(unity_ObjectToWorld,v.vertex);
    o.projpos = ComputeScreenPos(o.vertex);
    COMPUTE_EYEDEPTH(o.projpos.z);
    UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}
inline ray RayLocalPosCalc(ray ray,float3 delta){
    ray.localpos = mul(unity_WorldToObject,float4(ray.pos + delta,1)).xyz*ray.scale;
    return ray;
}
inline bool isInnerbox(ray ray){
    return all(max(ray.scale*0.5-abs(ray.localpos),0));
}
inline float3 GetNormal(ray ray){
    const float d = 0.001;
    return normalize(float3(
        smoothdistancefunc(RayLocalPosCalc(ray,float3(d,0,0))) - smoothdistancefunc(RayLocalPosCalc(ray,float3(-d,0,0))),
        smoothdistancefunc(RayLocalPosCalc(ray,float3(0,d,0))) - smoothdistancefunc(RayLocalPosCalc(ray,float3(0,-d,0))),
        smoothdistancefunc(RayLocalPosCalc(ray,float3(0,0,d))) - smoothdistancefunc(RayLocalPosCalc(ray,float3(0,0,-d)))
        ));

}
#if UNITY_PASS_SHADOWCASTER
void frag (v2f i,out float Depthbuff : SV_Depth)
{
    float2 screenpos = (i.vertex.xy*2-_ScreenParams)/min(_ScreenParams.x,_ScreenParams.y);
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
    ray.pos = i.worldpos;
    ray.len = length(ray.pos - _WorldSpaceCameraPos);
    //http://marupeke296.sakura.ne.jp/DXG_No39_WorldMatrixInformation.html
    ray.scale = float3(
        length(unity_ObjectToWorld[0].xyz),
        length(unity_ObjectToWorld[1].xyz),
        length(unity_ObjectToWorld[2].xyz)
        );
    float dist = 0;
#if hiquality
    [unroll(70)]
    for(int j = 0;j<70;j++){
        dist = smoothdistancefunc(RayLocalPosCalc(ray,0));
        ray.pos += dist*ray.normalizedDir;
        ray.len += dist;
        if(!isInnerbox(RayLocalPosCalc(ray,0))){
            break;
        }
        if(any(max(0.001-dist,0))){
            break;
        }
    }
#else
    [unroll(20)]
    for(int j = 0;j<20;j++){
        dist = smoothdistancefunc(RayLocalPosCalc(ray,0));
        ray.pos += dist*ray.normalizedDir;
        ray.len += dist;
        if(!isInnerbox(RayLocalPosCalc(ray,0))){
            break;
        }
        if(any(max(0.001-dist,0))){
            break;
        }
    }
#endif
    //if() discardより速い
    clip(0.001-dist);
    float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(ray.pos,1.0));
    Depthbuff = vpDepthPos.z/vpDepthPos.w;
}
#else
void frag (v2f i,out fixed4 Colorbuff:SV_Target, out float Depthbuff : SV_Depth)
{
    float2 screenpos = (i.vertex.xy*2-_ScreenParams)/min(_ScreenParams.x,_ScreenParams.y);
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
    ray.pos = i.worldpos;
    ray.len = length(ray.pos - _WorldSpaceCameraPos);
    ray.maxlen = depth/dot(ray.normalizedDir,camerapos.forward);
    ray.pos += (ray.maxlen - ray.len) * ray.normalizedDir;
    ray.len += ray.maxlen - ray.len;
    //http://marupeke296.sakura.ne.jp/DXG_No39_WorldMatrixInformation.html
    ray.scale = float3(
        length(unity_ObjectToWorld[0].xyz),
        length(unity_ObjectToWorld[1].xyz),
        length(unity_ObjectToWorld[2].xyz)
        );
    float dist = smoothdistancefunc(RayLocalPosCalc(ray,0));
    ray.pos += dist*ray.normalizedDir;
    ray.len += dist;
    //if() discardより速い
    clip(0.001-dist);
    
    float3 normal = GetNormal(ray);
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    float NdotL = dot(normal,lightDir);
    float diffuse = max(0.0,NdotL);
    col *= diffuse;
    
    ray.normalizedDir = reflect(ray.normalizedDir, normal);
    //Reflection Probe
    half4 refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
    refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
    Colorbuff =  col + refColor * 0.8;
    float3 Objectpos = ray.pos;
    ray.pos += ray.normalizedDir*0.01;
    [unroll(5)]
    for(int j = 0;j<5;j++){
        dist = distancefunc(ray.pos);
        ray.pos += dist*ray.normalizedDir;
        ray.len += dist;
        if(dist<0.001){
            break;
        }
    }
    if(dist<0.001){
        normal = GetNormal(ray);
        lightDir = normalize(_WorldSpaceLightPos0.xyz);
        NdotL = dot(normal,lightDir);
        diffuse = max(0,NdotL);
        ray.normalizedDir = reflect(ray.normalizedDir, normal);
        refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, ray.normalizedDir, 0);
        refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
        Colorbuff += refColor*0.64 + diffuse*0.8;
    }
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);
    float4 vpDepthPos = mul(UNITY_MATRIX_VP,float4(Objectpos,1.0));
    Depthbuff = vpDepthPos.z/vpDepthPos.w;
}
#endif