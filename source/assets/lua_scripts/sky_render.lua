execution_context = hg.ScriptContextAll

--------------------------------------------------------------------------------
zenith_color_r = 0
zenith_color_g = 0
zenith_color_b = 0
horizon_N_color_r = 0
horizon_N_color_g = 1
horizon_N_color_b = 1
horizon_S_color_r = 0
horizon_S_color_g = 0
horizon_S_color_b = 1
nadir_color_r = 0
nadir_color_g = 0
nadir_color_b = 0
nadir_falloff = 4.0
zenith_falloff = 4.0
horizon_line_color_r = 1
horizon_line_color_g = 1
horizon_line_color_b = 1
horizon_line_size = 40.0
tex_sky_N = renderer:LoadTexture("assets/skymaps/clouds.png")
tex_sky_S = renderer:LoadTexture("assets/skymaps/gabarit_sud.png")
clouds_map = renderer:LoadTexture("assets/clouds/maps/clouds_map_5.png")
tex_sky_N_intensity = 1.0
tex_sky_S_intensity = 1.0
z_near=1
z_far=1000
zoom_factor=1
resolution_x = 1920
resolution_y = 1080

sun_dir_x=0
sun_dir_y=0
sun_dir_z=0

sun_color_r=1
sun_color_g=1
sun_color_b=1

ambient_color_r=0.2
ambient_color_g=0.2
ambient_color_b=0.2

clouds_scale_x=5000
far_clouds_scale_y=0.1
clouds_scale_z=5000
clouds_altitude=1000
clouds_pos_x=0
clouds_pos_y=0

layer_far_scan_r=1024
far_clouds_absorption=0.5

--------------------------------------------------------------------------------

function ClearFrame()
	-- only clear the depth buffer
	renderer:Clear(hg.Color.Black, 1.0, hg.ClearDepth)
	-- notify the engine that clearing has been handled
	return true
end

-- load the shader (RenderScript is run from the rendering thread)
shader = renderer:LoadShader("assets/shaders/sky_render.isl")

-- hook the end of opaque render pass to draw the skybox
function EndRenderPass(pass)
	if not shader:IsReadyOrFailed() then
		return -- shader is not ready yet
	end

	if pass ~= hg.RenderPassOpaque then
		return -- we're only interested in the opaque primitive pass
	end

	-- backup current view state
	local view_state = render_system:GetViewState()
	--local view_rotation = view_state.view:GetRotationMatrix()

	-- configure the shader
	renderer:SetShader(shader)
	renderer:SetShaderTexture("tex_sky_N", tex_sky_N)
	renderer:SetShaderTexture("tex_sky_S", tex_sky_S)
	renderer:SetShaderTexture("clouds_map", clouds_map)
	renderer:SetShaderFloat("tex_sky_N_intensity",tex_sky_N_intensity)
	renderer:SetShaderFloat("tex_sky_S_intensity",tex_sky_S_intensity)
	renderer:SetShaderFloat2("resolution",resolution_x,resolution_y)
	renderer:SetShaderFloat3("clouds_scale",1/clouds_scale_x,far_clouds_scale_y,1/clouds_scale_z)
	renderer:SetShaderFloat("clouds_altitude",clouds_altitude)
	renderer:SetShaderFloat("focal_distance",zoom_factor)
	--renderer:SetShaderMatrix3("cam_normal", view_rotation)
	renderer:SetShaderFloat("zenith_falloff",zenith_falloff)
	renderer:SetShaderFloat("nadir_falloff",nadir_falloff)
	renderer:SetShaderFloat3("zenith_color", zenith_color_r, zenith_color_g, zenith_color_b)
	renderer:SetShaderFloat3("nadir_color", nadir_color_r, nadir_color_g, nadir_color_b)
	renderer:SetShaderFloat3("horizonH_color", horizon_N_color_r, horizon_N_color_g,horizon_N_color_b)
	renderer:SetShaderFloat3("horizonL_color", horizon_S_color_r, horizon_S_color_g,horizon_S_color_b)
	renderer:SetShaderFloat3("horizon_line_color", horizon_line_color_r, horizon_line_color_g, horizon_line_color_b)
	renderer:SetShaderFloat("horizon_line_size", horizon_line_size)
	renderer:SetShaderFloat("layer_far_scan_r", layer_far_scan_r)
	renderer:SetShaderFloat("far_clouds_absorption", far_clouds_absorption)
	renderer:SetShaderFloat2("zFrustum", z_near, z_far)
	renderer:SetShaderFloat3("sun_dir", sun_dir_x, sun_dir_y,sun_dir_z)
	renderer:SetShaderFloat3("sun_color", sun_color_r, sun_color_g,sun_color_b)
	renderer:SetShaderFloat3("ambient_color", ambient_color_r, ambient_color_g,ambient_color_b)

	-- configure the frame buffer so that only background pixels are drawn to
	renderer:EnableDepthTest(true)
	renderer:EnableDepthWrite(false)
	renderer:SetDepthFunc(hg.DepthLessEqual)
	render_system:DrawFullscreenQuad(render_system:GetViewportToInternalResolutionRatio())
	renderer:EnableDepthWrite(true)
	renderer:EnableDepthTest(true)

	-- restore view state
	render_system:SetViewState(view_state)
end
