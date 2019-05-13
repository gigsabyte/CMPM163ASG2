/*
* Reflection.Shader
* Simple reflection shader that lerps between reflecting/refracting the skybox.
* Also contains minor vertex displacement to mimic the rising and falling of the tide.
* Written by Angus Forbes and modified by Gigi Bachtel.
*
*/
Shader "Custom/Reflection" {
    Properties {
      
      _Cube ("Cubemap", CUBE) = "" {}
    }
     SubShader
    {
		Tags {"RenderType" = "Transparent"}
        Pass
        {
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
                float3 normalInWorldCoords : NORMAL;
                float3 vertexInWorldCoords : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
				v.vertex.y += sin(v.vertex.z) * 4 * cos(_Time.y)/2; // mess with the vertex y a bit

                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal 
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                return o;
            }
            
            samplerCUBE _Cube; // skybox cube texture
            
            fixed4 frag (v2f i) : SV_Target
            {
            
			 // position
             float3 P = i.vertexInWorldCoords.xyz;
             
             //get normalized incident ray (from camera to vertex)
             float3 vIncident = normalize(P - _WorldSpaceCameraPos);
             
             //reflect that ray around the normal using built-in HLSL command
             float3 vReflect = reflect( vIncident, i.normalInWorldCoords );
             
             
             //use the reflect ray to sample the skybox
             float4 reflectColor = texCUBE( _Cube, vReflect );
             
             //refract the incident ray through the surface using built-in HLSL command
             float3 vRefract = refract( vIncident, i.normalInWorldCoords, 0.5 );
                          
             // refract RGB values by arbitrary but different amounts
             float3 vRefractRed = refract( vIncident, i.normalInWorldCoords, 0.1 );
             float3 vRefractGreen = refract( vIncident, i.normalInWorldCoords, 0.4 );
             float3 vRefractBlue = refract( vIncident, i.normalInWorldCoords, 0.7 );
             
			 // sample the cube at the places where the refraction rays hit
             float4 refractColorRed = texCUBE( _Cube, float3( vRefractRed ) );
             float4 refractColorGreen = texCUBE( _Cube, float3( vRefractGreen ) );
             float4 refractColorBlue = texCUBE( _Cube, float3( vRefractBlue ) );

			 // get composite refraction color
             float4 refractColor = float4(refractColorRed.r, refractColorGreen.g, refractColorBlue.b, 1.0);
             
             
             return float4(lerp(reflectColor, refractColor, 0.8).rgb, 0.8);
                
                
            }
      
            ENDCG
        }
    }

    
    SubShader {
      Tags { "RenderType" = "Opaque" }
      CGPROGRAM
      #pragma surface surf Lambert
      struct Input {
          float2 uv_MainTex;
          float3 worldRefl;
      };
      sampler2D _MainTex;
      samplerCUBE _Cube;
      void surf (Input IN, inout SurfaceOutput o) {
          o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb * 0.5;
          o.Emission = texCUBE (_Cube, IN.worldRefl).rgb;
      }
      ENDCG
    } 
    Fallback "Diffuse"
  }
