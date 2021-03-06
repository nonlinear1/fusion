//
//  myGLRenderer.swift
//  AR
//
//  Created by jhw on 30/11/2017.
//  Copyright © 2017 zju.gaps. All rights reserved.
//

import Foundation
import GLKit



class myGLTexture2D: NSObject {
    var _width: GLsizei = 0
    var _height: GLsizei = 0
    var _textureid: GLuint = 0
    var _format: Int32 = 0
    var _type: Int32 = 0
    
    init(width: GLsizei, height: GLsizei, texid: GLuint, format: Int32, type: Int32) {
        _width = width
        _height = height
        _textureid = texid
        _format = format
        _type = type
    }
}

class myGLRenderer: NSObject {

    var _program: myGLProgram!
    var _rtt: myGLRTT!

    var vertexShader: GLuint = 0
    var fragmentShader: GLuint = 0
    var numIndices: Int = 0
    var vertexIndicesBufferID: GLuint = 0
    var vertexBufferID: GLuint = 0
    var vertexTexCoordID: GLuint = 0
    var vertexTexCoordAttributeIndex: GLuint = 0
    
    var _numChannels: Int = 0
    var _format: Int32 = 0
    var _type: Int32 = 0
    
    init(width: GLsizei, height: GLsizei, internalformat: Int32, format: Int32, type: Int32, textures: Int = 1) {
        switch format {
        case Int32(GL_RED), Int32(GL_GREEN), Int32(GL_BLUE): _numChannels = 1;
        case Int32(GL_RGB): _numChannels = 3;
        case Int32(GL_RGBA): _numChannels = 4;
        default:
            break
        }
        print("numChannels:", _numChannels)
        
        _format = format
        _type = type
        
        _rtt = myGLRTT.init(width: width, height: height, internalformat: internalformat, format: format, type: type, textures: textures)
    }
    
    func setShaderFile(vshname: String, fshname: String) {
        
        self._program = myGLProgram(vshname: vshname, fshname: fshname)
        self._program.addAttribute(attributeName: "position")
        self._program.addAttribute(attributeName: "texCoord")
        
        if !self._program.link() {
            _program = nil
            print("program init failure")
        }
        
        vertexTexCoordAttributeIndex = _program.attributeIndex(attributeName: "texCoord")
        _program.use()
        
        self.configureBuffer()
    }
    
