// ----------------------  Processing 4  ----------------------
//  Holistic Holographic Demo:  sphere ↔ box ↔ icosahedron
// ------------------------------------------------------------
PShape geom;
PShader holo;

float thin  = 1.0;   // base thin-film thickness (μm 表現を 1.0=1μm と見る近似)
float rough = 0.15;  // surface roughness 0=mirror 1=diffuse

boolean useBox = true;  // start with a box; press <space> to toggle
boolean useIco = false; // press <I> to toggle icosahedron

void settings() {
  size(900, 650, P3D);
}

void setup() {
  surface.setTitle("Holographic Iridescence Demo  –  press <space> to toggle shape");
  noStroke();
  updateGeometry();

  holo = loadShader("holo.frag", "holo.vert");
  holo.set("thinFilmBase", thin);
  holo.set("roughness", rough);
}

void draw() {
  background(0);
  float t = millis() * 0.001f;
  holo.set("uTime", t);

  shader(holo);

  translate(width * 0.5f, height * 0.55f);
  rotateY(t * 0.35f);
  rotateX(t * 0.23f);
  shape(geom);

  resetShader();
  showHint();
}

void keyPressed() {
  if (key == ' '){ useBox = !useBox; useIco = false; updateGeometry(); }
  else if (key == 'i' || key == 'I'){ useIco = !useIco; useBox = false; updateGeometry(); }
}

// ---------- helpers ----------
void updateGeometry() {
  if (useBox)       geom = createShape(BOX, 250);
  else if (useIco)  geom = createIcosahedron(220);
  else              geom = createShape(SPHERE, 220);
}

void showHint(){
  fill(255); textSize(12);
  text("shape: " + (useBox ? "BOX" : useIco ? "ICOSAHEDRON" : "SPHERE") +
       "  |  press <space> or <I>", 10, height-10);
}

// quick icosa generator (edge-shared normals for crisp edges)
PShape createIcosahedron(float r){
  float t = (1+sqrt(5))/2, s = r / sqrt(1+t*t);
  float[][] v = {
    {-s,  t*s,  0}, { s,  t*s,  0}, {-s, -t*s,  0}, { s, -t*s, 0},
    { 0, -s,  t*s}, { 0,  s,  t*s}, { 0, -s, -t*s}, { 0,  s, -t*s},
    { t*s, 0, -s}, { t*s, 0,  s}, {-t*s, 0, -s}, {-t*s, 0,  s}
  };
  int[][] idx = {
    {0,11,5},{0,5,1},{0,1,7},{0,7,10},{0,10,11},
    {1,5,9},{5,11,4},{11,10,2},{10,7,6},{7,1,8},
    {3,9,4},{3,4,2},{3,2,6},{3,6,8},{3,8,9},
    {4,9,5},{2,4,11},{6,2,10},{8,6,7},{9,8,1}
  };
  PShape ico = createShape();
  ico.beginShape(TRIANGLES);
  ico.noStroke();
  for (int[] f : idx){
    PVector a = new PVector(v[f[0]][0], v[f[0]][1], v[f[0]][2]);
    PVector b = new PVector(v[f[1]][0], v[f[1]][1], v[f[1]][2]);
    PVector c = new PVector(v[f[2]][0], v[f[2]][1], v[f[2]][2]);
    PVector n = PVector.cross(PVector.sub(b,a), PVector.sub(c,a), null).normalize();
    ico.normal(n.x, n.y, n.z); ico.vertex(a.x, a.y, a.z);
    ico.normal(n.x, n.y, n.z); ico.vertex(b.x, b.y, b.z);
    ico.normal(n.x, n.y, n.z); ico.vertex(c.x, c.y, c.z);
  }
  ico.endShape();
  return ico;
}
