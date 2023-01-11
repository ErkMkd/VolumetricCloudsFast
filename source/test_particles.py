# -*-coding:Utf-8 -*

# ===========================================================

#              - HARFANG® 3D - www.harfang3d.com

#                    - Python Unit test -

#            Test particles display

# ===========================================================

import harfang as hg
from math import radians
from data_converter import *

def init_scene(plus):
    scene = plus.NewScene()
    camera = plus.AddCamera(scene, hg.Matrix4.TranslationMatrix(hg.Vector3(20, 10, 10)))
    camera.SetName("Camera")
    init_lights(plus, scene)

    while not scene.IsReady():  # Wait until scene is ready
        plus.UpdateScene(scene, plus.UpdateClock())

    # Ground:
    ground = plus.AddPlane(scene, hg.Matrix4.TransformationMatrix(hg.Vector3(0, 0, 0), hg.Vector3(0, 0, 0)), 100,
                                 100)

    fps = hg.FPSController(0, 2, -15)


    return scene, fps


def init_lights(plus, scene):
    # Main light:
    ligth_sun = plus.AddLight(scene, hg.Matrix4.RotationMatrix(hg.Vector3(radians(22), radians(-45), 0)),
                              hg.LightModelLinear)
    ligth_sun.SetName("Sun")
    ligth_sun.GetLight().SetDiffuseColor(hg.Color(255. / 255., 255. / 255., 255. / 255., 1.))

    ligth_sun.GetLight().SetShadow(hg.LightShadowMap)
    ligth_sun.GetLight().SetShadowRange(50)

    ligth_sun.GetLight().SetDiffuseIntensity(1.)
    ligth_sun.GetLight().SetSpecularIntensity(1.)


    # Ambient:
    ambient_color = hg.Color(103. / 255., 157. / 255., 141. / 255., 1.)
    environment = hg.Environment()
    environment.SetAmbientColor(ambient_color)
    environment.SetAmbientIntensity(0.3)
    environment.SetFogColor(ambient_color * 0.3)
    environment.SetFogNear(20)
    environment.SetFogFar(100)
    environment.SetBackgroundColor(hg.Color(64 / 255, 184 / 255, 255 / 255) * 0.5)
    scene.AddComponent(environment)


# ==================================================================================================

#                                   Program start here

# ==================================================================================================

# Display settings
resolution = hg.Vector2(1600, 900)
antialiasing = 4
screenMode = hg.Windowed

# System setup
plus = hg.GetPlus()
hg.LoadPlugins()
plus.Mount("./")

# Run display
plus.RenderInit(int(resolution.x), int(resolution.y), antialiasing, screenMode)
plus.SetBlend2D(hg.BlendAlpha)


# Setup scene:
scene, fps= init_scene(plus)

plus.UpdateScene(scene)
camera = scene.GetNode("Camera")
rot=hg.Vector3(0,0,0)
cube = plus.AddCube(scene, hg.Matrix4.TransformationMatrix(hg.Vector3(-2, 3, 0), hg.Vector3(0, 0, 0)), 1,1,1)
particle = load_object(plus,"assets/clouds/cloud_particle_3.geo","particle",True)
scene.AddNode(particle)
particle.GetTransform().SetPosition(hg.Vector3(0,3,0))
# Main loop:

while not plus.KeyDown(hg.KeyEscape):
    delta_t = plus.UpdateClock()
    dts = hg.time_to_sec_f(delta_t)

    fps.UpdateAndApplyToNode(camera, delta_t)
    rot.x+=0.01
    rot.y+=0.045
    rot.z+=0.03146
    cube.GetTransform().SetRotation(rot)
    particle.GetTransform().SetRotation(rot)

    plus.UpdateScene(scene, delta_t)


    plus.Flip()
    plus.EndFrame()