//shader_type canvas_item;
//
//
//uniform sampler2D dissolve_pattern;
//uniform float dissolve_state : hint_range(-0.01, 1.01) = 0; // 1.01 was 1.1 and -0.01 was 0
//
//void fragment(){
	//COLOR = texture(TEXTURE, UV);
	//float pattern_val = texture(dissolve_pattern, UV).r;
	//COLOR.a *= step(dissolve_state, pattern_val);
//}

shader_type canvas_item;

uniform sampler2D dissolve_pattern;
uniform float dissolve_state : hint_range(-0.01, 1.01) = 0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;
uniform float dist : hint_range(0.1, 10.0) = 0.1; // paramètre pour contrôler l'éloignement

void fragment() {
    COLOR = texture(TEXTURE, UV);

    // moyenne des valeurs autour du pixel actuel
    float sum = 0.0;
    int samples = 0;
    float step = dist / 10.0; // pas en fonction de la distance

    for (float x = -dist; x <= dist; x += step) {
        for (float y = -dist; y <= dist; y += step) {
            vec2 offset = vec2(x, y) * 0.01; // échelle de l'offset
            sum += texture(dissolve_pattern, UV + offset).r;
            samples++;
        }
    }

    float average_pattern_val = sum / float(samples);

    // smoothstep pour adoucir la transition
    float smoothed_edge = smoothstep(dissolve_state - smoothness, dissolve_state + smoothness, average_pattern_val);

    COLOR.a *= smoothed_edge;
}

