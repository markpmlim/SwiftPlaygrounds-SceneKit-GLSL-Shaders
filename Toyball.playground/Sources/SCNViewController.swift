//: Playground - noun: a place where people can play

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

public final class SCNViewController: NSViewController {
    var sceneView: OGLSceneView!

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
        let scene = SCNScene()
        sceneView.scene = scene

        let sphere = SCNSphere(radius: 5.0)
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)

        sceneView.backgroundColor = NSColor.gray
        // Check the rendering API is OpenGL
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true

        // Read the contents of the 2 shaders
        let shaderName = "Toyball"
        let vertexShaderURL = Bundle.main.url(forResource: shaderName,
                                              withExtension: "vs")
        let fragmentShaderURL = Bundle.main.url(forResource: shaderName,
                                                withExtension: "fs")
        var vertexShader: String?
        do {
            try vertexShader = String(contentsOf: vertexShaderURL!,
                                      encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        }
        catch _ {
            print("Can't load vertex shader")
        }
        var fragmentShader: String?
        do {
            try fragmentShader = String(contentsOf: fragmentShaderURL!,
                                        encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        }
        catch _ {
            print("Can't load fragment shader")
        }

        let program = SCNProgram()
        program.vertexShader = vertexShader
        program.fragmentShader = fragmentShader
        sphere.program = program

        program.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue,
                            forSymbol: "vertexPosition",
                            options: nil)

        program.setSemantic(SCNModelViewTransform,
                            forSymbol: "modelViewMatrix",
                            options: nil)
        program.setSemantic(SCNModelViewProjectionTransform,
                            forSymbol: "mvpMatrix",
                            options: nil)

        sphere.handleBinding(ofSymbol: "ballCenter",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4f(Int32(location), 0.0, 0.0, 0.0, 1.0)
        })

        var halfSpaceValues: [GLfloat] = [
            1.0, 0.0, 0.0, 0.2,
            0.309016994, 0.951056516, 0.0, 0.2,
            -0.809016994, 0.587785252, 0.0, 0.2,
            -0.809016994, -0.587785252, 0.0, 0.2,
            0.309016994, -0.951056516, 0.0, 0.2
        ]

        sphere.handleBinding(ofSymbol: "HalfSpace",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4fv(Int32(location), 5, &halfSpaceValues)
        })

        var starColor: [Float] = [0.6, 0.0, 0.0, 1.0]
        sphere.handleBinding(ofSymbol: "StarColor",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4fv(Int32(location), 1, &starColor)
        })

        let stripeColor: [Float] = [0.0, 0.3, 0.6, 1.0]
        sphere.handleBinding(ofSymbol: "StripeColor",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4fv(Int32(location), 1, UnsafePointer<GLfloat>(stripeColor))
        })

        let baseColor: [Float] = [0.6, 0.5, 0.0, 1.0]
        sphere.handleBinding(ofSymbol: "BaseColor",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4fv(Int32(location), 1, UnsafePointer<GLfloat>(baseColor))
        })

        sphere.handleBinding(ofSymbol: "LightDir",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in

            glUniform4f(Int32(location), 0.57735, 0.57735, 0.57735, 0.0)
        })

        sphere.handleBinding(ofSymbol: "HVector",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4f(Int32(location), 0.32506, 0.32506, 0.88808, 0.0)
        })
 
        sphere.handleBinding(ofSymbol: "SpecularColor",
                             handler: {

            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform4f(Int32(location), 1.0, 1.0, 1.0, 1.0)
        })


        sphere.handleBinding(ofSymbol: "StripeWidth",
                             handler: {
            (programID: UInt32, location: UInt32, node: SCNNode?, renderer: SCNRenderer) -> Void in
            glUniform1f(Int32(location), 0.3);
        })
        
        sphereNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0,
                                                                        y: 1.14,
                                                                        z: 0,
                                                                        duration: 1)))
    }
}


