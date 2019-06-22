import SceneKit
import OpenGL.GL3

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

    // For the custom OpenGL program
    var renderShader = GLShader()
    var offScreenRenderer: SCNRenderer!
    var offScreenScene: SCNScene!
    var sharedContext: NSOpenGLContext!
    var quadVAO: GLuint = 0
    let shader = GLShader()
    var frameBufferObject: GLuint = 0   // framebuffer object name (or id)
    var cubemapTexture: GLuint = 0      // color attachment texture
    let textureWidth: GLsizei = 1024
    let textureHeight: GLsizei = 1024

    override public func loadView() {
        let frameRect = NSRect(x: 0, y: 0, width: 480, height: 320)
        self.view = NSView(frame: frameRect)
        // Using the Dictionary below to ensure OpenGL Core Profile 3.2 or later is supported.
        let options: [String:Any] = [
            SCNView.Option.preferredRenderingAPI.rawValue:SCNRenderingAPI.openGLCore41.rawValue
        ]
        sceneView = OGLSceneView(frame: frameRect,
                                 options: options)

        //print(sceneView.renderingAPI.rawValue)
        self.view.addSubview(sceneView)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        sharedContext = sceneView.openGLContext!
        sharedContext.makeCurrentContext()
        loadShaders()
        setupFrameBuffer()

        // Setup up the SCNRenderer object which will render the contents of
        // a scene offscreen. The output is to a texture bound to a frame buffer object.
        offScreenRenderer = SCNRenderer(context: sharedContext.cglContextObj)
        offScreenScene = SCNScene()
        offScreenRenderer.scene = offScreenScene
        // Make this instance of NSViewController is a delegate of SCNSceneRenderer.
        offScreenRenderer.delegate = self
        // The statement below will call the implemented SCNSceneRendererDelegate method
        //      renderer:willRenderScene:atTime:
        offScreenRenderer.render(atTime: 0)
     }

    override public func viewWillAppear() {
        super.viewWillAppear()
        let shaderName = "display"
        let vertexShaderURL = Bundle.main.url(forResource: shaderName,
                                              withExtension: "vs")
        let fragmentShaderURL = Bundle.main.url(forResource: shaderName,
                                                withExtension: "fs")

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
        
        let program = SCNProgram()
        program.vertexShader = vertexShader
        program.fragmentShader = fragmentShader
        program.delegate = self

        let cubeGeometry = SCNBox(width: 1.0, height: 1.0, length: 1.0,
                                  chamferRadius: 0.0)
        
        cubeGeometry.program = program

        // only 1 vertex attribute
        program.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue,
                            forSymbol: "in_position",
                            options: nil)

        program.setSemantic(SCNModelViewProjectionTransform,
                            forSymbol: "MVP",
                            options: nil)

        cubeGeometry.handleBinding(ofSymbol: "cubemap",
                                   handler: {

            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), self.cubemapTexture)
        })

        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.name = "textured cube"
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 2)
        let scene = SCNScene()
        sceneView.scene = scene
        scene.rootNode.addChildNode(cubeNode)

        //sceneView.delegate = self             // this can't be assigned!
        sceneView.backgroundColor = NSColor.gray
        // Check the rendering API is OpenGL
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true

        // Camera
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3Make(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
 
        // Animate the cube
        SCNTransaction.begin()
        let animation = CABasicAnimation(keyPath: "rotation")
        animation.duration = 5.0
        animation.toValue = NSValue(scnVector4: SCNVector4Make(1, 1, 1,
                                                               CGFloat.pi * 2))
        animation.repeatCount = .greatestFiniteMagnitude
        cubeNode.addAnimation(animation,
                              forKey: "myAnimation")
        SCNTransaction.commit()
    }

    @nonobjc
    public func program(_ programID: SCNProgram,
                        handleError error: Error) {
        Swift.print("%@", error.localizedDescription);
    }

    func checkGLError() {
        let err = glGetError()
        if err != GLenum(GL_NO_ERROR) {
            NSLog("OpenGL error:0x%0x", err)
        }
    }

    // This pair of shaders is used by the offscreen renderer.
    func loadShaders() {

        var shaderIDs = [GLuint]()
        var shaderID = renderShader.compileShader(filename: "RenderCubeTexture.vs",
                                            shaderType: GLenum(GL_VERTEX_SHADER))
        shaderIDs.append(shaderID)
        shaderID = renderShader.compileShader(filename: "RenderCubeTexture.gs",
                                        shaderType: GLenum(GL_GEOMETRY_SHADER))
        shaderIDs.append(shaderID)
        shaderID = renderShader.compileShader(filename: "RenderCubeTexture.fs",
                                        shaderType: GLenum(GL_FRAGMENT_SHADER))
        shaderIDs.append(shaderID)
        renderShader.createAndLinkProgram(shaders: shaderIDs)
    }

    // Setup the environment for an offscreen render.
    func setupFrameBuffer() {
        // The geometry of the quad is embedded in the vertex shader.
        glGenVertexArrays(1, &quadVAO)

        // Now instantiate a texture object ...
        glActiveTexture(GLenum(GL_TEXTURE0))
        glGenTextures(1, &cubemapTexture)
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), cubemapTexture)
        // glTexStorage2D is not declared in Swift interface module
        for i in 0..<6 {
            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + Int32(i)),
                         0,
                         GL_RGBA8,                  // internal format
                         textureWidth, textureHeight,
                         0,
                         GLenum(GL_RGBA),           // check
                         GLenum(GL_UNSIGNED_BYTE),
                         nil)
        }
        // Set up texture maps
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_R), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)

        // setup FBO with color cubemap attached
        glGenFramebuffers(1, &frameBufferObject)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBufferObject)
        glFramebufferTexture(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), cubemapTexture, 0)
        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GLenum(GL_FRAMEBUFFER_COMPLETE) {
            print("FrameBuffer is incomplete")
        }
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), 0)
   }

    // Note: This function is be called by the off-screen renderer
    // and not by the program's instance of SCNView "sceneView" renderer
    fileprivate var firstTime = true
    public func renderer(_ renderer: SCNSceneRenderer,
                         willRenderScene scene: SCNScene,
                         atTime time: TimeInterval) {
        sharedContext.makeCurrentContext()
        CGLLockContext(sharedContext.cglContextObj!)

        glClear(GLenum(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        // For offscreen rendering the rectangular drawing region must set.
        // Or it will be 1 pixel x 1 pixel by default.
        glViewport(0, 0, textureWidth, textureHeight)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBufferObject)
        // Set the background to a black to indicate this method
        // had been called in case the shaders are not working properly.
        glClearColor(0.0, 0.0, 0.0, 1.0)
        renderShader.use()
        glBindVertexArray(quadVAO)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindVertexArray(0)
        glUseProgram(0)
        // Make the system default active
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)

        sharedContext.update()
        sharedContext.flushBuffer()
        CGLUnlockContext(sharedContext.cglContextObj!)
    }
}


