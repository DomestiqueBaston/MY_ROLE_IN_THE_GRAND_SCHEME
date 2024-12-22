shader_type canvas_item;

uniform sampler2D overlay_texture; // Texture de l'overlay en niveaux de gris
uniform vec4 overlay_color = vec4(1.0, 1.0, 1.0, 1.0); // Couleur pour teinter l'overlay
uniform float overlay_intensity = 1.0; // Intensité du Soft Light

void fragment() {
    vec4 background = texture(TEXTURE, UV);
    vec4 overlay = texture(overlay_texture, UV) * overlay_color;

    // L'overlay est en niveaux de gris, donc on utilise une seule composante pour le calcul.
    float gray_overlay = overlay.r;

    // Calcul du mode Soft Light pour chaque canal.
    vec3 result = vec3(0.0);
    for (int i = 0; i < 3; i++) {
        if (background[i] < 0.5) {
            result[i] = 2.0 * background[i] * gray_overlay;
        } else {
            result[i] = 1.0 - 2.0 * (1.0 - background[i]) * (1.0 - gray_overlay);
        }
    }

    // Application de la transparence et de l'intensité.
    vec4 final_color = vec4(mix(background.rgb, result, overlay.a * overlay_intensity), background.a);

    COLOR = final_color;
}