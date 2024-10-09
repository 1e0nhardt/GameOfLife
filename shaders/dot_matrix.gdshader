shader_type canvas_item;

uniform sampler2D lit_texture;
uniform sampler2D unlit_texture;
uniform sampler2D binary_texture: filter_nearest;
uniform sampler2D mask_texture: filter_nearest;

uniform vec2 grid_size = vec2(384, 216);


void fragment() {
    vec2 scaled_uv = UV * grid_size;
    ivec2 cell_index = ivec2(floor(scaled_uv));
    vec2 cell_uv = fract(scaled_uv);

    vec2 pixel_uv = vec2(
        float(cell_index.x) / float(grid_size.x - 1.0),
        float(cell_index.y) / float(grid_size.y - 1.0)
    );

    float binary_value = texture(binary_texture, pixel_uv).r;
    float mask_value = texture(mask_texture, pixel_uv).r;
    
    vec4 color = texture(unlit_texture, cell_uv);
    // vec4 color = vec4(1.0);
    if (binary_value > 0.5) {
        color = texture(lit_texture, cell_uv);
        // color = vec4(0.01, 0.8, 0.6, 1.0);
    }

    if (mask_value > 0.5) {
        color = mix(vec4(0.8, 0.5, 0.1, 0.5), color, 0.5);
    }

    // color = mix(vec4(0.0), color, step(cell_uv.y, 0.95) * step(cell_uv.x, 0.95));

    COLOR = color;
}
