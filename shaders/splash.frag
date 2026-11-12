// Splash ledakan Debug Rush: dither piksel (matriks Bayer 4x4, sel 6 dp)
// berwarna fg yang menyebar dari posisi bug sampai menutup layar dalam 35%
// pertama durasi, lalu luruh; hilang tepat saat freeze (0,6 s) selesai.
// Sama dengan drawSplash() di bahan/mockup/minigame-gameplay-mockup.html.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // ukuran area (dp)
uniform vec2 uOrigin;   // posisi bug yang meledak (dp)
uniform float uProgress; // 0 -> 1 sepanjang freeze
uniform float uCell;    // sisi sel dither (dp)
uniform vec4 uColor;    // warna fg tema aktif

out vec4 fragColor;

// Nilai ambang Bayer 2x2 dan 4x4 (0..15/16).
float bayer2(vec2 a) {
  a = floor(a);
  return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(vec2 a) {
  return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 cell = floor(p / uCell);
  vec2 center = (cell + 0.5) * uCell;

  float maxD = max(
    max(length(uOrigin), length(vec2(uSize.x - uOrigin.x, uOrigin.y))),
    max(length(vec2(uOrigin.x, uSize.y - uOrigin.y)), length(uSize - uOrigin))
  );
  float k = uProgress;
  float spread = 1.0 - pow(1.0 - clamp(k / 0.35, 0.0, 1.0), 3.0);
  float radius = maxD * spread + uCell;
  float glob = k < 0.35 ? 1.0 : 1.0 - (k - 0.35) / 0.65;

  float d = length(center - uOrigin);
  if (d > radius) {
    fragColor = vec4(0.0);
    return;
  }
  float loc = glob * (1.0 - 0.4 * d / maxD);
  float band = 70.0;
  if (d > radius - band) {
    loc *= (radius - d) / band;
  }
  float threshold = bayer4(cell) + 0.5 / 16.0;
  fragColor = threshold < loc ? vec4(uColor.rgb * uColor.a, uColor.a) : vec4(0.0);
}
