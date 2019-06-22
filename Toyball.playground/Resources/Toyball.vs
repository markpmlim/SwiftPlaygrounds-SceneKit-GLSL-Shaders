#version 330 core
//
// Fragment shader for procedurally generated toy ball
//
// Author: Bill Licea-Kane
//
// Copyright (c) 2002-2003 ATI Research 
//
// See ATI-License.txt for license information
//
// Texcoords and surface normals are not used

layout( location = 0 ) in vec4 vertexPosition;

uniform vec4 ballCenter;		// ball center in modelling (object) coordinates
uniform mat4 modelViewMatrix;
uniform mat4 mvpMatrix;

out vec3 ocPosition;
out vec4 ecPosition;			// surface position in eye(view) coordinates
flat out vec4 ecBallCenter;		// ball center in eye(view) coordinates

void main(void)
{ 
    ocPosition	 = vertexPosition.xyz;
    ecPosition   = modelViewMatrix * vertexPosition;
    ecBallCenter = modelViewMatrix * ballCenter;

    gl_Position  = mvpMatrix * vertexPosition;
}
