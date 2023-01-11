in {
	tex2D diffuse_map;
}

variant {
	vertex {
		out {
			vec2 v_uv;
		}

		source %{
			v_uv = vUV0;
		%}
	}

	pixel {
		source %{
			vec4 diffuse_color = texture2D(diffuse_map, v_uv);
			%diffuse% = vec3(0,0,0);
			%specular% = vec3(0.,0.,0.);
			%opacity% = diffuse_color.a;
			%constant% = diffuse_color.rgb;
		%}
	}
}

surface {
	blend:alpha,
	z-write:True,
	
	//blend:opaque,
	//alpha-test:True,
	//alpha_threshold:0.5,
	double-sided:True
	}
