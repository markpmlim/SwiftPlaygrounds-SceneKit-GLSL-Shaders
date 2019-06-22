// Testing GLSL shader programs in SceneKit
// This playground shows how to setup two sets of GLSL shaders.
// The first set generates a cubemap in an framebuffer.
// The second set renders a colored cube textured with the
// generated cubemap.
//
// Requirements: XCode 8.x or later
import PlaygroundSupport

let vc = SCNViewController()
PlaygroundPage.current.liveView = vc
