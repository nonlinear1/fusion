//
//  myGLRTT.swift
//  AR
//
//  Created by jhw on 30/11/2017.
//  Copyright © 2017 zju.gaps. All rights reserved.
//

import Foundation
import GLKit

class myGLRTT {
    var _width: GLsizei = 0
    var _height: GLsizei = 0
    
    var _framebuffer: GLuint = 0
    var _texture: GLuint = 0
    var _lastfbo: GLint = 0
    
    var _numChannels: Int = 0
    var _internalformat: Int32 = 0
    var _format: Int32 = 0
    var _type: Int32 = 0
    
    init(width: GLsizei, height: GLsizei, internalformat: Int32, format: Int32, type: Int32) {
        glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &_lastfbo)
        
        switch format {
        case Int32(GL_RED), Int32(GL_GREEN), Int32(GL_BLUE): _numChannels = 1;
        case Int32(GL_RGB): _numChannels = 3;
        case Int32(GL_RGBA): _numChannels = 4;
        default:
            break
        }
        print("numChannels:", _numChannels)
        
        _width = width
        _height = height
        
        _internalformat = internalformat
        _format = format
        _type = type
        
        glGenFramebuffers(1, &_framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer)
        
        glGenTextures(1, &_texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), _texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(_internalformat), width, height, 0, GLenum(_format), GLenum(_type), nil)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), _texture, 0)
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        if status != GLenum(GL_FRAMEBUFFER_COMPLETE) {
            print("ERROR: generate frame buffer error with", width, height, "status:", status)
            print("right: ", GLenum(GL_FRAMEBUFFER_COMPLETE))
            
            print("GL_FRAMEBUFFER_UNDEFINED:",GLenum(GL_FRAMEBUFFER_UNDEFINED))
            print("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:",GLenum(GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT))
            print("GL_FRAMEBUFFER_UNSUPPORTED:",GLenum(GL_FRAMEBUFFER_UNSUPPORTED))
        }
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLenum(_lastfbo))
    }
    
    func bind() {
        glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &_lastfbo)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer)
    }
    
    func unbind_to_lastfbo() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLenum(_lastfbo))
    }
    
    func unbind_to_0() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }
}