#version 410 core

// Input from geometry shader
in GS_FS
{
    vec4 color;
} fs_in;

// By default, output to color attachment 0 if there is no layout qualifier.
layout(location = 0) out vec4 fragColor;

void main()
{
    fragColor = fs_in.color;
}
