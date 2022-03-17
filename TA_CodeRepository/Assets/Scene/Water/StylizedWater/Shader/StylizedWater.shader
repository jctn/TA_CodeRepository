// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "StylizedWater"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_ShallowColor("ShallowColor", Color) = (0.06875221,0.7281977,0.9716981,1)
		_DepthColor("DepthColor", Color) = (0.1045626,0,0.990566,1)
		_DeepthRange("DeepthRange", Float) = 1
		_FresnelColor("FresnelColor", Color) = (0.03964933,0.6732354,0.9339623,1)
		_FresnelPower("FresnelPower", Float) = 5
		_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalScale("NormalScale", Float) = 1
		_NormalSpeed("NormalSpeed", Vector) = (1,0,0,0)
		_ReflectionDistort("ReflectionDistort", Float) = 1
		_RefractionDistort("RefractionDistort", Float) = 1
		_CausticsTex("CausticsTex", 2D) = "white" {}
		_CausticsScale("Caustics Scale", Float) = 0
		_CausticsRange("Caustics Range", Float) = 1
		_CausticsIntensity("Caustics Intensity", Float) = 0
		_ShoreRange("Shore Range", Float) = 0
		_ShoreColor("Shore Color", Color) = (0,0,0,0)
		_ShoreEdgeWidth("Shore Edge Width", Range( 0 , 1)) = 0
		_ShoreEdgeIntensity("Shore Edge Intensity", Float) = 0
		_FoamRange("Foam Range", Float) = 0
		_FoamSpeed("Foam Speed", Float) = 1
		_FoamFrequency("Foam  Frequency", Float) = 0
		_FoamSoft("Foam Soft", Range( 0 , 5)) = 0
		_FoamNoiseTiling("Foam Noise Tiling", Vector) = (0,0,0,0)
		_FoamDissolve("Foam Dissolve", Float) = 0
		_FoamShoreRange("Foam Shore Range", Range( 0 , 1)) = 0
		[ASEEnd]_FoamColor("Foam Color", Color) = (1,1,1,1)

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull Back
		AlphaToMask Off
		
		HLSLINCLUDE
		#pragma target 2.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#define ASE_SRP_VERSION 999999
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _DepthColor;
			float4 _ShoreColor;
			float4 _FresnelColor;
			float4 _FoamColor;
			float4 _ShallowColor;
			float2 _FoamNoiseTiling;
			float2 _NormalSpeed;
			float _FresnelPower;
			float _FoamSpeed;
			float _FoamFrequency;
			float _FoamShoreRange;
			float _FoamRange;
			float _FoamSoft;
			float _ShoreEdgeIntensity;
			float _ShoreRange;
			float _DeepthRange;
			float _FoamDissolve;
			float _CausticsIntensity;
			float _CausticsScale;
			float _RefractionDistort;
			float _ReflectionDistort;
			float _NormalScale;
			float _ShoreEdgeWidth;
			float _CausticsRange;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;
			sampler2D _ReflectionTex;
			sampler2D _NormalMap;
			sampler2D _CameraOpaqueTexture;
			sampler2D _CausticsTex;


			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDirURP75_g1( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION == 70600 || ASE_SRP_VERSION == 70700 || ASE_SRP_VERSION == 70701 || ASE_SRP_VERSION >= 80301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			
			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float3 customSurfaceDepth116 = v.vertex.xyz;
				float customEye116 = -TransformWorldToView(TransformObjectToWorld( customSurfaceDepth116 )).z;
				o.ase_texcoord4.w = customEye116;
				
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 UV22_g3 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g3 = UnStereo( UV22_g3 );
				float2 break64_g1 = localUnStereo22_g3;
				float clampDepth69_g1 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g1 = ( 1.0 - clampDepth69_g1 );
				#else
				float staticSwitch38_g1 = clampDepth69_g1;
				#endif
				float3 appendResult39_g1 = (float3(break64_g1.x , break64_g1.y , staticSwitch38_g1));
				float4 appendResult42_g1 = (float4((appendResult39_g1*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g1 = mul( unity_CameraInvProjection, appendResult42_g1 );
				float3 temp_output_46_0_g1 = ( (temp_output_43_0_g1).xyz / (temp_output_43_0_g1).w );
				float3 In75_g1 = temp_output_46_0_g1;
				float3 localInvertDepthDirURP75_g1 = InvertDepthDirURP75_g1( In75_g1 );
				float4 appendResult49_g1 = (float4(localInvertDepthDirURP75_g1 , 1.0));
				float4 PositionFromDepth121 = mul( unity_CameraToWorld, appendResult49_g1 );
				float WaterDepth10 = ( WorldPosition.y - (PositionFromDepth121).y );
				float4 lerpResult15 = lerp( _DepthColor , _ShallowColor , saturate( exp( ( -WaterDepth10 / max( _DeepthRange , 0.0001 ) ) ) ));
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float fresnelNdotV27 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode27 = ( 0.0 + 1.0 * pow( max( 1.0 - fresnelNdotV27 , 0.0001 ), _FresnelPower ) );
				float4 lerpResult26 = lerp( lerpResult15 , _FresnelColor , fresnelNode27);
				float4 WaterColor16 = lerpResult26;
				float2 temp_output_103_0 = ( (WorldPosition).xz / ( _NormalScale * 5.0 ) );
				float2 temp_output_36_0 = ( _TimeParameters.x * _NormalSpeed * 0.1 );
				float3 SufaceNormal55 = BlendNormal( UnpackNormalScale( tex2D( _NormalMap, ( temp_output_103_0 + temp_output_36_0 ) ), 1.0f ) , UnpackNormalScale( tex2D( _NormalMap, ( ( temp_output_103_0 * 2.0 ) + ( temp_output_36_0 * -0.5 ) ) ), 1.0f ) );
				float4 ReflectionColor66 = tex2D( _ReflectionTex, ( (ase_screenPosNorm).xy + ( (SufaceNormal55).xy * ( _ReflectionDistort * 0.01 ) ) ) );
				float customEye116 = IN.ase_texcoord4.w;
				float2 temp_output_71_0 = (ase_screenPosNorm).xy;
				float2 temp_output_93_0 = ( temp_output_71_0 + ( (SufaceNormal55).xy * ( _RefractionDistort * 0.01 ) ) );
				float eyeDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( float4( temp_output_93_0, 0.0 , 0.0 ).xy ),_ZBufferParams);
				float2 ifLocalVar120 = 0;
				if( ( customEye116 - eyeDepth115 ) <= 0.0 )
				ifLocalVar120 = temp_output_93_0;
				else
				ifLocalVar120 = temp_output_71_0;
				float4 tex2DNode95 = tex2D( _CameraOpaqueTexture, ifLocalVar120 );
				float2 temp_output_132_0 = ( (PositionFromDepth121).xz / _CausticsScale );
				float2 temp_output_136_0 = ( _TimeParameters.x * float2( -1,0 ) * 0.1 );
				float4 CausticsColor140 = ( ( min( tex2D( _CausticsTex, ( temp_output_132_0 + temp_output_136_0 ) ) , tex2D( _CausticsTex, ( -temp_output_132_0 + temp_output_136_0 ) ) ) * _CausticsIntensity ) * saturate( exp( ( -WaterDepth10 / max( _CausticsRange , 0.0001 ) ) ) ) );
				float4 UnderwaterColor143 = ( tex2DNode95 + CausticsColor140 );
				float WaterTransparent29 = ( 1.0 - (lerpResult26).a );
				float4 lerpResult101 = lerp( ( WaterColor16 + ReflectionColor66 ) , UnderwaterColor143 , WaterTransparent29);
				float4 RefractionColor96 = tex2DNode95;
				float4 ShoreColor173 = ( RefractionColor96 * _ShoreColor );
				float WaterShore168 = exp( ( -WaterDepth10 / ( _ShoreRange * 0.1 ) ) );
				float4 lerpResult179 = lerp( lerpResult101 , ShoreColor173 , WaterShore168);
				float smoothstepResult182 = smoothstep( ( 1.0 - _ShoreEdgeWidth ) , 1.1 , WaterShore168);
				float ShoreEdgeColor183 = ( smoothstepResult182 * _ShoreEdgeIntensity );
				float clampResult195 = clamp( ( WaterDepth10 / _FoamRange ) , 0.0 , 1.0 );
				float temp_output_196_0 = ( 1.0 - clampResult195 );
				float smoothstepResult204 = smoothstep( 0.0 , _FoamSoft , temp_output_196_0);
				float2 texCoord211 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float gradientNoise208 = GradientNoise(( texCoord211 * _FoamNoiseTiling ),1.0);
				gradientNoise208 = gradientNoise208*0.5 + 0.5;
				float4 FoamColor207 = ( ( smoothstepResult204 * step( max( ( temp_output_196_0 - _FoamShoreRange ) , 0.0 ) , ( ( sin( ( ( temp_output_196_0 * _FoamFrequency ) + ( _TimeParameters.x * _FoamSpeed ) ) ) + gradientNoise208 ) - _FoamDissolve ) ) ) * _FoamColor );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = max( ( lerpResult179 + ShoreEdgeColor183 + FoamColor207 ) , float4( 0,0,0,0 ) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18921
24;685;2071;1045;-1195.003;938.4324;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;32;-2615.207,740.9111;Inherit;False;1945.023;669.8489;SurfaceNormal;20;53;33;34;36;55;54;52;51;49;48;50;41;39;72;103;104;124;125;126;129;SurfaceNormal;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-2302.393,896.3015;Inherit;False;Property;_NormalScale;NormalScale;6;0;Create;True;0;0;0;False;0;False;1;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;125;-2293.408,981.3068;Inherit;False;Constant;_Float5;Float 5;12;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;33;-2542.849,794.1531;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;129;-2553.732,992.0485;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;124;-2550.598,1102.369;Inherit;False;Property;_NormalSpeed;NormalSpeed;7;0;Create;True;0;0;0;False;0;False;1,0;1.5,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;104;-2549.536,1232.219;Inherit;False;Constant;_Float4;Float 4;11;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;34;-2259.489,802.4071;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-2126.408,915.3068;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;11;-2572.007,-795.1033;Inherit;False;1230.6;468.1;WaterDepth;6;8;10;9;6;7;121;WaterDepth;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-2027.362,1241.213;Inherit;False;Constant;_Float1;Float 1;1;0;Create;True;0;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-2258.391,1106.033;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-2016.362,1060.213;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;103;-1996.536,823.2185;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-1829.362,1184.213;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;6;-2548.33,-586.609;Inherit;False;Reconstruct World Position From Depth;-1;;1;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-1848.362,1049.213;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;52;-1654.362,1120.213;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;121;-2201.066,-590.8875;Inherit;False;PositionFromDepth;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;-1809.393,830.3015;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;144;-2630.715,3617.09;Inherit;False;2300.001;903.3113;CausticsColor;25;140;139;138;136;133;135;134;132;131;130;146;147;148;149;150;151;152;153;155;156;157;158;159;160;161;CausticsColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;72;-1495.7,800.6145;Inherit;True;Property;_NormalMap;NormalMap;5;0;Create;True;0;0;0;False;0;False;-1;None;c3a778bb5af5c8e4d821248ca5961513;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;53;-1490.362,1064.213;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;72;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;7;-1980.533,-593.1311;Inherit;False;FLOAT;1;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;8;-2116.932,-741.6314;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;130;-2523.337,3665.708;Inherit;False;121;PositionFromDepth;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BlendNormalsNode;54;-1159.362,943.2126;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;9;-1840.336,-693.0315;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;191;676.5015,59.19043;Inherit;False;2424.168;1224.099;WaterFoam;29;207;206;201;204;197;205;199;202;198;200;203;196;195;193;192;194;208;211;212;214;215;218;219;220;221;222;223;224;225;WaterFoam;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;10;-1661.601,-698.1651;Inherit;False;WaterDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;-936.4757,937.9644;Inherit;False;SufaceNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;131;-2264.561,3668.071;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;97;-2622.103,2350.086;Inherit;False;2220.367;1105.063;UnderwaterColor;19;96;95;120;119;116;115;93;117;71;92;88;91;94;87;89;90;141;142;143;UnderwaterColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-2322.739,3823.663;Inherit;False;Property;_CausticsScale;Caustics Scale;13;0;Create;True;0;0;0;False;0;False;0;13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-2573.19,3088.063;Inherit;False;Property;_RefractionDistort;RefractionDistort;11;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;192;750.1947,351.8091;Inherit;False;10;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;194;756.0204,481.4499;Inherit;False;Property;_FoamRange;Foam Range;20;0;Create;True;0;0;0;False;0;False;0;0.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;132;-2050.79,3760.073;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-2528.259,4142.107;Inherit;False;Constant;_Float6;Float 6;14;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;-2561.201,2948.015;Inherit;False;55;SufaceNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;155;-2533.404,4015.914;Inherit;False;Constant;_Vector0;Vector 0;15;0;Create;True;0;0;0;False;0;False;-1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;89;-2566.381,3194.074;Inherit;False;Constant;_Float3;Float 3;9;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;17;-2624.253,-195.442;Inherit;False;1899.691;843.1625;WaterColor;18;30;31;29;22;24;16;26;25;15;20;19;13;27;21;14;12;23;28;WaterColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;135;-2524.335,3924.031;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-1844.473,4361.84;Inherit;False;Property;_CausticsRange;Caustics Range;14;0;Create;True;0;0;0;False;0;False;1;1.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;94;-2420.449,2710.857;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;136;-2318.681,3978.201;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;147;-1850.784,4265.548;Inherit;False;10;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;156;-1874.684,3952.226;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-2287.304,3159.769;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;12;-2565.834,318.0116;Inherit;False;10;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;91;-2303.877,2949.96;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;193;1005.718,356.7191;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-2555.523,415.3003;Inherit;False;Property;_DeepthRange;DeepthRange;2;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;134;-1869.49,3791.192;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;195;1167.779,343.8279;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;149;-1645.473,4356.84;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;20;-2381.737,322.7755;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;157;-1742.86,4059.049;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;23;-2360.523,409.3003;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;148;-1666.687,4270.313;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;71;-2149.782,2723.912;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-2116.448,2990.857;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;200;1080.629,722.2312;Inherit;False;Property;_FoamSpeed;Foam Speed;21;0;Create;True;0;0;0;False;0;False;1;-3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;198;1091.487,612.4824;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;69;-2593.658,1559.14;Inherit;False;1838.972;683.3256;ReflectionColor;11;65;57;56;66;67;61;62;59;63;58;68;ReflectionColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;196;1348.131,337.7382;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;117;-2166.332,2462.261;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;150;-1519.474,4268.837;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;158;-1595.123,3985.179;Inherit;True;Property;_TextureSample1;Texture Sample 1;12;0;Create;True;0;0;0;False;0;False;-1;None;b3ffe1167e0e73b4b8993139e504e03a;True;0;False;white;Auto;False;Instance;139;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;93;-1975.341,2855.527;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;203;1295.192,498.7864;Inherit;False;Property;_FoamFrequency;Foam  Frequency;22;0;Create;True;0;0;0;False;0;False;0;16.35;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;21;-2234.524,321.3003;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;139;-1594.426,3760.975;Inherit;True;Property;_CausticsTex;CausticsTex;12;0;Create;True;0;0;0;False;0;False;-1;None;b3ffe1167e0e73b4b8993139e504e03a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SurfaceDepthNode;116;-1977.359,2464.211;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-2518.658,2081.944;Inherit;False;Constant;_Float2;Float 2;7;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;214;1092.292,1017.201;Inherit;False;Property;_FoamNoiseTiling;Foam Noise Tiling;24;0;Create;True;0;0;0;False;0;False;0,0;16.6,10;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;161;-1259.524,4012.458;Inherit;False;Property;_CausticsIntensity;Caustics Intensity;15;0;Create;True;0;0;0;False;0;False;0;7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;202;1502.192,442.7865;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;58;-2543.658,1851.944;Inherit;False;55;SufaceNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ExpOpNode;151;-1357.474,4267.837;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;115;-1905.87,2626.737;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ExpOpNode;24;-2072.524,320.3003;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;159;-1234.883,3882.902;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;162;-2616.856,4702.694;Inherit;False;2330.473;955.1616;Water Shore;18;163;164;165;166;167;168;169;170;171;173;177;178;180;181;182;183;184;185;Water Shore;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;199;1328.762,695.0718;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;211;1075.392,848.601;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;61;-2526.658,1971.943;Inherit;False;Property;_ReflectionDistort;ReflectionDistort;9;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;178;-2395.178,5116.075;Inherit;False;Constant;_Float7;Float 7;18;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;13;-2218.931,-118.9269;Inherit;False;Property;_DepthColor;DepthColor;1;0;Create;True;0;0;0;False;0;False;0.1045626,0,0.990566,1;0,0.2251551,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;59;-2306.658,1853.943;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;119;-1698.385,2584.869;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;197;1666.376,566.6418;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;164;-2428.805,4899.376;Inherit;False;10;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;1431.593,875.9014;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;19;-1945.954,320.4323;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;56;-2521.241,1614.903;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;163;-2403.983,5033.605;Inherit;False;Property;_ShoreRange;Shore Range;16;0;Create;True;0;0;0;False;0;False;0;3.62;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-2294.658,2027.944;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;160;-1062.51,3881.497;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;152;-1230.904,4267.969;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;28;-1961.383,502.0602;Inherit;False;Property;_FresnelPower;FresnelPower;4;0;Create;True;0;0;0;False;0;False;5;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;14;-2224.282,74.69733;Inherit;False;Property;_ShallowColor;ShallowColor;0;0;Create;True;0;0;0;False;0;False;0.06875221,0.7281977,0.9716981,1;0.5707546,0.8047355,1,0.2470588;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;177;-2213.178,5076.075;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;15;-1750.299,29.54208;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ConditionalIfNode;120;-1522.296,2657.112;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;57;-2127.88,1624.943;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;153;-881.2765,3999.087;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FresnelNode;27;-1735.985,411.486;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-2090.657,1846.943;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;208;1607.312,866.1656;Inherit;False;Gradient;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-1737.096,192.729;Inherit;False;Property;_FresnelColor;FresnelColor;3;0;Create;True;0;0;0;False;0;False;0.03964933,0.6732354,0.9339623,1;0,0.3782668,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SinOpNode;201;1823.006,574.0518;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;166;-2183.446,4908.683;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;222;1802.299,470.6823;Inherit;False;Property;_FoamShoreRange;Foam Shore Range;26;0;Create;True;0;0;0;False;0;False;0;0.676;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;95;-1308.023,2668.838;Inherit;True;Global;_CameraOpaqueTexture;_CameraOpaqueTexture;10;0;Create;True;0;0;0;False;0;False;-1;None;;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;219;1993.899,836.1343;Inherit;False;Property;_FoamDissolve;Foam Dissolve;25;0;Create;True;0;0;0;False;0;False;0;1.38;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;140;-706.2563,3998.413;Inherit;False;CausticsColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;68;-1906.657,1737.943;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;215;1969.039,681.6854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;26;-1399.028,66.57346;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;165;-2003.203,4907.608;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;221;2074.346,379.9991;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;30;-1239.456,298.6377;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;65;-1730.682,1710.968;Inherit;True;Global;_ReflectionTex;_ReflectionTex;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;223;2226.293,388.1436;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;205;1881.397,158.7445;Inherit;False;Property;_FoamSoft;Foam Soft;23;0;Create;True;0;0;0;False;0;False;0;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;218;2151.621,690.0789;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;142;-1147.441,3034.22;Inherit;False;140;CausticsColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ExpOpNode;167;-1849.947,4916.238;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;96;-959.8955,2671.477;Inherit;False;RefractionColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;180;-1757.918,5043.313;Inherit;False;Property;_ShoreEdgeWidth;Shore Edge Width;18;0;Create;True;0;0;0;False;0;False;0;0.28;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;141;-897.0548,2900.29;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;66;-1370.657,1750.943;Inherit;False;ReflectionColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;204;2193.61,230.733;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;181;-1449.819,5049.814;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-1693.808,4921.996;Inherit;False;WaterShore;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;31;-1106.487,302.8188;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;16;-1158.574,62.26362;Inherit;False;WaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;220;2371.355,565.6989;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;169;-2412.4,5234.21;Inherit;False;96;RefractionColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;171;-2425.637,5347.256;Inherit;False;Property;_ShoreColor;Shore Color;17;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.9339623,0.9339623,0.9339623,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;206;2497.293,347.9395;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;225;2531.84,577.9144;Inherit;False;Property;_FoamColor;Foam Color;27;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;98;987.2847,-923.6809;Inherit;False;66;ReflectionColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;18;1018.477,-1038.706;Inherit;False;16;WaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;29;-941.4874,299.8188;Inherit;False;WaterTransparent;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;182;-1289.918,4932.814;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;185;-1308.819,5144.712;Inherit;False;Property;_ShoreEdgeIntensity;Shore Edge Intensity;19;0;Create;True;0;0;0;False;0;False;0;0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;143;-731.5932,2865.902;Inherit;False;UnderwaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;170;-2091.595,5244.393;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;102;1291.542,-1002.211;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;99;1195.285,-759.648;Inherit;False;143;UnderwaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;173;-1837.724,5257.415;Inherit;False;ShoreColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;2751.74,389.1144;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;184;-1053.018,4931.514;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;100;1188.285,-644.8101;Inherit;False;29;WaterTransparent;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;176;1626.433,-531.6495;Inherit;False;168;WaterShore;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;183;-756.489,4931.825;Inherit;False;ShoreEdgeColor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;1625.618,-673.5452;Inherit;False;173;ShoreColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;207;2895.621,398.2352;Inherit;False;FoamColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;101;1518.885,-819.5809;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;179;1891.924,-716.541;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;226;1902.003,-434.4324;Inherit;False;207;FoamColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;188;1880.735,-572.4023;Inherit;False;183;ShoreEdgeColor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;190;2129.337,-651.7855;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;189;2312.736,-671.4022;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;83;296.0227,6.989027;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;85;296.0227,6.989027;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;82;2486.773,-692.1457;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;StylizedWater;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;84;296.0227,6.989027;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;81;1990.786,-848.5622;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;RefractionMask;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=RefractionMask;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;34;0;33;0
WireConnection;126;0;39;0
WireConnection;126;1;125;0
WireConnection;36;0;129;0
WireConnection;36;1;124;0
WireConnection;36;2;104;0
WireConnection;103;0;34;0
WireConnection;103;1;126;0
WireConnection;50;0;36;0
WireConnection;50;1;51;0
WireConnection;48;0;103;0
WireConnection;48;1;49;0
WireConnection;52;0;48;0
WireConnection;52;1;50;0
WireConnection;121;0;6;0
WireConnection;41;0;103;0
WireConnection;41;1;36;0
WireConnection;72;1;41;0
WireConnection;53;1;52;0
WireConnection;7;0;121;0
WireConnection;54;0;72;0
WireConnection;54;1;53;0
WireConnection;9;0;8;2
WireConnection;9;1;7;0
WireConnection;10;0;9;0
WireConnection;55;0;54;0
WireConnection;131;0;130;0
WireConnection;132;0;131;0
WireConnection;132;1;133;0
WireConnection;136;0;135;0
WireConnection;136;1;155;0
WireConnection;136;2;138;0
WireConnection;156;0;132;0
WireConnection;88;0;87;0
WireConnection;88;1;89;0
WireConnection;91;0;90;0
WireConnection;193;0;192;0
WireConnection;193;1;194;0
WireConnection;134;0;132;0
WireConnection;134;1;136;0
WireConnection;195;0;193;0
WireConnection;149;0;146;0
WireConnection;20;0;12;0
WireConnection;157;0;156;0
WireConnection;157;1;136;0
WireConnection;23;0;22;0
WireConnection;148;0;147;0
WireConnection;71;0;94;0
WireConnection;92;0;91;0
WireConnection;92;1;88;0
WireConnection;196;0;195;0
WireConnection;150;0;148;0
WireConnection;150;1;149;0
WireConnection;158;1;157;0
WireConnection;93;0;71;0
WireConnection;93;1;92;0
WireConnection;21;0;20;0
WireConnection;21;1;23;0
WireConnection;139;1;134;0
WireConnection;116;0;117;0
WireConnection;202;0;196;0
WireConnection;202;1;203;0
WireConnection;151;0;150;0
WireConnection;115;0;93;0
WireConnection;24;0;21;0
WireConnection;159;0;139;0
WireConnection;159;1;158;0
WireConnection;199;0;198;0
WireConnection;199;1;200;0
WireConnection;59;0;58;0
WireConnection;119;0;116;0
WireConnection;119;1;115;0
WireConnection;197;0;202;0
WireConnection;197;1;199;0
WireConnection;212;0;211;0
WireConnection;212;1;214;0
WireConnection;19;0;24;0
WireConnection;62;0;61;0
WireConnection;62;1;63;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;152;0;151;0
WireConnection;177;0;163;0
WireConnection;177;1;178;0
WireConnection;15;0;13;0
WireConnection;15;1;14;0
WireConnection;15;2;19;0
WireConnection;120;0;119;0
WireConnection;120;2;71;0
WireConnection;120;3;93;0
WireConnection;120;4;93;0
WireConnection;57;0;56;0
WireConnection;153;0;160;0
WireConnection;153;1;152;0
WireConnection;27;3;28;0
WireConnection;67;0;59;0
WireConnection;67;1;62;0
WireConnection;208;0;212;0
WireConnection;201;0;197;0
WireConnection;166;0;164;0
WireConnection;95;1;120;0
WireConnection;140;0;153;0
WireConnection;68;0;57;0
WireConnection;68;1;67;0
WireConnection;215;0;201;0
WireConnection;215;1;208;0
WireConnection;26;0;15;0
WireConnection;26;1;25;0
WireConnection;26;2;27;0
WireConnection;165;0;166;0
WireConnection;165;1;177;0
WireConnection;221;0;196;0
WireConnection;221;1;222;0
WireConnection;30;0;26;0
WireConnection;65;1;68;0
WireConnection;223;0;221;0
WireConnection;218;0;215;0
WireConnection;218;1;219;0
WireConnection;167;0;165;0
WireConnection;96;0;95;0
WireConnection;141;0;95;0
WireConnection;141;1;142;0
WireConnection;66;0;65;0
WireConnection;204;0;196;0
WireConnection;204;2;205;0
WireConnection;181;0;180;0
WireConnection;168;0;167;0
WireConnection;31;0;30;0
WireConnection;16;0;26;0
WireConnection;220;0;223;0
WireConnection;220;1;218;0
WireConnection;206;0;204;0
WireConnection;206;1;220;0
WireConnection;29;0;31;0
WireConnection;182;0;168;0
WireConnection;182;1;181;0
WireConnection;143;0;141;0
WireConnection;170;0;169;0
WireConnection;170;1;171;0
WireConnection;102;0;18;0
WireConnection;102;1;98;0
WireConnection;173;0;170;0
WireConnection;224;0;206;0
WireConnection;224;1;225;0
WireConnection;184;0;182;0
WireConnection;184;1;185;0
WireConnection;183;0;184;0
WireConnection;207;0;224;0
WireConnection;101;0;102;0
WireConnection;101;1;99;0
WireConnection;101;2;100;0
WireConnection;179;0;101;0
WireConnection;179;1;175;0
WireConnection;179;2;176;0
WireConnection;190;0;179;0
WireConnection;190;1;188;0
WireConnection;190;2;226;0
WireConnection;189;0;190;0
WireConnection;82;2;189;0
ASEEND*/
//CHKSM=5964F8EF560C9C2B2983DCA1911C1BF68998031B