    func configureBuffer() {
        
        var vertices: UnsafeMutablePointer<Float>?
        var textCoord:UnsafeMutablePointer<Float>?
        var indices: UnsafeMutablePointer<Int16>?
        var numVertices: Int32? = 0
        
        numIndices = Int(GLuint(myGenVertices(&vertices, &textCoord, &indices, &numVertices!)))
        
        // Indices
        var tempVertexIndicesBufferID: GLuint = 0
        glGenBuffers(1, &tempVertexIndicesBufferID)
        vertexIndicesBufferID = tempVertexIndicesBufferID
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), vertexIndicesBufferID)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), numIndices*3*MemoryLayout<GLushort>.size, indices, GLenum(GL_STATIC_DRAW))
        
        // Vertex
        var tempVertexBufferID: GLuint = 0
        glGenBuffers(1, &tempVertexBufferID)
        vertexBufferID = tempVertexBufferID
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferID)
        glBufferData(GLenum(GL_ARRAY_BUFFER), Int(numVertices!)*3*MemoryLayout<GLfloat>.size, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*3), nil)
        
        // Texture Coordinates
        var tempVertexTexCoordID: GLuint = 0
        glGenBuffers(1, &tempVertexTexCoordID)
        vertexTexCoordID = tempVertexTexCoordID
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexTexCoordID)
        glBufferData(GLenum(GL_ARRAY_BUFFER), Int(numVertices!)*2*MemoryLayout<GLfloat>.size, textCoord, GLenum(GL_DYNAMIC_DRAW))
        
        glEnableVertexAttribArray(vertexTexCoordAttributeIndex);
        glVertexAttribPointer(vertexTexCoordAttributeIndex, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*2), nil);
        
    }
    
    static func createTexture(width: GLsizei, height: GLsizei, internalformat: Int32, format: Int32, type: Int32) -> myGLTexture2D {
        let texture: myGLTexture2D = myGLTexture2D.init(width: width, height: height, texid: GLuint(0), format: format, type: type)
        
        glGenTextures(1, &texture._textureid)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture._textureid)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(internalformat), width, height, 0, GLenum(format), GLenum(type), nil)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        return texture
    }
    
    func setTexSub2D(tex_name: String, tex: myGLTexture2D, num: Int32, texture_num: Int32, value: UnsafeRawPointer) {
        glActiveTexture(GLenum(texture_num))
        glBindTexture(GLenum(GL_TEXTURE_2D), tex._textureid)
        glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, tex._width, tex._height, GLenum(tex._format), GLenum(tex._type), value)
        
        glUniform1i(GLint(_program!.uniformIndex(uniformName: tex_name)), GLint(num))
    }
    
    func renderScene() {
        
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        //var gl_error = glGetError()
        //print("glerror r1:", gl_error)
        
        glViewport(0, 0, _rtt._width, _rtt._height)
        _rtt.bind()
        //gl_error = glGetError()
        //print("glerror r2:", gl_error)
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferID)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexTexCoordID)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), vertexIndicesBufferID)
        
        //gl_error = glGetError()
        //print("glerror r3:", gl_error)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(numIndices*3), GLenum(GL_UNSIGNED_SHORT), nil);
        
        //gl_error = glGetError()
        //print("glerror r4:", gl_error)
        _rtt.unbind_to_lastfbo()
    }
    
    func getFramebufferImage() -> UIImage? {
        let byteLength = Int(_rtt._width * _rtt._height)
        var bytes = [UInt32](repeating: 0, count: Int(byteLength))
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _rtt._framebuffer)
        glReadPixels(0, 0, _rtt._width, _rtt._height, GLenum(_rtt._format), GLenum(_rtt._type), &bytes)
        var anUIImage: UIImage! = nil
        
        let gl_error = glGetError()
        if gl_error == 0 {
            anUIImage = getUIImagefromRGBABuffer(src_buffer: &bytes, width: Int(_rtt._width), height: Int(_rtt._height))
        } else {
            print("glerror:", gl_error)
        }
        return anUIImage
    }
    
    func getFramebuffer3Images() -> (UIImage?, UIImage?, UIImage?) {
        let byteLength = Int(_rtt._width * _rtt._height)
        var bytes = [UInt32](repeating: 0, count: Int(byteLength))
        var b8 = [UInt8](repeating: 0, count: Int(byteLength))
        var anUIImage: UIImage! = nil
        var anUIImage1: UIImage! = nil
        var anUIImage2: UIImage! = nil
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _rtt._framebuffer)
        glReadBuffer(GLenum(GL_COLOR_ATTACHMENT0))
        glReadPixels(0, 0, _rtt._width, _rtt._height, GLenum(_rtt._format), GLenum(_rtt._type), &bytes)
        
        var gl_error = glGetError()
        if gl_error == 0 {
            anUIImage = getUIImagefromRGBABuffer(src_buffer: &bytes, width: Int(_rtt._width), height: Int(_rtt._height))
        } else {
            print("glerror GL_COLOR_ATTACHMENT0:", gl_error)
        }
        
        
        glReadBuffer(GLenum(GL_COLOR_ATTACHMENT1))
        glReadPixels(0, 0, _rtt._width, _rtt._height, GLenum(GL_RED), GLenum(_rtt._type), &b8)
        for i in 0..<byteLength {
            let tmp:UInt32 = UInt32(b8[i])
            bytes[i] = UInt32(0xff) << 24
            bytes[i] |= (tmp << 16)
            bytes[i] |= tmp << 8
            bytes[i] |= tmp
        }
        gl_error = glGetError()
        if gl_error == 0 {
            anUIImage1 = getUIImagefromRGBABuffer(src_buffer: &bytes, width: Int(_rtt._width), height: Int(_rtt._height))
        } else {
            print("glerror GL_COLOR_ATTACHMENT1:", gl_error)
        }
        
        
        glReadBuffer(GLenum(GL_COLOR_ATTACHMENT2))
        glReadPixels(0, 0, _rtt._width, _rtt._height, GLenum(GL_RED), GLenum(_rtt._type), &b8)
        for i in 0..<byteLength {
            let tmp:UInt32 = UInt32(b8[i])
            bytes[i] = UInt32(0xff) << 24
            bytes[i] |= (tmp << 16)
            bytes[i] |= tmp << 8
            bytes[i] |= tmp
        }
        gl_error = glGetError()
        if gl_error == 0 {
            anUIImage2 = getUIImagefromRGBABuffer(src_buffer: &bytes, width: Int(_rtt._width), height: Int(_rtt._height))
        } else {
            print("glerror GL_COLOR_ATTACHMENT2:", gl_error)
        }
        
        return (anUIImage, anUIImage1, anUIImage2)
    }
    
    func getFramebufferImageGray() -> UIImage? {
        let byteLength = Int(_rtt._width * _rtt._height)
        var bytes = [UInt8](repeating: 0, count: Int(byteLength))
        var b2 = [UInt32](repeating: 0, count: Int(byteLength))
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _rtt._framebuffer)
        glReadPixels(0, 0, _rtt._width, _rtt._height, GLenum(_rtt._format), GLenum(_rtt._type), &bytes)
        
        for i in 0..<byteLength {
            let tmp:UInt32 = UInt32(bytes[i])
            b2[i] = UInt32(0xff) << 24
            b2[i] |= (tmp << 16)
            b2[i] |= tmp << 8
            b2[i] |= tmp
        }
        
        var anUIImage: UIImage! = nil
        
        let gl_error = glGetError()
        if gl_error == 0 {
            anUIImage = getUIImagefromRGBABuffer(src_buffer: &b2, width: Int(_rtt._width), height: Int(_rtt._height))
        } else {
            print("glerror:", gl_error)
        }
        return anUIImage
    }
}

