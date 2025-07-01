// CORRECTED SHADER CODE
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform sampler2D noise_texture;
uniform vec4 edge_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	// Get the sprite's original pixel color from the texture
	vec4 texture_color = texture(TEXTURE, UV);
	
	// Get the noise value for the dissolve pattern
	float noise_value = texture(noise_texture, UV).r;
	
	float threshold = progress;

	// If the noise value is less than our threshold, the pixel disappears.
	if (noise_value < threshold) {
		discard;
	}
	
	// Start with the base texture color
	vec4 final_color = texture_color;
	
	// If it's on the edge, mix in the glow color
	if (noise_value < threshold + edge_width) {
		final_color = mix(texture_color, edge_color, 0.8);
	}
	
	// --- THIS IS THE KEY FIX FOR THE FLASH ---
	// Multiply our calculated color by the sprite's modulate color (passed in as COLOR).
	// This allows the red flash tween to work.
	COLOR = final_color * COLOR;
	
	// Also respect the original texture's transparency
	COLOR.a *= texture_color.a;
}