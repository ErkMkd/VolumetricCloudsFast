# -*-coding:Utf-8 -*

# ===========================================================

#              - HARFANG® 3D - www.harfang3d.com

#                   Clouds
# ===========================================================

import harfang as hg
from math import radians, degrees
from random import uniform
from Cloud import *


# =============================================================================================

#       Functions

# =============================================================================================

flag_hovering_gui = False

def update_hovering_ImGui(plus):
	global flag_hovering_gui

	if hg.ImGuiIsWindowHovered(hg.ImGuiHoveredFlags_AnyWindow) and plus.GetMouse().WasButtonPressed(hg.Button0):
		flag_hovering_gui=True
	if flag_hovering_gui and plus.GetMouse().WasButtonReleased(hg.Button0):
		flag_hovering_gui = False

def init_scene(plus,resolution):
	scene = plus.NewScene()
	camera = plus.AddCamera(scene, hg.Matrix4.TranslationMatrix(hg.Vector3(0, 0, -10)))
	camera.SetName("Camera")
	camera.GetCamera().SetZNear(1.)
	camera.GetCamera().SetZFar(40000)

	init_lights(plus,scene)

	#plane = plus.AddPlane(scene, hg.Matrix4.TransformationMatrix(hg.Vector3(0, 0, 0), hg.Vector3(0, 0, 0)), 500,500)
	#plane.SetName("ground")



	while not scene.IsReady():  # Wait until scene is ready
		plus.UpdateScene(scene, plus.UpdateClock())

	plus.UpdateScene(scene, plus.UpdateClock())

	# Sky
	#sky_render_script = hg.RenderScript("@core/lua/sky_lighting.lua")
	sky_render_script = hg.RenderScript("assets/lua_scripts/sky_render.lua")
	scene.AddComponent(sky_render_script)

	# ---- Clouds:
	json_script = hg.GetFilesystem().FileToString("assets/scripts/clouds_parameters.json")
	if json_script != "":
		clouds_parameters = json.loads(json_script)
		cloud = Clouds(plus, scene, resolution, clouds_parameters)

	fps = hg.FPSController(0,0,-10,50,10)

	# check if we use VR
	openvr_frame_renderer = None
	"""
	try:
		openvr_frame_renderer = hg.CreateFrameRenderer("VR")
		if openvr_frame_renderer.Initialize(plus.GetRenderSystem()):
			scene.GetRenderableSystem().SetFrameRenderer(openvr_frame_renderer)
			print("!! Use VR")
		else:
			openvr_frame_renderer = None
			print("!! No VR detected")
	except:
		print("!! No VR detected")
		openvr_frame_renderer = None
	"""

	return scene, camera, fps, cloud, sky_render_script,openvr_frame_renderer

def init_lights(plus,scene):
	# Main light:
	ligth_sun = plus.AddLight(scene, hg.Matrix4.RotationMatrix(hg.Vector3(radians(25), radians(-45), 0)),
								   hg.LightModelLinear)
	ligth_sun.SetName("Sun")
	ligth_sun.GetLight().SetDiffuseColor(hg.Color(255. / 255., 255. / 255., 255. / 255., 1.))

	ligth_sun.GetLight().SetShadow(hg.LightShadowMap)  # Active les ombres portées
	ligth_sun.GetLight().SetShadowRange(500)

	ligth_sun.GetLight().SetDiffuseIntensity(1.)
	ligth_sun.GetLight().SetSpecularIntensity(1.)

	# Sky ligth:
	ligth_sky = plus.AddLight(scene, hg.Matrix4.RotationMatrix(hg.Vector3(radians(54), radians(135), 0)),
								   hg.LightModelLinear)
	ligth_sky.SetName("SkyLigth")
	ligth_sky.GetLight().SetDiffuseColor(hg.Color(103. / 255., 157. / 255., 141. / 255., 1.))
	ligth_sky.GetLight().SetDiffuseIntensity(0.2)

	# Ambient:
	environment = hg.Environment()
	environment.SetAmbientColor(hg.Color(103. / 255., 157. / 255., 141. / 255., 1.))
	environment.SetAmbientIntensity(0.5)
	scene.AddComponent(environment)


def update_view(plus, scene, fps, delta_t):
	camera = scene.GetNode("Camera")
	fps.UpdateAndApplyToNode(camera, delta_t)

