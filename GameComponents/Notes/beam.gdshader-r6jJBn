shader_type spatial;

uniform vec3 wall_position;
uniform vec3 wall_size;

void fragment() {
    vec3 object_position = VERTEX;
    vec3 wall_min = wall_position - (wall_size * 0.5);
    vec3 wall_max = wall_position + (wall_size * 0.5);

    bool inside_wall =
        object_position.x > wall_min.x && object_position.x < wall_max.x &&
        object_position.y > wall_min.y && object_position.y < wall_max.y &&
        object_position.z > wall_min.z && object_position.z < wall_max.z;

    if (inside_wall) {
        discard;
    }

    ALBEDO = vec3(1.0, 1.0, 1.0); // Set the color of the visible part
}
