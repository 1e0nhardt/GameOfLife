shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);


float sdRoundedX( in vec2 p, in float w, in float r )
{
    p = abs(p);
    return length(p-min(p.x+p.y,w)*0.5) - r;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = sdRoundedX(uv, 1.0, 0.15);
    float rounded_x = smoothstep(0.15, 0.0, d);
	COLOR = tint * rounded_x;
}
