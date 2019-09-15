Shader "Hidden/RadialBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Center("Center", Vector) = (0.5, 0.5, 0.0, 0.0)
		_Strength("Strength", Float) = 2.0
		_Dist("Dist", Float) = 1.0
    }
    SubShader
    {
        // No culling or depth
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
			float4 _Center;
			float _Strength;
			float _Dist;

            fixed4 frag (v2f i) : SV_Target
            {
				float samples[10] = {-0.08, -0.05, -0.03, -0.02, -0.01, 0.01, 0.02, 0.03, 0.05, 0.08};
                fixed4 col = tex2D(_MainTex, i.uv);

				float2 dir = i.uv - _Center.xy;
				float distance = length(dir);
				dir = normalize(dir);

				fixed4 blurColor = col;
				for (int j = 0; j < 10; ++j)
				{
					blurColor += tex2D(_MainTex, i.uv + (dir * samples[j] * _Dist));
				}
				blurColor /= 11.0;

				float blurLerp = clamp(distance * _Strength, 0.0, 1.0);
				col = lerp(col, blurColor, blurLerp);

                return col;
            }
            ENDCG
        }
    }
}
