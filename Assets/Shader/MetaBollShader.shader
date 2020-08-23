Shader "Unlit/MetabollShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Debug("debug",Vector)= (0,0,0,0)
        [HideInInspector] _arraycount("配列の数",int) = 0
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
            float4 _Debug;
            int _arraycount;
            struct metabollinfo{
                float3 pos;
                float size;
                float3 addForce;
                float time;
            };
            StructuredBuffer<metabollinfo> _metabollinfo;
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float maxlen;
                float3 scale;
                float3 localpos;
            };
            inline float distancefunc(float3 localpos,int _arraynum){
                return length(localpos-_metabollinfo[_arraynum].pos)-_metabollinfo[_arraynum].size;
            }
            inline float distancefunc(float3 localpos){
                return length(localpos-_metabollinfo[0].pos)-_metabollinfo[0].size;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float smoothdistancefunc(ray ray){
                float tmplen = smin(distancefunc(ray.localpos),ray.maxlen,0.8);
                for(int k = 0;k<_arraycount;k++){
                    tmplen = smin(distancefunc(ray.localpos,k),tmplen,0.8);
                }
                return tmplen;
            }
            #include "ObjectBasedRaymarching.hlsl"
            ENDCG
        }
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hiquality _

            // make fog work

            #include "UnityCG.cginc"
            float4 _Debug;
            int _arraycount;
            struct metabollinfo{
                float3 pos;
                float size;
                float3 addForce;
                float time;
            };
            StructuredBuffer<metabollinfo> _metabollinfo;
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float3 scale;
                float3 localpos;
            };
            inline float distancefunc(float3 localpos,int _arraynum){
                return length(localpos-_metabollinfo[_arraynum].pos)-_metabollinfo[_arraynum].size;
            }
            inline float distancefunc(float3 localpos){
                return length(localpos-_metabollinfo[0].pos)-_metabollinfo[0].size;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float smoothdistancefunc(ray ray){
                float tmplen = distancefunc(ray.localpos);
                for(int k = 0;k<_arraycount;k++){
                    tmplen = smin(distancefunc(ray.localpos,k),tmplen,0.8);
                }
                return tmplen;
            }
            #include "ObjectBasedRaymarching.hlsl"
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
            float4 _Debug;
            int _arraycount;
            struct metabollinfo{
                float3 pos;
                float size;
                float3 addForce;
                float time;
            };
            StructuredBuffer<metabollinfo> _metabollinfo;
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float maxlen;
                float3 scale;
                float3 localpos;
            };
            inline float distancefunc(float3 localpos,int _arraynum){
                return length(localpos-_metabollinfo[_arraynum].pos)-_metabollinfo[_arraynum].size;
            }
            inline float distancefunc(float3 localpos){
                return length(localpos-_metabollinfo[0].pos)-_metabollinfo[0].size;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float smoothdistancefunc(ray ray){
                float tmplen = smin(distancefunc(ray.localpos),ray.maxlen,0.8);
                for(int k = 0;k<_arraycount;k++){
                    tmplen = smin(distancefunc(ray.localpos,k),tmplen,0.8);
                }
                return tmplen;
            }
            #include "ObjectBasedRaymarching.hlsl"
            ENDCG
        }
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"
            float4 _Debug;
            int _arraycount;
            struct metabollinfo{
                float3 pos;
                float size;
                float3 addForce;
                float time;
            };
            StructuredBuffer<metabollinfo> _metabollinfo;
            struct ray{
                float3 pos;
                float len;
                float3 normalizedDir;
                float3 scale;
                float3 localpos;
            };
            inline float distancefunc(float3 localpos,int _arraynum){
                return length(localpos-_metabollinfo[_arraynum].pos)-_metabollinfo[_arraynum].size;
            }
            inline float distancefunc(float3 localpos){
                return length(localpos-_metabollinfo[0].pos)-_metabollinfo[0].size;
            }
            //https://www.iquilezles.org/www/articles/smin/smin.htm
            float smin(float a,float b, float k){
                float h = max(k - abs(a-b), 0.0)/k;
                return min(a,b) - h*h*h*k*(0.166666);
            }
            inline float smoothdistancefunc(ray ray){
                float tmplen = distancefunc(ray.localpos);
                for(int k = 0;k<_arraycount;k++){
                    tmplen = smin(distancefunc(ray.localpos,k),tmplen,0.8);
                }
                return tmplen;
            }
            #include "ObjectBasedRaymarching.hlsl"
            ENDCG
        }
    }
}
