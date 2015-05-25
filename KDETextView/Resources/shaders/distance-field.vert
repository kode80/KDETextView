uniform sampler2D texture;
uniform vec3 pixel;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

attribute vec3 vertex;
attribute vec4 color;
attribute vec2 tex_coord;

varying vec4 vcolor;
varying vec2 vtex_coord;

void main(void)
{
    vcolor = color;
    vtex_coord = tex_coord;
    gl_Position = projection*(view*(model*vec4(vertex,1.0)));
}


