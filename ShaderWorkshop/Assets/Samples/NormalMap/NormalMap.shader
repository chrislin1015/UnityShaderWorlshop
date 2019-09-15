Shader "Chris/NormalMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
		    Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent: TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD2;
				float4 worldTangent : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = float4(UnityObjectToWorldDir(v.tangent), v.tangent.w);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
			
			    float3 tNormalMap = UnpackNormal(tex2D(_NormalMap, i.uv));

				float3 worldBinormal = normalize(cross(i.worldNormal, i.worldTangent.xyz) * i.worldTangent.w);
				float3x3 tangentToWorld = transpose(float3x3(i.worldTangent.xyz, worldBinormal, i.worldNormal));
				float3 wNormalMap = mul(tangentToWorld, tNormalMap);

				float lightIntensity = max(0.0, dot(_WorldSpaceLightPos0.xyz, wNormalMap));
				fixed3 diffuse = lightIntensity * _LightColor0.rgb * SHADOW_ATTENUATION(i);
				fixed3 ambient = ShadeSH9(float4(i.worldNormal, 1)) * (1-lightIntensity);

				col.rgb *= diffuse + ambient;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
