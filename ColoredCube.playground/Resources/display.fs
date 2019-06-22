#version 410 core

in VS_FS
{
    smooth vec3 cubemap_texcoord;
} fs_in;

uniform samplerCube cubemap;

out vec4 fragColor;

void main()
{
    fragColor = texture(cubemap, fs_in.cubemap_texcoord);
}
