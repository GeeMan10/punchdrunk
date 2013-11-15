//
//  Shader2.vsh
//  Punch Drunk 4
//
//  Created by Gurmit Singh on 10/11/2013.
//  Copyright (c) 2013 RuleOnSix. All rights reserved.
//

attribute vec4 position2;
attribute vec3 normal2;
attribute vec4 position;
attribute vec3 normal;
varying lowp vec4 colorVarying2;

uniform mat4 modelViewProjectionMatrix2;
uniform mat3 normalMatrix2;
uniform float target;
uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;
void main()
{
    if (target < 1.0) {
        vec3 eyeNormal = normalize(normalMatrix * normal);
        
        vec3 lightPosition = vec3(1.0, 0.0, 0.0);
        vec4 diffuseColor = vec4(1.0,0.0, 0.0, 1.0);
        
        float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
        colorVarying2 = diffuseColor * nDotVP;
        
        gl_Position = modelViewProjectionMatrix * position;

    }
    else if (target > 0.0) {
        
        vec3 eyeNormal2 = normalize(normalMatrix2 * normal2);
        vec3 lightPosition2 = vec3(1.0, 0.0, 0.0);
        vec4 diffuseColor2 = vec4(0.0,1.0, 0.0, 1.0);
         float nDotVP2 = max(0.0, dot(eyeNormal2, normalize(lightPosition2)));
        colorVarying2 = diffuseColor2 * nDotVP2;
        
        gl_Position = (modelViewProjectionMatrix2 * position2);

    }
   
    
    
    }
