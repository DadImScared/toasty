shader_type canvas_item;

// Adjustable parameters
uniform float outline_width : hint_range(0.0, 5.0) = 1.5;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 0.8);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 2.0;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.4;
uniform bool enable_shimmer = true;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;

    // Create outline by sampling neighboring pixels
    float outline = 0.0;
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;

    // Only create outline if current pixel is transparent
    if (original_color.a == 0.0) {
        // Sample in 8 directions
        for (float x = -outline_width; x <= outline_width; x += 1.0) {
            for (float y = -outline_width; y <= outline_width; y += 1.0) {
                if (x == 0.0 && y == 0.0) continue;

                vec2 offset = vec2(x, y) * pixel_size;
                vec4 neighbor = texture(TEXTURE, UV + offset);

                if (neighbor.a > 0.0) {
                    float distance = length(vec2(x, y));
                    if (distance <= outline_width) {
                        outline = max(outline, (outline_width - distance) / outline_width);
                    }
                }
            }
        }
    }

    // Create shimmer effect
    float shimmer = 1.0;
    if (enable_shimmer && original_color.a > 0.0) {
        shimmer = sin(TIME * shimmer_speed + UV.x * 10.0 + UV.y * 10.0) * 0.5 + 0.5;
        shimmer = 0.7 + (shimmer * shimmer_strength);
    }

    // Apply glow to original sprite
    vec4 final_color = original_color;
    if (original_color.a > 0.0) {
        // Add glow effect to the sprite itself
        final_color.rgb *= shimmer * (1.0 + glow_intensity);
        final_color.a = original_color.a;
    }

    // Add outline
    if (outline > 0.0) {
        vec4 glow_color = outline_color;
        glow_color.a *= outline;
        final_color = mix(final_color, glow_color, glow_color.a);
    }

    COLOR = final_color;
}