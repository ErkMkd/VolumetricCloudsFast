in {
	tex2D diffuse_map;
	vec4 teint;
	float scale;
	vec3 sun_dir;
	vec3 sun_color;
	vec3 ambient_color;
	float absorption_factor;
}

variant {
	vertex {
		out {
			float front_face;
			vec2 v_uv;
			vec3 position;
		}

		source %{
			v_uv = vUV0;
			vec3 face_normal = vNormalViewMatrix * vNormal;
			vec3 model_pos = (_mtx_mul(vModelViewMatrix, vec4(0,0,0, 1.0))).xyz;
			front_face = abs(dot(face_normal,normalize(model_pos)));
			position = vNormalMatrix * (vPosition * scale);
		%}
	}

	pixel {
		global %{
			//r_pos : ray origin in sphere space
			vec2 sphere_intersect(vec3 r_pos, vec3 r_dir, float s_r)
			{
				const float EPSILON=1e-2;
				float t1,t2;
				 //Determinant:
				float a=r_dir.x*r_dir.x+r_dir.y*r_dir.y+r_dir.z*r_dir.z;
				float b=2.*(r_pos.x*r_dir.x+r_pos.y*r_dir.y+r_pos.z*r_dir.z);
				float c=r_pos.x*r_pos.x+r_pos.y*r_pos.y+r_pos.z*r_pos.z-s_r*s_r;

				float delta=b*b-4.*a*c;
				if(delta>0.)
				{
					delta=sqrt(delta);
					t1=(-b-delta)/(2.*a);
					t2=(-b+delta)/(2.*a);
					if(t1>EPSILON && t2 >EPSILON)
					{
						if(t2<t1) return vec2(t2,t1);
						else return vec2(t1,t2);
					}

					else if(t1>EPSILON && t2<=EPSILON)
					{
						return vec2(t1,t2);
					}
					else if(t1<=EPSILON && t2>EPSILON)
					{
						return vec2(t2,t1);
					}
				}

				else if (delta==0.)
				{
					t1=-b/2.*a;
					if(t1>EPSILON) return vec2(t1,t1);
				}
				return vec2(0.,0.);
			}
		%}
		
		source %{
			vec4 c_texture = texture2D(diffuse_map, v_uv);// * vec4(teint.rgb,1.);
			vec3 c_cloud=c_texture.rgb*teint.rgb;
			vec2 v_ray=sphere_intersect(position,-sun_dir,scale/2.);
			float absorption = exp(-v_ray.x*absorption_factor);
			%diffuse% = vec3(0,0,0);
			%specular% = vec3(0.,0.,0.);
			%opacity% = c_texture.a*teint.a*front_face;
			%constant% = mix(ambient_color*c_cloud,sun_color*c_cloud,absorption);
		%}
	}
}

surface {
	blend:alpha,
	z-write:True,
	
	//blend:opaque,
	//alpha-test:True,
	//alpha_threshold:0.9,
	double-sided:True
	}
