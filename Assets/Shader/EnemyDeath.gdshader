shader_type canvas_item;

uniform sampler2D dissolve_texture : hint_albedo;
uniform float effect_percentage : hint_range(0,1);

void fragment(){
	float time = TIME;
    vec4 main_texture = texture(TEXTURE, UV);
    vec4 noise_texture = texture(dissolve_texture, UV);
    main_texture.a *= min(floor(effect_percentage *  abs(UV.y*UV.y+1.0) + noise_texture.y) , 1.0);
    COLOR = main_texture;
}