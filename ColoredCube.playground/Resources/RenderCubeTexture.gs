#version 410 core

// geometry shader instancing
layout (triangles, invocations = 6) in;
layout (triangle_strip, max_vertices = 3) out;

// Input from vertex shader.
in VS_GS
{
    vec3 position;
} gs_in[];

// Output to fragment shader.
out GS_FS
{
    vec4 color;
} gs_out;

const vec4 faceColor[6] = vec4[6]
(
    vec4(0.5, 0.5, 1.0, 1.0),   // +X
    vec4(1.0, 0.5, 0.5, 1.0),   // -X
    vec4(0.0, 0.5, 0.5, 1.0),   // +Y
    vec4(0.5, 1.0, 0.5, 1.0),   // -Y
    vec4(0.0, 0.5, 0.0, 1.0),   // +Z
    vec4(0.5, 0.0, 0.0, 1.0)    // -Z
);

void main()
{
    for (int vertex = 0; vertex < gl_in.length(); vertex++)
    {
        gl_Position = vec4(gs_in[vertex].position, 1.0);
        gs_out.color = faceColor[gl_InvocationID];
        gl_Layer = gl_InvocationID;
        EmitVertex();
   }
    EndPrimitive();
}
