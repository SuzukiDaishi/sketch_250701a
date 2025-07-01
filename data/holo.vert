#version 150

uniform mat4 transform;   /* projection * modelview */
uniform mat4 modelview;
uniform mat3 normalMatrix;

in  vec4 vertex;          /* default P3D attributes */
in  vec3 normal;

out vec3 vN;
out vec3 vV;

void main(){
    vN = normalize(normalMatrix * normal);
    vec4 viewPos = modelview * vertex;
    vV = normalize(-viewPos.xyz);
    gl_Position = transform * vertex;
}
