shader_type canvas_item;


vec4 soft_light(vec4 base, vec4 blend) {
    vec4 limit = step(0.5, blend);
    return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void fragment() {
    vec4 baseColor = texture(TEXTURE, UV);
    vec4 blendColor = vec4(1.0, 1.0, 1.0, 1.0);
    COLOR = soft_light(baseColor, blendColor);
}