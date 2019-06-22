#version 410 

uniform int tessLevel;

// the following are interpolated values from the tes
in vec3 normal;
in vec3 vpos;
in vec2 uv;

struct MaterialInfo
{
    vec4    ambient;
    vec4    diffuse;
    vec4    specular;
    float   shininess;
};
uniform MaterialInfo material;

struct LightInfo
{
    vec4 position;  // Light position in eye coords.
    vec3 specular;
    vec3 diffuse;
};
uniform LightInfo lightSource;

uniform vec4 lightModelAmbient;

out vec4 fragColor;

void main()
{
    // calculate direction towards the light source
    vec3 ldir = lightSource.position.xyz - vpos;

    vec3 n = normalize(normal);
    vec3 v = -normalize(vpos);  // view vector
    vec3 l = normalize(ldir);
    vec3 h = normalize(l + v);  // halfway vector

    float ndotl = max(dot(n, l), 0.0);
    float ndoth = max(dot(n, h), 0.0);

    vec3 ka = material.ambient.xyz;
    vec3 kd = material.diffuse.xyz;
    vec3 ks = material.specular.xyz;
    float shin = material.shininess;

    vec3 diffuse = kd * ndotl * lightSource.diffuse.xyz;
    vec3 specular = ks * pow(ndoth, shin) * lightSource.specular.xyz;
    vec3 ambient = ka * lightModelAmbient.xyz;
    vec3 color = ambient + diffuse + specular;

    vec2 tess_uv = mod(uv * float(tessLevel), 1.0);

#define STEPSZ  0.1
    float wire = smoothstep(0.0, STEPSZ,
                            tess_uv.x) * smoothstep(1.0, 1.0 - STEPSZ,
                                                    tess_uv.x);
    wire *= smoothstep(0.0, STEPSZ,
                       tess_uv.y) * smoothstep(1.0, 1.0 - STEPSZ, tess_uv.y);

    fragColor = vec4(mix(vec3(0.0, 0.0, 0.0), color, wire), material.diffuse.w);
}
