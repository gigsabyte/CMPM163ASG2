/*
*	Phong Outline Shader
*	Multi-pass shader that renders objects with Phong lighting, emissiveness, and an emissive outline.
*	When the object is blocked by another object, the outline is still visible.
*	Written by Gigi Bachtel. 
*   Based on Phong and Outline shaders written byb Angus Forbes and Manu.
*	Also used the following blog post as reference for the X-Ray component of the shader:
*	https://lindenreid.wordpress.com/2018/03/17/x-ray-shader-tutorial-in-unity/
*
*/

Shader "Custom/PhongOutline"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1) //The color of our object
        _EmmisiveColor("Emmisive Color", Color) = (1, 1, 1, 1) // emissive color
        _Emissiveness("Emmissiveness", Range(0,10)) = 0 // how emissive
        _Shininess ("Shininess", Float) = 10 //Shininess
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1) //Specular highlights color
        _MainTex ("Texture", 2D) = "white" {} // main texture
		_Outline ("Outline", Float) = 0.1 // outline width
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1) // outline color
		_OutlineEmmisiveColor("Emmisive Color", Color) = (1, 1, 1, 1) // outline emissive color
        _OutlineEmissiveness("Emmissiveness", Range(0,10)) = 0 // how emissive outline is
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		Pass
        {
			// stencil that checks if the other pass is drawn
			// and draws even if it the other one doesn't
			Stencil {
			  Ref 3
			  Comp Greater
			  Fail keep
			  Pass replace
			}

			// cull front, turn off z writing, always check ztest
			Cull Front
			ZWrite Off
			ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			uniform float4 _OutlineEmmisiveColor;
            uniform float _OutlineEmissiveness;  
			float _Outline;
			fixed4 _OutlineColor;


            v2f vert (appdata v)
            {
                v2f o;

				// make outline expand vertex by using normal values
				float4 outline = float4(v.normal.x, v.normal.y, v.normal.z, 1) * _Outline;
				// add to vertex value
				o.vertex = v.vertex + outline ;
                o.vertex = UnityObjectToClipPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                return float4 (_OutlineEmmisiveColor * _OutlineEmissiveness + _OutlineColor);
            }
            ENDCG
        }

        Pass
        {
			// write to stencil
			Stencil {
				Ref 4
				Comp always
				Pass replace
				ZFail keep
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
               float4 vertex : SV_POSITION;
               float3 normal : NORMAL;       
               float3 vertexInWorldCoords : TEXCOORD1;
               float2 uv: TEXCOORD0;
            };

            uniform float4 _LightColor0; //From UnityCG
            uniform float4 _Color; 
            uniform float4 _SpecColor;
            uniform float _Shininess;
    
            uniform float4 _EmmisiveColor;
            uniform float _Emissiveness;   
            sampler _MainTex; 

            v2f vert (appdata v)
            {
                v2f o;
                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normal = v.normal; //Normal 
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex); 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				// Phong lighting calculations
               float3 P = i.vertexInWorldCoords.xyz;
                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos - P);
                float3 L = normalize(_WorldSpaceLightPos0.xyz - P);
                float3 H = normalize(L + V);
                
                float3 Kd = _Color.rgb; //Color of object
                float3 Ka = UNITY_LIGHTMODEL_AMBIENT.rgb; //Ambient light
                //float3 Ka = float3(0,0,0); //UNITY_LIGHTMODEL_AMBIENT.rgb; //Ambient light
                float3 Ks = _SpecColor.rgb; //Color of specular highlighting
                float3 Kl = _LightColor0.rgb; //Color of light
                
                
                //AMBIENT LIGHT 
                float3 ambient = Ka;
                
               
                //DIFFUSE LIGHT
                float diffuseVal = max(dot(N, L), 0);
                float3 diffuse = Kd * Kl * diffuseVal;
                
                
                //SPECULAR LIGHT
                float specularVal = pow(max(dot(N,H), 0), _Shininess);
                
                if (diffuseVal <= 0) {
                    specularVal = 0;
                }
                
                float3 specular = Ks * Kl * specularVal;
                
                float4 texColor = tex2D(_MainTex, i.uv);
                //FINAL COLOR OF FRAGMENT
				
				// add emissive to final color
                return float4(_EmmisiveColor * _Emissiveness + ambient+ diffuse + specular, 1.0)*texColor;
            }
            ENDCG
        }
    }
}
