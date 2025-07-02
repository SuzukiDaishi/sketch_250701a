# Holographic Bubble Demo (Processing 4)

> **Updated July 2025 – single‑mode transparent bubble with keyboard‑only control**
> Built with OpenAI ChatGPT. No external GUI or libraries required.

---

## ✨ What this sketch does

* Renders a **transparent “soap bubble / holographic plastic”** object

  * RGB‑wise Snell refraction → large‐scale background warp
  * Thin‑film interference for rainbow colours
  * Subtle GGX rim highlights (`roughness`)
  * Optional curl‑noise wobble for *Liquid Glass* feel (default gentle 0.10)
* Background is a static image (`windows.jpg`) drawn each frame.
* All material parameters are tweakable **via simple keyboard shortcuts** – no GUI library needed.

---

## 🗂 Folder layout

```
HoloBubbleWarp/
 ├─ HoloBubbleWarp.pde   ← main sketch (this file)
 └─ data/
     ├─ holo.vert         ← vertex shader
     ├─ holo.frag         ← fragment shader
     └─ windows.jpg       ← background image (any 16:9 JPG works)
```

---

## 🎹 Keyboard controls

| Keys      | Parameter                           | Range / Step | Default     |
| --------- | ----------------------------------- | ------------ | ----------- |
| **SPACE** | Geometry shape                      | BOX ↔ SPHERE | BOX         |
| **I / i** | Toggle Icosahedron                  | on/off       | off         |
| **A / Z** | Alpha (transparency) ±0.05          | 0 – 1        | **0.35**    |
| **T / G** | Thin‑film thickness ±0.05 µm        | 0.3 – 1.5    | **1.00** µm |
| **D / F** | Lens depth (radius) ±0.15           | 1.0 – 4.0    | **2.00**    |
| **W / S** | Projection distance (*farPlane*) ±2 | 8 – 40       | **20**      |
| **Y / H** | Warp scale multiplier ±0.2          | 0.5 – 4      | **1.5**     |
| **U / J** | Noise amplitude ±0.02               | 0 – 0.3      | **0.10**    |
| **K / L** | Dispersion strength ±0.1            | 0 – 2        | **1.0**     |
| **R / E** | Roughness ±0.02                     | 0 – 0.4      | **0.12**    |
| **P**     | Save screenshot                     | –            | –           |

A live HUD at the bottom‑left shows current values.

---

## 🛠 Build & run

1. Install **Processing 4** (tested on 4.3).
2. Clone / copy this folder.
3. Place a background JPG named `windows.jpg` inside **data/** (any 16:9 image works).
4. Open `HoloBubbleWarp.pde` in Processing and press **Run**.

No additional libraries are required; the sketch relies only on standard P3D and GLSL 1.50.

### Command‑line usage

1. In the Processing IDE choose **Tools → Install "processing‑java"** to install the CLI helper.
2. Run the sketch from a terminal:

   ```bash
   processing-java --sketch=/path/to/sketch_250701a --run
   ```

   When running headless (e.g. on a server) you may need a virtual display such as **Xvfb**.

### Capturing frames

Within the sketch you can call `saveFrame("frame-####.png");` to write screenshots. Pressing **Ctrl+S** (or `Cmd+S` on macOS) while the sketch window is focused also saves an image to the sketch folder.

---

## ⚙️ Technical notes

* **Accurate refraction offset**
  Refracted ray intersects a distant plane (background) and offsets UVs from the
  current screen coordinate.
* **Dispersion** sampled at three wavelengths (R/G/B) using slightly different IOR values (1.333 / 1.340 / 1.348).
* **Thin‑film** interference uses the glTF `KHR_materials_iridescence` 3‑wavelength cosine approximation.
* **Warp strength** ≈ `warpScale × (farPlane − lensDepth)/farPlane` so perspective and scene depth influence distortion.
* **Curl‑noise wobble** (P\_Malin *Liquid Glass* method) adds subtle spatial‑temporal variation; set `noiseAmp` → 0 to disable.

---

## 📜 Credits & references

* Intel 2015 – *Screen‑Space Fluid Refraction* (ray/plane projection)
* glTF 2.0 – *KHR\_materials\_iridescence* (thin‑film approximation)
* P. Malin – Shadertoy *Liquid Glass* (curl‑noise wobble)
* Demo authored & consolidated with help from **OpenAI ChatGPT**.

Released under the MIT License – feel free to remix and play!
