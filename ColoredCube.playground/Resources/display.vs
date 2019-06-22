#version 410 core

layout(location = 0) in vec3 in_position;

uniform mat4 MVP = mat4(1);

out VS_FS
{
	smooth vec3 cubemap_texcoord;
} vs_out;

void main()
{
    gl_Position = MVP * vec4(in_position, 1);
    vs_out.cubemap_texcoord = in_position;
}
