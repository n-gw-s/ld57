shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha, shadows_disabled, specular_disabled;

uniform sampler2D albedo_texture: source_color, filter_nearest;
uniform vec4 modulate: source_color = vec4(1.0);
uniform float jitter: hint_range(0, 1) = 0.75;
uniform float emission_amount = 0.0;
uniform vec2 uv_scale = vec2(1.0);
uniform vec3 backlight_color: source_color = vec3(1.0);
uniform float backlight_amount = 0.0;

vec4 snap(vec4 v) {
	vec4 s = v;
	s.xyz = v.xyz / v.w;
	vec2 r = vec2(480, 270);

	vec2 f = floor(r * (1.0 - jitter));
	s.x = floor(f.x * s.x) / f.x;
	s.y = floor(f.y * s.y) / f.y;

	s.xyz *= v.w;
	return s;
}

void vertex() {
	POSITION = snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

void fragment() {
	vec4 color_base = COLOR;
	vec2 uv = UV * uv_scale;
	vec4 tex_col = texture(albedo_texture, uv) * modulate;
	ALBEDO = (color_base * tex_col).rgb;
	ALPHA = tex_col.a * color_base.a * modulate.a;
	EMISSION = ALBEDO * emission_amount;
	BACKLIGHT = backlight_color * backlight_amount;
}