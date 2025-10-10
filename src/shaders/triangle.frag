#version 330 core

in vec4 vertColor;

out vec4 fragColor;

uniform float utime;

void main() {
  fragColor = vertColor * (sin(utime) / 2 + 0.5);
}
