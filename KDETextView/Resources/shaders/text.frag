uniform sampler2D texture;
uniform vec3 pixel;

varying vec4 vcolor;
varying vec2 vtex_coord;
varying float vshift;
varying float vgamma;

void main()
{
    float a = texture2D(texture, vtex_coord).r;
    gl_FragColor = vec4( vcolor.rgb, a);
}