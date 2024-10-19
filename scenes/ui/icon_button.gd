class_name ShaderButton
extends Button

@export_group("Tint")
@export var tint_normal: Color = Color.WHITE
@export var tint_hover: Color = Color.GRAY
@export var tint_pressed: Color = Color.LIGHT_GRAY

@export_group("Icon")
@export var icon_size: Vector2 = Vector2(36, 36)
@export var icon_material: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	var icon_texture = PlaceholderTexture2D.new()
	icon_texture.size = icon_size
	icon = icon_texture
	size = icon_size
	material = icon_material


func _on_button_down() -> void:
	material.set_shader_parameter("tint", tint_pressed)


func _on_button_up() -> void:
	material.set_shader_parameter("tint", tint_normal)


func _on_mouse_entered() -> void:
	material.set_shader_parameter("tint", tint_hover)


func _on_mouse_exited() -> void:
	material.set_shader_parameter("tint", tint_normal)
