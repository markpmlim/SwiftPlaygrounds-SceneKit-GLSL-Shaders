#version 410 core

out VS_GS
{
    vec3 position;
} vs_out;

void main()
{
    // Tthe coords of a 2x2 square made up of 2 triangle strips.
    const vec2 verts[4] = vec2[4](vec2(-1.0, -1.0),
                                  vec2( 1.0, -1.0),
                                  vec2(-1.0,  1.0),
                                  vec2( 1.0,  1.0));
    vs_out.position = vec3(verts[gl_VertexID], 0.0);
}