link_altitudes=True
link_morphs=True
clouds_altitude=1000
clouds_morph_level=0.1

def gui_clouds(scene: hg.Scene, cloud: Clouds,sky_render):
	global link_altitudes,link_morphs,clouds_altitude,clouds_morph_level

	if hg.ImGuiBegin("Clouds Settings"):
		if hg.ImGuiButton("Load clouds parameters"):
			cloud.load_json_script()  # fps.Reset(cloud.cam_pos,hg.Vector3(0,0,0))
		hg.ImGuiSameLine()
		if hg.ImGuiButton("Save clouds parameters"):
			cloud.save_json_script(scene)

		hg.ImGuiSeparator()

		hg.ImGuiText("Map position: X=" + str(cloud.map_position.x))
		hg.ImGuiText("Map position: Y=" + str(cloud.map_position.y))


		"""
		d, f = hg.ImGuiSliderFloat("Far Clouds scale x", sky_render.clouds_scale.x, 100, 10000)
		if d:
			sky_render.clouds_scale.x = f

		d, f = hg.ImGuiSliderFloat("Far Clouds scale y", sky_render.clouds_scale.y, 0, 1)
		if d:
			sky_render.clouds_scale.y = f

		d, f = hg.ImGuiSliderFloat("Far Clouds scale z", sky_render.clouds_scale.z, 100, 10000)
		if d:
			sky_render.clouds_scale.z = f

		
		d, f = hg.ImGuiSliderFloat("Far Clouds absorption", sky_render.clouds_absorption, 0, 1)
		if d:
			sky_render.clouds_absorption = f
		"""


		d, f = hg.ImGuiSliderFloat("Clouds scale x", cloud.map_scale.x, 100, 10000)
		if d:
			cloud.set_map_scale_x(f)
		d, f = hg.ImGuiSliderFloat("Clouds scale z", cloud.map_scale.y, 100, 10000)
		if d:
			cloud.set_map_scale_z(f)

		d, f = hg.ImGuiSliderFloat("Wind speed x", cloud.v_wind.x, -1000, 1000)
		if d:
			cloud.v_wind.x=f

		d, f = hg.ImGuiSliderFloat("Wind speed z", cloud.v_wind.y, -1000, 1000)
		if d:
			cloud.v_wind.y = f


		d, f = hg.ImGuiCheckbox("Link layers altitudes", link_altitudes)
		if d: link_altitudes = f
		d, f = hg.ImGuiCheckbox("Link layers morph levels", link_morphs)
		if d: link_morphs = f


		d, f = hg.ImGuiSliderFloat("Clouds altitude", clouds_altitude, 100, 10000)
		if d:
			clouds_altitude = f
			if link_altitudes:
				for layer in cloud.layers:
					layer.set_altitude(f)

		d, f = hg.ImGuiSliderFloat("Clouds morph level", clouds_morph_level, 0, 1)
		if d:
			clouds_morph_level = f
			if link_morphs:
				for layer in cloud.layers:
					layer.morph_level=f

		for layer in cloud.layers:
			hg.ImGuiSeparator()
			gui_layer(layer)

	hg.ImGuiEnd()


