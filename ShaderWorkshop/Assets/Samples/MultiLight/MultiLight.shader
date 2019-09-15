Shader "Chris/MultiLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
	    _SpecularPow ("Specular Power", Range(0, 1)) = 0
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
				float4 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _SpecularPow;

			fixed3 Light(float4 lightPos, float3 wNormal, float3 wPos, fixed3 lightColor, fixed lightAtt, float3 viewDir, out fixed3 specularColor)
			{
				float3 lightDir = 1;
				float3 attenuation = 1;

				if (lightPos.w == 0)
				{
					lightDir = lightPos.xyz;
					attenuation = 1;
				}
				else
				{
					lightDir = lightPos.xyz - wPos;
					float distance = length(lightDir);

					attenuation = 1.0 / (1.0 + lightAtt * pow(distance, 2.0));
					lightDir = normalize(lightDir);
				}

				//diffuse
				fixed3 color = attenuation * lightColor * saturate(dot(lightDir, wNormal));

				//specular
				float3 refl = reflect(-lightDir, wNormal);
				float specular = max(0.0, dot(viewDir, refl));
				specular = pow(specular, 1 + (_SpecularPow * 256)) * _SpecularPow;
				specularColor = specular * lightColor;

				return color;
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

			    fixed3 specularColor = 0;
				fixed3 finalSpecular = 0;
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			    
				//main light
			    fixed3 lightColor = Light(_WorldSpaceLightPos0, i.worldNormal, i.worldPos, _LightColor0.rgb, 1, viewDir, specularColor) * SHADOW_ATTENUATION(i);
				finalSpecular += specularColor;

				float lightIntensity = max(0.0, dot(i.worldNormal, _WorldSpaceLightPos0.xyz));
				fixed3 ambient = ShadeSH9(float4(i.worldNormal, 1)) * (1- lightIntensity);
				lightColor += ambient;

				//4 Sub light
				for (int index = 0; index < 4; ++index)
				{
					float4 lightPos = float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1);
					lightColor += Light(lightPos, i.worldNormal, i.worldPos, unity_LightColor[index].rgb, unity_4LightAtten0[index], viewDir, specularColor);
					finalSpecular += specularColor;
				}

				col.rgb *= lightColor;

				col.rgb += finalSpecular;
			    
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
