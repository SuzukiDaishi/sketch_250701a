/* ============================================================
 *  HoloIridescenceDemo.pde
 *  ------------------------------------------------------------
 *  DEMO:
 *    • <space>  : BOX ↔ SPHERE
 *    • <I>      : ICO on/off
 *    • <B>      : MIRROR ↔ BUBBLE (透明屈折モード)
 *  ========================================================= */
import processing.opengl.*;

PShape geom;            // current geometry
PShader holo;           // GLSL shader
PImage  bgImg;          // background image

/* material parameters */
float thin  = 1.0f;     // thin-film (µm)
float rough = 0.15f;    // 0–1

/* mode switching */
int  renderMode = 0;    // 0 = MIRROR, 1 = BUBBLE
boolean useBox = true;
boolean useIco = false;

/* ----------------------------------------------------------- */
void settings(){ size(900, 650, P3D); }

void setup(){
  surface.setTitle("Holographic Iridescence  |  <space>/<I>/<B>");
  noStroke();
  updateGeometry();

  /* load shader */
  holo = loadShader("holo.frag", "holo.vert");
  holo.set("thinFilmBase", thin);
  holo.set("roughness",   rough);
  holo.set("resolution",  (float)width, (float)height);

  /* background image */
  bgImg = loadImage("windows.jpg");
  bgImg.resize(width, height);
  holo.set("bgTex", bgImg);          // send once (static)
}

void draw(){
  /* 0) clear screen & depth, draw background without depth write */
  background(0);
  hint(DISABLE_DEPTH_TEST);
  image(bgImg, 0, 0, width, height);
  hint(ENABLE_DEPTH_TEST);

  /* 1) set mode & alpha uniforms */
  holo.set("mode", renderMode);
  holo.set("alpha", renderMode==0 ? 1.0f : 0.35f);

  /* 2) enable blending only for transparent bubble mode */
  if(renderMode==1){
    PGL pgl = beginPGL();
    pgl.enable(PGL.BLEND);
    pgl.blendFunc(PGL.SRC_ALPHA, PGL.ONE_MINUS_SRC_ALPHA);
    endPGL();
  }

  /* 3) draw geometry */
  shader(holo);
  pushMatrix();
    translate(width*0.5f, height*0.55f);
    rotateY(frameCount*0.006f);
    rotateX(frameCount*0.004f);
    shape(geom);
  popMatrix();
  resetShader();

  if(renderMode==1){
    PGL pgl = beginPGL();
    pgl.disable(PGL.BLEND);
    endPGL();
  }

  /* 4) UI text (always on top) */
  hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(12);
  String shapeName = useBox ? "BOX" : useIco ? "ICOSAHEDRON" : "SPHERE";
  String modeName  = renderMode==0 ? "MIRROR" : "BUBBLE";
  text(shapeName+"  |  mode: "+modeName+"   (space / I / B)", 10, height-10);
  hint(ENABLE_DEPTH_TEST);
}

/* ---------------- keyboard ---------------- */
void keyPressed(){
  if(key==' '){
    useBox = !useBox;
    useIco = false;
    updateGeometry();
  } else if(key=='i' || key=='I'){
    useIco = !useIco;
    useBox = false;
    updateGeometry();
  } else if(key=='b' || key=='B'){
    renderMode = 1 - renderMode;     // toggle
  }
}

/* ---------------- helpers ---------------- */
void updateGeometry(){
  if(useBox)      geom = createShape(BOX, 250);
  else if(useIco) geom = createIcosahedron(220);
  else            geom = createShape(SPHERE, 220);
}

/* faceted icosahedron generator */
PShape createIcosahedron(float r){
  float t = (1 + sqrt(5)) / 2.0f;
  float s = r / sqrt(1 + t*t);

  /* vertices */
  float[][] v = {
    {-s,  t*s,  0}, { s,  t*s,  0}, {-s, -t*s,  0}, { s, -t*s, 0},
    { 0, -s,  t*s}, { 0,  s,  t*s}, { 0, -s, -t*s}, { 0,  s, -t*s},
    { t*s, 0, -s}, { t*s, 0,  s}, {-t*s, 0, -s}, {-t*s, 0,  s}
  };
  /* face indices */
  int[][] idx = {
    {0,11,5},{0,5,1},{0,1,7},{0,7,10},{0,10,11},
    {1,5,9},{5,11,4},{11,10,2},{10,7,6},{7,1,8},
    {3,9,4},{3,4,2},{3,2,6},{3,6,8},{3,8,9},
    {4,9,5},{2,4,11},{6,2,10},{8,6,7},{9,8,1}
  };

  PShape ico = createShape();
  ico.beginShape(TRIANGLES);
  ico.noStroke();
  for(int[] f : idx){
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