def gui_layer(layer: CloudsLayer):
	nm = layer.name
	hg.ImGuiText(layer.name)

	d, f = hg.ImGuiSliderFloat(nm + " particles rotation speed", layer.particles_rot_speed , -10, 10)
	if d:
		layer.set_particles_rot_speed(f)

	d, f = hg.ImGuiSliderFloat(nm + " particles morph level", layer.morph_level, -1, 1)
	if d:
		layer.morph_level=f

	d, f = hg.ImGuiSliderFloat(nm + " Absorption factor", layer.absorption * 100, 0.01, 10)
	if d:
		layer.set_absorption(f / 100)

	d, f = hg.ImGuiSliderFloat(nm + " Altitude floor", layer.altitude_floor, -2, 2)
	if d: layer.set_altitude_floor(f)

	d, f = hg.ImGuiSliderFloat(nm + " Altitude", layer.altitude, 0, 10000)
	if d: layer.set_altitude(f)

	d, f = hg.ImGuiSliderFloat(nm + " Altitude falloff", layer.altitude_falloff, 0.1, 100)
	if d: layer.set_altitude_falloff(f)

	d, f = hg.ImGuiSliderFloat(nm + " Particles min scale", layer.particles_scale_range.x, 1, 5000)
	if d:
		layer.set_particles_min_scale(f)
	d, f = hg.ImGuiSliderFloat(nm + " Particles max scale", layer.particles_scale_range.y, 1, 5000)
	if d:
		layer.set_particles_max_scale(f)
	d, f = hg.ImGuiSliderFloat(nm + " Alpha threshold", layer.alpha_threshold, 0, 1)
	if d:
		layer.alpha_threshold = f

	d, f = hg.ImGuiSliderFloat(nm + " Scale falloff", layer.scale_falloff, 1, 10)
	if d:
		layer.scale_falloff = f

	d, f = hg.ImGuiSliderFloat(nm + " Alpha scale falloff", layer.alpha_scale_falloff, 1, 10)
	if d:
		layer.alpha_scale_falloff = f

	d, f = hg.ImGuiSliderFloat(nm + " Perturbation", layer.perturbation, 0, 200)
	if d:
		layer.perturbation = f
	d, f = hg.ImGuiSliderFloat(nm + " Tile size", layer.tile_size, 1, 500)
	if d:
		layer.tile_size = f
	d, f = hg.ImGuiSliderFloat(nm + " Distance min", layer.distance_min, 0, 5000)
	if d:
		layer.set_distance_min(f)
	d, f = hg.ImGuiSliderFloat(nm + " Distance max", layer.distance_max, 100, 5000)
	if d:
		layer.set_distance_max(f)

	d, f = hg.ImGuiSliderFloat(nm + " Margin", layer.margin, 0.5, 2)
	if d:
		layer.margin = f
	d, f = hg.ImGuiSliderFloat(nm + " Focal margin", layer.focal_margin, 0.5, 2)
	if d:
		layer.focal_margin = f


# ==================================================================================================

#                                   Program start here

# ==================================================================================================

# Display settings
resolution = hg.Vector2(1600, 900)
antialiasing = 1
screenMode = hg.Windowed

# System setup
plus = hg.GetPlus()
hg.LoadPlugins()
plus.Mount("./")

# Run display
plus.RenderInit(int(resolution.x), int(resolution.y), antialiasing, screenMode)
plus.SetBlend2D(hg.BlendAlpha)

# Setup dashboard:
scene, camera, fps, cloud, sky_render,openvr_frame_renderer = init_scene(plus,resolution)
plus.UpdateScene(scene)

cloud.update_particles()

# -----------------------------------------------
#                   Main loop
# -----------------------------------------------

while not plus.KeyDown(hg.KeyEscape) and not plus.IsAppEnded():
	delta_t = plus.UpdateClock()

	dts=hg.time_to_sec_f(delta_t)
	t=hg.time_to_sec_f(plus.GetClock())

	gui_clouds(scene,cloud,sky_render)

	update_hovering_ImGui(plus)
	if not flag_hovering_gui:
		update_view(plus, scene, fps, delta_t)


	#plus.GetRenderer().Clear(hg.Color(0.,0.,0.,0.))  # red

	"""
	plus.Text2D(0.1 * resolution.x, 0.28 * resolution.y, "Num tiles layer 1:" + str(cloud.layers[0].num_tiles))
	plus.Text2D(0.1 * resolution.x, 0.26 * resolution.y, "Num tiles layer 2:" + str(cloud.layers[1].num_tiles))
	y=0.24
	for i in range(0,cloud.layers[0].num_geometries):
		plus.Text2D(0.1 * resolution.x, (y) * resolution.y, "Num particles "+cloud.layers[0].name+"  geo "+str(i)+":" + str(cloud.layers[0].particle_index[i]))
		y-=0.02
	y-=0.02
	for i in range(0,cloud.layers[1].num_geometries):
		plus.Text2D(0.1 * resolution.x, (y) * resolution.y, "Num particles "+cloud.layers[1].name+"  geo "+str(i)+":" + str(cloud.layers[1].particle_index[i]))
		y -=0.02
	"""


	plus.UpdateScene(scene, delta_t)
	mat=camera.GetTransform().GetWorld()
	hmd = hg.GetInputSystem().GetDevice("HMD")
	if hmd is not None:
		mat = mat*hmd.GetMatrix(hg.InputDeviceMatrixHead)
	cloud.update(t, dts, scene,mat, resolution)
	scene.Commit()
	scene.WaitCommit()

	plus.Flip()

	plus.EndFrame()

plus.RenderUninit()