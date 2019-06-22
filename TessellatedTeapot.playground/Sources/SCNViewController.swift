import SceneKit

class OGLSceneView: SCNView {
    override init(frame frameRect: NSRect,
                  options: [String : Any]?) {

        super.init(frame: frameRect, options: options)

        let pixelFormatAttrsBestCase: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFABackingStore),
            UInt32(NSOpenGLPFADepthSize), UInt32(24),
            UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(0)
        ]
        
        let pf = NSOpenGLPixelFormat(attributes: pixelFormatAttrsBestCase)
        if (pf == nil) {
            NSLog("Couldn't init opengl at all, sorry :(")
            abort()
        }
        self.pixelFormat = pf
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class SCNViewController: NSViewController, SCNSceneRendererDelegate, SCNProgramDelegate {
    var sceneView: OGLSceneView!
    var scnVAO: GLint = 0           // The Vertex Array Object used by scene's renderer.
    var scnProgramID: GLint = 0     // The GLSL programID object used by scene's renderer.

    override public func loadView() {
        let frameRect = NSRect(x: 0, y: 0, width: 480, height: 320)
        self.view = NSView(frame: frameRect)
        // Change the Dictionary below to support OpenGL Core Profile 3.2 or later.
        let options: [String : Any] = [
            SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLCore41.rawValue
        ]
        sceneView = OGLSceneView(frame: frameRect,
                                 options: options)

        //print(sceneView.renderingAPI.rawValue)
        self.view.addSubview(sceneView)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        let shaderName = "bezier"
        let vertexShaderURL = Bundle.main.url(forResource: shaderName,
                                              withExtension: "vs")
        let fragmentShaderURL = Bundle.main.url(forResource: shaderName,
                                                withExtension: "fs")
        let tessControlShaderURL = Bundle.main.url(forResource: shaderName,
                                                   withExtension: "tcs")
        let tessEvaluationShaderURL = Bundle.main.url(forResource: shaderName,
                                                      withExtension: "tes")
        var vertexShader: String?
        do {
            try vertexShader = String(contentsOf: vertexShaderURL!,
                                      encoding: String.Encoding.utf8)
        }
        catch _ {
            Swift.print("Can't load vertex shader")
        }
        var fragmentShader: String?
        do {
            try fragmentShader = String(contentsOf: fragmentShaderURL!,
                                        encoding: String.Encoding.utf8)
        }
        catch _ {
            Swift.print("Can't load fragment shader")
        }
        var tessControlShader: String?
        do {
            try tessControlShader = String(contentsOf: tessControlShaderURL!,
                                           encoding: String.Encoding.utf8)
        }
        catch _ {
            Swift.print("Can't load tessellation control shader")
        }
        var tessEvaluationShader: String?
        do {
            try tessEvaluationShader = String(contentsOf: tessEvaluationShaderURL!,
                                              encoding: String.Encoding.utf8)
        }
        catch _ {
            Swift.print("Can't load tessellation evaluation shader")
        }
        
        let program = SCNProgram()
        program.vertexShader = vertexShader
        program.tessellationControlShader = tessControlShader
        program.tessellationEvaluationShader = tessEvaluationShader
        program.fragmentShader = fragmentShader
        program.delegate = self

        // only 1 vertex attribute
        program.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue,
                            forSymbol: "vertexPosition",
                            options: nil)

        program.setSemantic(SCNNormalTransform,
                            forSymbol: "NormalMatrix",
                            options: nil)
        
        program.setSemantic(SCNModelViewTransform,
                            forSymbol: "ModelViewMatrix",
                            options: nil)

        program.setSemantic(SCNModelViewProjectionTransform,
                            forSymbol: "MVP",
                            options: nil)


        let teapotPatches = createGeometry()!
        teapotPatches.program = program

        teapotPatches.handleBinding(ofSymbol: "tessLevel",
                                    handler: {

            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform1i(Int32(location), 4)
            if self.scnProgramID == 0 {
                // We need the vertex array object and programID name during rendering.
                glGetIntegerv(GLenum(GL_VERTEX_ARRAY_BINDING), &self.scnVAO)
                glGetIntegerv(GLenum(GL_CURRENT_PROGRAM), &self.scnProgramID)
            }
        })

        var normalScale: [Float] = [0.05, 0.05, 0.05]
        teapotPatches.handleBinding(ofSymbol: "norm_scale",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform3fv(Int32(location), 1, &normalScale)
        })

        var lightModelAmbient:[Float] = [0.05, 0.05, 0.05, 1.0]
        teapotPatches.handleBinding(ofSymbol: "lightModelAmbient",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4fv(Int32(location), 1, &lightModelAmbient)
        })
        
        var lightSourcePosition: [Float] = [-5.0, 10.0, 4.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "lightSource.position",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4fv(Int32(location), 1, &lightSourcePosition)
        })

        var diffuse: [Float] = [1.0, 1.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "lightSource.diffuse",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform3fv(Int32(location), 1, &diffuse)
        })

        var specular: [Float] = [1.0, 1.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "lightSource.specular",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform3fv(Int32(location), 1, &specular)
        })
 
        var materialAmbient: [Float] = [0.2, 0.35, 1.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "material.ambient",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4fv(Int32(location), 1, &materialAmbient)
        })
        
        var materialDiffuse: [Float] = [0.2, 0.35, 1.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "material.diffuse",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4fv(Int32(location), 1, &materialDiffuse)
        })

        var materialSpecular: [Float] = [1.0, 1.0, 1.0, 1.0]
        teapotPatches.handleBinding(ofSymbol: "material.specular",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4fv(Int32(location), 1, &materialSpecular)
        })

        teapotPatches.handleBinding(ofSymbol: "material.shininess",
                                    handler: {
                                        
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform1f(Int32(location), 60.0)
        })

        let teapotNode = SCNNode(geometry: teapotPatches)
        teapotNode.name = "Teapot Bezier patches"
        let scene = SCNScene()
        sceneView.scene = scene
        scene.rootNode.addChildNode(teapotNode)

        sceneView.delegate = self
        sceneView.backgroundColor = NSColor.gray
        // Check the rendering API is OpenGL
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true

    }

    fileprivate var firstTime = true
    public func renderer(_ renderer: SCNSceneRenderer,
                         willRenderScene scene: SCNScene,
                         atTime time: TimeInterval) {
        if firstTime {
            glPolygonMode(GLenum(GL_FRONT_AND_BACK), GLenum(GL_FILL))
            glEnable(GLenum(GL_DEPTH_TEST))

            self.checkGLError()
            firstTime = false
        }
        else {
            glPatchParameteri(GLenum(GL_PATCH_VERTICES), 16)
            glDisable(GLenum(GL_CULL_FACE))
            self.checkGLError()
            glUseProgram(GLuint(scnProgramID))
            glBindVertexArray(GLuint(scnVAO))
            glDrawElements(GLenum(GL_PATCHES),          // # of elements to ...
                           GLsizei(kNumTeapotIndices),  // ... be rendered
                           GLenum(GL_UNSIGNED_INT),
                           nil)
        }
    }

    public func program(_ programID: SCNProgram, handleError error: Error) {
        Swift.print("%@", error.localizedDescription);
    }

    func checkGLError() {
        let err = glGetError()
        if err != GLenum(GL_NO_ERROR) {
            NSLog("OpenGL error:0x%0x", err)
        }
    }
}


