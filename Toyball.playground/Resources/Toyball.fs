//
// Fragment shader for procedurally generated toy ball
//
// Author: Bill Licea-Kane
//
// Copyright (c) 2002-2003 ATI Research 
//
// See ATI-License.txt for license information

#version 330


uniform vec4 HalfSpace[5];  // half-spaces used to define star pattern
uniform float StripeWidth;
uniform float InOrOutInit = -3.0;
uniform float FWidth = 0.005;
uniform vec4 StarColor;
uniform vec4 StripeColor;
uniform vec4 BaseColor;
uniform vec4 LightDir;      // light direction, should be normalized
uniform vec4 HVector;       // reflection vector for infinite light

uniform vec4 SpecularColor;
uniform float SpecularExponent;
uniform float Ka = 0.3;
uniform float Kd = 0.7;
uniform float Ks = 0.4;

in vec4 ecPosition;         // surface position in eye(view) coordinates
in vec3 ocPosition;         // surface position in object coordinates
flat in vec4 ecBallCenter;  // ball center in eye(view) coordinates

out vec4 FragColor;

//https://stackoverflow.com/questions/44033605/why-is-metal-shader-gradient-lighter-as-a-scnprogram-applied-to-a-scenekit-node
float srgbToLinear(float c) {
    if (c <= 0.04045)
        return c / 12.92;
    else
        return pow((c + 0.055) / 1.055, 2.4);
}

void main()
{
    vec3 normal;            // Analytically computed normal
    vec4 pShade;            // Point in shader space
    vec4 surfColor;         // Computed color of the surface
    float intensity;        // Computed light intensity
    vec4 distance;          // Computed distance values
    float inorout;          // Counter for classifying star pattern

    pShade.xyz = normalize(ocPosition.xyz);
    pShade.w = 1.0;

    inorout = InOrOutInit;	// initialize inorout to -3.0

    distance[0] = dot(pShade, HalfSpace[0]);
    distance[1] = dot(pShade, HalfSpace[1]);
    distance[2] = dot(pShade, HalfSpace[2]);
    distance[3] = dot(pShade, HalfSpace[3]);

    //float FWidth = fwidth(pShade);
    distance = smoothstep(-FWidth, FWidth, distance);

    inorout += dot(distance, vec4(1.0));

    distance.x = dot(pShade, HalfSpace[4]);
    distance.y = StripeWidth - abs(pShade.z);
    distance.xy = smoothstep(-FWidth, FWidth, distance.xy);

    inorout += distance.x;
    inorout = clamp(inorout, 0.0, 1.0);

    surfColor = mix(BaseColor, StarColor, inorout);
    surfColor = mix(surfColor, StripeColor, distance.y);

    // Calculate analytic normal of a sphere
    normal = normalize(ecPosition.xyz-ecBallCenter.xyz);

    // Per-fragment diffuse lighting
    intensity = Ka;         // ambient
    intensity += Kd * clamp(dot(LightDir.xyz, normal), 0.0, 1.0);
    surfColor *= intensity;

    // Per-fragment specular lighting
    intensity = clamp(dot(HVector.xyz, normal), 0.0, 1.0);
    intensity = Ks * pow(intensity, SpecularExponent);
    surfColor.rgb += SpecularColor.rgb * intensity;

    surfColor.r = srgbToLinear(surfColor.r);
    surfColor.g = srgbToLinear(surfColor.g);
    surfColor.b = srgbToLinear(surfColor.b);

    FragColor = surfColor;
}
