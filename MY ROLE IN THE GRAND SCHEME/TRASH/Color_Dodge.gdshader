shader_type canvas_item;


uniform float transparency = 1.0;

vec4 compositing(vec4 base, vec4 blend) {
    return base / (1.0 - blend);
}
void fragment() {
    vec4 baseColor = texture(TEXTURE, UV);
    vec4 blendColor = vec4(1.0, 1.0, 1.0, transparency);
    COLOR = compositing(baseColor, blendColor);
}