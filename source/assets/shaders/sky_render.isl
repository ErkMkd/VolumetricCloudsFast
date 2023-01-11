/*

				Sky render - 2017		

*/

in {
	tex2D tex_sky_N [wrap-u: clamp, wrap-v: clamp];
	tex2D tex_sky_S [wrap-u: clamp, wrap-v: clamp];
	vec2 resolution;
	float focal_distance;
	
	vec3 zenith_color;
	vec3 nadir_color;
	float zenith_falloff;
	float nadir_falloff;
	vec3 horizonH_color;
	vec3 horizonL_color;
	vec3 horizon_line_color;
	float horizon_line_size;
	float tex_sky_N_intensity;
	float tex_sky_S_intensity;
	
	vec2 zFrustum;
	
	tex2D clouds_map [wrap-u: repeat, wrap-v: repeat];
	vec3 clouds_scale;
	float clouds_altitude;
	
	vec3 sun_dir;
	vec3 sun_color;
	vec3 ambient_color;
	
	float layer_far_scan_r;
	float far_clouds_absorption;
	
}

variant {
	
	//====================================================================================================
	
	vertex {
		out {
			vec2 v_uv;
			vec3 screen_ray; 
		}

		source %{
			v_uv = vUV0;
			//float ratio = resolution.x / resolution.y;
			//screen_ray=vec3(vPosition.x,vPosition.y,0.)*vec3(ratio,1.,0.)+vec3(0.,0.,focal_distance);
			
			vec4 clip = _mtx_mul(vInverseViewProjectionMatrixAtOrigin, vec4(vPosition, 1.0));
			screen_ray = clip.xyz / clip.w;

			
			%out.position% = vec4(vPosition, 1.0);
		%}
	}

	//====================================================================================================
	
	pixel {
			
		global %{
			
			#define M_PI 3.141592653
			#define GRAY_FACTOR_R 0.11
			#define GRAY_FACTOR_V 0.59
			#define GRAY_FACTOR_B 0.3
			
			// Get spherical coordinate texel:
			vec4 get_sky_texel(vec3 dir)
			{
				float phi,theta,v,r;
				vec2 uv;
				if (dir.y<0)
				{
					phi=asin(dir.y)+M_PI;
					v=acos(-dir.x/sqrt(pow(-dir.x,2)+pow(dir.z,2)));
				}
				else 
				{
					phi=asin(dir.y);
					v=acos(dir.x/sqrt(pow(dir.x,2)+pow(dir.z,2)));
				}
				if (dir.z>=0.) theta=v;
				else theta=2.*M_PI-v;
				
				r=0.5-phi/M_PI;
				uv=vec2(r*cos(theta),r*sin(theta))+vec2(0.5,0.5);
				if (dir.y<0) return texture2D(tex_sky_S,uv) * vec4(tex_sky_S_intensity,tex_sky_S_intensity,tex_sky_S_intensity,1.);
				else return texture2D(tex_sky_N,uv) * vec4(tex_sky_N_intensity,tex_sky_N_intensity,tex_sky_N_intensity,1.);
			}
			
			vec3 get_atmosphere_color(vec3 dir)
			{
				vec3 c_atmosphere;
				if (dir.y<-1e-4)c_atmosphere=mix(nadir_color,horizonL_color,pow(min(1.,1+dir.y),nadir_falloff));
				else if(dir.y>=-1e-4 && dir.y<1e-4) c_atmosphere=horizonH_color;
				else c_atmosphere=mix(zenith_color,horizonH_color,pow(min(1.,1-dir.y),zenith_falloff));
				return c_atmosphere;
			}
			
			
			float get_sun_intensity(vec3 dir, vec3 sun_dir)
			{
				float prod_scal = max(dot(sun_dir,-dir),0);
				return min(0.4*pow(prod_scal,7000) + 0.5 * pow(prod_scal,50) + 0.4 *pow(prod_scal,2),1);
			}
			
			
			vec3 get_sky_color(vec3 dir, vec3 c_atmosphere)
			{
				vec4 sky_col=get_sky_texel(dir);
				vec3 sky_tex=sky_col.rgb*sky_col.a;
				float sun_lum = get_sun_intensity(dir,sun_dir);
				float sky_lum=c_atmosphere.r*GRAY_FACTOR_R+c_atmosphere.g*GRAY_FACTOR_V+c_atmosphere.b*GRAY_FACTOR_B;
				return mix(c_atmosphere+sky_tex*(1-sky_lum),sun_color,sun_lum);
			}
			
			

			vec3 get_sky_color_no_sun(vec3 dir, vec3 c_atmosphere)
			{
				vec4 sky_col=get_sky_texel(dir);
				vec3 sky_tex=sky_col.rgb*sky_col.a;
				float sky_lum=c_atmosphere.r*GRAY_FACTOR_R+c_atmosphere.g*GRAY_FACTOR_V+c_atmosphere.b*GRAY_FACTOR_B;
				return c_atmosphere+sky_tex*(1-sky_lum);
			}
			
			float get_zDepth(float near,float far)
			{
					float a,b,z;
					z=far*near;
					a=zFrustum.y/(zFrustum.y-zFrustum.x);
					b=zFrustum.y*zFrustum.x/(zFrustum.x-zFrustum.y);
					return ((a+b/z)+1.)/2.;
			}
			
			
			//Clouds texture ======================================================
			
			float get_cloudTex_altitude(vec2 p)
			{
				float a=texture2D(clouds_map, p).r;
				return a*clouds_scale.y;
			}
			
			vec3 get_cloudTex_normale(vec2 pos)
			{
				float f=0.02;//0.02 for rt noise
				vec2 xd=vec2(f,0);
				vec2 zd=vec2(0,f);
				return normalize(vec3(
										get_cloudTex_altitude(pos-xd) - get_cloudTex_altitude(pos+xd),
										2.*f,
										get_cloudTex_altitude(pos-zd) - get_cloudTex_altitude(pos+zd)
									  ));
			}
			
			
			vec4 get_clouds_color(vec3 pos, vec3 dir)
			{
				float distance;
				vec4 c_cloud=vec4(0.,0.,0.,0.);
				if (pos.y>clouds_altitude && dir.y<-1e-4 || pos.y<clouds_altitude && dir.y>1e-4)
				{
					distance = (clouds_altitude-pos.y) / dot(vec3(0,1.,0),dir);
					vec2 p=(pos+distance*dir).xz*clouds_scale.xz;
					vec3 n_cloud=get_cloudTex_normale(p);
					c_cloud=texture2D(clouds_map, p);
					c_cloud.a=c_cloud.r * pow(min(1.,distance/layer_far_scan_r),4.);
					if (pos.y<clouds_altitude) n_cloud.y*=-1.;
					float light_cloud=dot(sun_dir,-n_cloud);
					vec3 dark_color=mix(sun_color,ambient_color,far_clouds_absorption);
					if (light_cloud<0.)c_cloud.rgb=mix(dark_color,sun_color,(1.-c_cloud.a)*-1.*light_cloud);
					else c_cloud.rgb=mix(dark_color,sun_color,light_cloud);
					
				}
				return c_cloud;
			}
			
		%}
		
	//====================================================================================================
		
		
		source %{
			vec3 screen_ray_dir = normalize(screen_ray);
			vec3 dir=screen_ray_dir; //normalize(cam_normal*screen_ray_dir);

			vec3 color;
			float distance;
			distance = zFrustum.y*0.9999;
			color = get_atmosphere_color(dir);
			color=get_sky_color(dir,color);
			vec4 clouds_color = get_clouds_color(vViewPosition.xyz,dir);
			color = mix(color,clouds_color.rgb,clouds_color.a);
	
	
			//Smooth horizon line:
			color = mix(color,horizon_line_color,pow(min(1.,1-abs(dir.y)),horizon_line_size));
	
			%out.color% =vec4(color,1.);
			//%out.depth%=get_zDepth(screen_ray_dir.z,min(distance,zFrustum.y*0.9999));
		%}
	}
}
