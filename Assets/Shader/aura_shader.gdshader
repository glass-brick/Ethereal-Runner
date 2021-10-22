shader_type canvas_item;
render_mode blend_mix;

uniform float radius = 5.0;
uniform vec4 modulate: hint_color;
uniform vec4 modulate_active: hint_color;
uniform bool active;
uniform float time_scale = 20;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * abs(cos(TIME));

	vec4 shadow = texture(TEXTURE, UV + vec2(-radius, -radius) * ps);

	shadow += texture(TEXTURE, UV + vec2(-radius, 0.0) * ps);
	shadow += texture(TEXTURE, UV + vec2(-radius, radius) * ps);
	shadow += texture(TEXTURE, UV + vec2(0.0, -radius) * ps);
	shadow += texture(TEXTURE, UV + vec2(0.0, radius) * ps);
	shadow += texture(TEXTURE, UV + vec2(radius, -radius) * ps);
	shadow += texture(TEXTURE, UV + vec2(radius, 0.0) * ps);
	shadow += texture(TEXTURE, UV + vec2(radius, radius) * ps);
	shadow /= 0.200 * abs(cos(TIME));
	shadow *= modulate;

	vec4 col = texture(TEXTURE, UV);
	COLOR = mix(shadow, col, col.a);
	
	if(active){
		if (!active || cos(TIME * time_scale) > 0.0) {
			COLOR = mix(shadow, col, col.a);
		} else {
			COLOR = mix(shadow, vec4(modulate_active.rgb, texture(TEXTURE, UV).a * modulate_active.a), col.a); 
	}

	}
}
