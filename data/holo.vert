#version 150
// Matrices supplied by Processing
uniform mat4 transform;       // projection * modelview
uniform mat4 modelview;
uniform mat3 normalMatrix;

in  vec4 vertex;              // <-- attribute names per Processing spec
in  vec3 normal;

out vec3 vNormal;
out vec3 vViewDir;

void main(){
    vNormal  = normalize(normalMatrix * normal);
    vec4 viewPos = modelview * vertex;
    vViewDir = normalize(-viewPos.xyz);
    gl_Position = transform * vertex;
}
