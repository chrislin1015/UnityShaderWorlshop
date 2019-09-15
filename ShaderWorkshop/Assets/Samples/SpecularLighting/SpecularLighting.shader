Shader "Chris/SpecularLighting"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_SpecularPow ("Specular Power", Range(0.0, 1)) = 0
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed _SpecularPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

				//Diffuse
				float lightIntensity = max(0.0, dot(_WorldSpaceLightPos0.xyz, i.worldNormal));
				float3 diffuse = lightIntensity * _LightColor0.rgb * SHADOW_ATTENUATION(i);
				float3 ambient = ShadeSH9(float4(i.worldNormal, 1)) * (1- lightIntensity);
				col.rgb *= diffuse + ambient;

				//Specular
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 refl = reflect(-_WorldSpaceLightPos0.xyz, i.worldNormal);
				float specular = max(0.0, dot(viewDir, refl));
				specular = pow(specular, (_SpecularPow * 256) + 1) * _SpecularPow;

				float3 specularColor = specular * _LightColor0;
				col.rgb += specularColor;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
