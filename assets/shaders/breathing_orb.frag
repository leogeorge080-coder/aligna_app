precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_intensity;
uniform vec4 u_primary;
uniform vec4 u_secondary;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  vec2 center = uv - vec2(0.5);
  float r = length(center);

  float pulse = 0.015 * sin(u_time) + u_intensity;
  float glow = smoothstep(0.55, 0.0, r + pulse * 0.04);
  vec4 color = mix(u_secondary, u_primary, glow);

  float alpha = smoothstep(0.6, 0.0, r);
  fragColor = vec4(color.rgb, alpha);
}
