#[compute]
#version 460

layout(local_size_x = 32, local_size_y = 32) in;

layout(set = 0, binding = 0, r8) restrict uniform readonly image2D u_input_texture;
layout(set = 0, binding = 1, r8) restrict uniform writeonly image2D u_output_texture;

bool is_cell_alive(int x, int y) {
    return imageLoad(u_input_texture, ivec2(x, y)).r > 0.5;
}

int get_alive_neighbors(ivec2 coords) {
    int alive_neighbors = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            if (x == 0 && y == 0) {
                continue;
            }
            
            int nx = coords.x + x;
            int ny = coords.y + y;
            
            if (nx >= 0 && nx < imageSize(u_input_texture).x && ny >= 0 && ny < imageSize(u_input_texture).y)
                alive_neighbors += int(is_cell_alive(nx, ny));
        }
    }
    return alive_neighbors;
}

void main() {
    ivec2 cell_index = ivec2(gl_GlobalInvocationID.xy);
    
    bool is_alive = is_cell_alive(cell_index.x, cell_index.y);
    int alive_neighbors = get_alive_neighbors(cell_index);
    
    bool next_state = is_alive;
    if (is_alive && !(alive_neighbors == 3)) {
        next_state = false;
    } else if (!is_alive && (alive_neighbors == 3)) {
        next_state = true;
    }
    
    imageStore(u_output_texture, cell_index, next_state ? vec4(1.0) : vec4(0.0));
}

