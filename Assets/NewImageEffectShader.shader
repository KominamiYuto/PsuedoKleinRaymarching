Shader "Custom/ElectricBoard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [PowerSlider(3.0)] _modint ("モッド",range(1.0,1000.0)) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off 
        
        Pass
        {
            Tags{"LightMode" = "Always"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            int _modint;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : normal;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            sampler2D _MainTex;
            fixed4 frag (v2f i) : SV_Target
            {
                
                float2 cusuv1;
                //i.uvを_modint倍にしてceil()でそれより少ない整数にする。その後_modintで割ると左下の座標になる。
                float2 uvpos = float2(ceil(i.uv.x * _modint)/_modint + 1.0/_modint/2,
                                      ceil(i.uv.y * _modint)/_modint + 1.0/_modint/2);
                fixed4 col = tex2D(_MainTex, uvpos);
                float2 ppos = float2(0.5,0.5);
                float drowposY = fmod(uvpos.y * 2 + _Time.w*3,UNITY_PI/2);
                col *= (cos(drowposY) +10.0)/11;
                return col;
            }
            ENDCG
        }
    }
}
