#version 150
uniform mat4 transform, modelview;
uniform mat3 normalMatrix;

in  vec4 vertex; in  vec3 normal;
out vec3 vN, vV, vPosV;

void main(){
  vN = normalize(normalMatrix*normal);
  vec4 vp = modelview * vertex; vPosV = vp.xyz;
  vV = normalize(-vp.xyz);
  gl_Position = transform * vertex;
}