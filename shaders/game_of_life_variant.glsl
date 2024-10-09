#[compute]
#version 460

layout(local_size_x = 32, local_size_y = 32) in;

layout(set = 0, binding = 0, r8) restrict uniform readonly image2D u_input_texture;
layout(set = 0, binding = 1, r8) restrict uniform writeonly image2D u_output_texture;
layout(set = 0, binding = 2, std430) restrict buffer SurviveNums{
    uint data[];
} u_survive_nums;
layout(set = 0, binding = 3, std430) restrict buffer BornNums{
    uint data[];
} u_born_nums;

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

bool should_survive(int an) {
    for (int i = 1; i < u_survive_nums.data[0] + 1; i++) {
        if (an == u_survive_nums.data[i])
            return true;
    }
    return false;
}

bool should_born(int an) {
    for (int i = 1; i < u_born_nums.data[0] + 1; i++) {
        if (an == u_born_nums.data[i])
            return true;
    }
    return false;
}

void main() {
    ivec2 cell_index = ivec2(gl_GlobalInvocationID.xy);
    
    bool is_alive = is_cell_alive(cell_index.x, cell_index.y);
    int alive_neighbors = get_alive_neighbors(cell_index);
    
    bool next_state = is_alive;
    // B3/S23
    if (is_alive && !should_survive(alive_neighbors)) {
        next_state = false;
    } else if (!is_alive && should_born(alive_neighbors)) {
        next_state = true;
    }
    
    imageStore(u_output_texture, cell_index, next_state ? vec4(1.0) : vec4(0.0));
}

