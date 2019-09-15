Shader "Chris/Fresnel"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_FresnelPow ("Frsnel Power", Range(0, 10)) = 3.0
		[HDR]_FresnelColor ("Fresnel Color", Color) = (1, 1, 1, 1)
		_NormalMap("Normal Map", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
	    sampler2D _NormalMap;
        
		struct Input
        {
            float2 uv_MainTex;
			float2 uv_NormalMap;
			float3 viewDir;
			float4 tangent;
			float3 worldNormal;
			INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		float _FresnelPow;
		fixed4 _FresnelColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

			float3 tNormalMap = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));

			float3 wNormal = WorldNormalVector(IN, o.Normal);
			float3 wTangent = normalize(IN.tangent.xyz);
			float3 wBinormal = normalize(cross(wNormal, wTangent) * IN.tangent.w);
			float3x3 tangentToWorld = transpose(float3x3(wTangent, wBinormal, wNormal));

			float3 wNormalMap = mul(tangentToWorld, tNormalMap);
			float3 blendNormal = normalize(lerp(wNormal, wNormalMap, 0.5));

			float fresnel = saturate(dot(IN.viewDir, blendNormal));
			fresnel = 1 - fresnel;
			fresnel = pow(fresnel, _FresnelPow);
			o.Emission = _FresnelColor * fresnel;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