public func getUIImagefromRGBABuffer(src_buffer: UnsafeMutableRawPointer, width: Int, height: Int) -> UIImage {
    var colorSpace: CGColorSpace?
    var alphaInfo: CGImageAlphaInfo!
    var bmcontext: CGContext?
    colorSpace = CGColorSpaceCreateDeviceRGB()
    alphaInfo = .noneSkipLast
    
    bmcontext = CGContext(data: src_buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace!, bitmapInfo: alphaInfo.rawValue)!
    let rgbImage: CGImage? = bmcontext!.makeImage()
    if rgbImage == nil {
        fatalError()
    }
    let anUIImage = UIImage(cgImage: rgbImage!)
    return anUIImage
}

public func getUIImagefromGrayBuffer(src_buffer: UnsafeMutableRawPointer, width: Int, height: Int) -> UIImage {
    var colorSpace: CGColorSpace?
    var alphaInfo: CGImageAlphaInfo!
    var bmcontext: CGContext?
    colorSpace = CGColorSpaceCreateDeviceGray()
    alphaInfo = .none
    
    if colorSpace == nil {
        fatalError()
    }
    
    bmcontext = CGContext(data: src_buffer, width: width, height: height, bitsPerComponent: 2, bytesPerRow: width, space: colorSpace!, bitmapInfo: alphaInfo.rawValue)!
    let rgbImage: CGImage? = bmcontext!.makeImage()
    if rgbImage == nil {
        fatalError()
    }
    let anUIImage = UIImage(cgImage: rgbImage!)
    return anUIImage
}
