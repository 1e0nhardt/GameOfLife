class_name GameOfLife
extends Node2D

const ITEM_LABEL = preload("res://scenes/item_label.tscn")

@export var grid_size: Vector2i = Vector2i(384, 216)
@export var update_interval: float = 0.2

var _rd: RenderingDevice
var _pipeline: RID
var _input_texture: RID
var _output_texture: RID
var _survive_nums_buffer: RID
var _born_nums_buffer: RID
var _uniform_set: RID
var _default_texture_format: RDTextureFormat
var _default_texture_usage_bits = (
    RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
    RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT +
    RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
)

var _input_image: Image
var _output_image: Image
var _render_texture: ImageTexture
var _mask_image: Image
var _mask_image_texture: ImageTexture

var _anchor_pixel_coords := Vector2i.ZERO

var generation: int = 0:
    set(value):
        generation = value
        generation_number.text = "Generation: %d" % generation

var stopped := true:
    set(value):
        stopped = value
        if not stopped:
            _rd.texture_update(_input_texture, 0, _output_image.get_data())
            start_process_loop()

@onready var gol_state_machine: GolStateMachine = $GolStateMachine
@onready var update_interval_number: Label = %UpdateIntervalNumber
@onready var mode_label: Label = %ModeLabel
@onready var generation_number: Label = %GenerationNumber
@onready var renderer: Sprite2D = $Renderer
@onready var camera_2d: GameOfLifeCamera = $Camera2D
@onready var search_panel: CenterContainer = %SearchPanel
@onready var search_edit: LineEdit = %SearchEdit
@onready var rmb_options: PanelContainer = %RMBOptions
@onready var rmb_options_vbox: VBoxContainer = %RMBVBox
@onready var rule_edit: LineEdit = %RuleEdit
@onready var rule_label: Label = %RuleLabel


func _ready() -> void:
    # CAHelper.insert_rows_from_folder("res://game_of_life_patterns")
    EventBus.object_selected.connect(_on_object_selected)
    rule_edit.text_submitted.connect(_on_rule_changed)
    gol_state_machine.init(self)

    update_interval_label(update_interval)

    setup_images()
    link_output_texture_to_renderer()
    setup_compute_shader()
    start_process_loop()


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        cleanup_gpu()


func _process(delta: float) -> void:
    gol_state_machine.on_process(delta)


func _input(event: InputEvent) -> void:
    gol_state_machine.on_input(event)


func _unhandled_input(event: InputEvent) -> void:
    gol_state_machine.on_unhandled_input(event)


# 返回true表示左键点击在右键菜单上。
func handle_right_click_event(event: InputEvent) -> bool:
    var pos = %UI.get_local_mouse_position()
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        rmb_options.position = pos
        _anchor_pixel_coords = get_pixel_coords_at_mouse()
        rmb_options.show()

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if rmb_options.get_rect().has_point(pos):
            return true
        else:
            rmb_options.hide()

    return false


func handle_update_interval_event(event: InputEvent) -> void:
     if event is InputEventMouseButton:
        event = event as InputEventMouseButton

        if event.ctrl_pressed:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                update_interval += 0.025
            if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                update_interval -= 0.025
            update_interval = clamp(update_interval, 0.00, 2.0)
            update_interval_label(update_interval)


func update_interval_label(interval: float) -> void:
    update_interval = interval
    var text = "Update interval: %.2f" % interval
    update_interval_number.text = text


func update_model_label(text: String) -> void:
    mode_label.text =  "Mode: %s" % text


func get_pixel_coords_at_mouse() -> Vector2i:
    var mouse_pos_on_renderer := get_local_mouse_position() + Vector2(0, 420)
    var uv_coords := mouse_pos_on_renderer / 1920.0
    return Vector2i(floor(uv_coords.x * grid_size.x), floor(uv_coords.y * grid_size.y))


func draw_point_at_mouse_on_renderer(state: bool) -> void:
    var pixel_coords := get_pixel_coords_at_mouse()
    var color = Color.WHITE if state else Color.BLACK
    _output_image.set_pixelv(pixel_coords, color)
    _render_texture.update(_output_image)


func draw_object_on_renderer(obj_record: Dictionary) -> void:
    CAHelper.add_object_at(_output_image, obj_record["name"], _anchor_pixel_coords.x, _anchor_pixel_coords.y)
    _render_texture.update(_output_image)


func clear_rect_on_renderer(rect: Rect2i) -> void:
    if rect.size.x <= 0 and rect.size.y <= 0:
        return

    _output_image.fill_rect(rect, Color.BLACK)
    _render_texture.update(_output_image)


func draw_rect_on_mask(rect: Rect2i) -> void:
    if rect.size.x <= 0 and rect.size.y <= 0:
        return

    _mask_image.fill(Color.BLACK)

    if rect.size.x == 1 and rect.size.y == 1:
        _mask_image_texture.update(_mask_image)
        return

    _mask_image.fill_rect(rect, Color.WHITE)
    _mask_image_texture.update(_mask_image)


func encode_selected_rect(rect: Rect2i) -> String:
    var cells_code = ""
    for y in rect.size.y:
        for x in rect.size.x:
            var pixel_color = _output_image.get_pixel(rect.position.x + x, rect.position.y + y)
            if pixel_color.r > 0.5:
                cells_code += "O"
            else:
                cells_code += "."
    return CAHelper.rle_encode(cells_code, rect.size.x, rect.size.y)


#region Compute Shader
func create_noise_input_image(frequency: float = 0.1) -> void:
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.seed = randi()
    noise.frequency = frequency
    var noise_image: Image = noise.get_image(grid_size.x, grid_size.y)
    _input_image = noise_image


func setup_images() -> void:
    # create_noise_input_image()

    # 定制输入
    _input_image = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_L8)
    # CAHelper.add_object_at(_input_image, "Unix", 150, 150)

    _output_image = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_L8)
    _output_image.copy_from(_input_image)

    _mask_image = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_L8)


func link_output_texture_to_renderer() -> void:
    var mat: ShaderMaterial = renderer.material as ShaderMaterial
    _render_texture = ImageTexture.create_from_image(_output_image)
    _mask_image_texture = ImageTexture.create_from_image(_mask_image)
    mat.set_shader_parameter("grid_size", grid_size)
    mat.set_shader_parameter("binary_texture", _render_texture)
    mat.set_shader_parameter("mask_texture", _mask_image_texture)


func start_process_loop() -> void:
    while not stopped:
        update()
        await get_tree().create_timer(update_interval).timeout
        render()
        generation += 1


func load_shader(filepath: String) -> RID:
    var shader_file: RDShaderFile = load(filepath)
    # var shader_file: RDShaderFile = ResourceLoader.load(filepath, "", ResourceLoader.CACHE_MODE_IGNORE)
    var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
    return _rd.shader_create_from_spirv(shader_spirv)


#region change pipeline not work as expected
func create_shader_with_rule(rule: String) -> void:
    var shader_file_template = FileAccess.get_file_as_string("res://shaders/game_of_life.template")
    var shader_file = FileAccess.open("res://shaders/game_of_life_temp.glsl", FileAccess.WRITE)
    var born_condition = get_condition_string(rule.split("/")[0].substr(1))
    var survive_condition = get_condition_string(rule.split("/")[1].substr(1))
    shader_file.store_string(shader_file_template % [survive_condition, born_condition])


func get_condition_string(condition: String) -> String:
    if condition.length() == 1:
        return "alive_neighbors == %s" % condition
    else:
        var condition_string = ""
        for num in condition:
            condition_string += " || alive_neighbors == %s" % num
        condition_string = condition_string.substr(4)
        return condition_string


func change_rule(rule: String) -> void:
    create_shader_with_rule(rule)
    _rd.free_rid(_pipeline)
    _pipeline = _rd.compute_pipeline_create(load_shader("res://shaders/game_of_life_temp.glsl"))
#endregion


func create_texture_uniform(texture_rid: RID, binding: int) -> RDUniform:
    var texture_uniform := RDUniform.new()
    texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
    texture_uniform.binding = binding
    texture_uniform.add_id(texture_rid)
    return texture_uniform


func create_buffer_uniform(buffer_rid: RID, binding: int) -> RDUniform:
    var buffer_uniform := RDUniform.new()
    buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
    buffer_uniform.binding = binding
    buffer_uniform.add_id(buffer_rid)
    return buffer_uniform
    

func setup_compute_shader() -> void:
    _rd = RenderingServer.create_local_rendering_device()
    if _rd == null:
        OS.alert("""Couldn't create local RenderingDevice on GPU: %s\nNote: RenderingDevice is only available in the Forward+ and Mobile rendering methods, not Compatibility.""" % RenderingServer.get_video_adapter_name())
        return

    var shader_rid := load_shader("res://shaders/game_of_life_variant.glsl")
    _pipeline = _rd.compute_pipeline_create(shader_rid)

    _default_texture_format = RDTextureFormat.new()
    _default_texture_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
    _default_texture_format.width = grid_size.x
    _default_texture_format.height = grid_size.y
    _default_texture_format.usage_bits = _default_texture_usage_bits

    _input_texture = _rd.texture_create(_default_texture_format, RDTextureView.new(), [_input_image.get_data()])
    _output_texture = _rd.texture_create(_default_texture_format, RDTextureView.new(), [_output_image.get_data()])

    var input_texture_uniform = create_texture_uniform(_input_texture, 0)
    var output_texture_uniform = create_texture_uniform(_output_texture, 1)
    
    var survive_nums_bytes := PackedInt32Array([2, 2, 3, 0, 0, 0, 0, 0, 0]).to_byte_array()
    _survive_nums_buffer = _rd.storage_buffer_create(survive_nums_bytes.size(), survive_nums_bytes)
    var survive_nums_uniform = create_buffer_uniform(_survive_nums_buffer, 2)
    
    var born_nums_bytes := PackedInt32Array([1, 3, 0, 0, 0, 0, 0, 0, 0]).to_byte_array()
    _born_nums_buffer = _rd.storage_buffer_create(born_nums_bytes.size(), born_nums_bytes)
    var born_nums_uniform = create_buffer_uniform(_born_nums_buffer, 3)
    
    _uniform_set = _rd.uniform_set_create([input_texture_uniform, output_texture_uniform, survive_nums_uniform, born_nums_uniform], shader_rid, 0)


func update() -> void:
    if _rd == null:
        return

    var compute_list := _rd.compute_list_begin()
    _rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
    _rd.compute_list_bind_uniform_set(compute_list, _uniform_set, 0)
    var dispach_size = Vector2i(ceil(grid_size.x / 32.0), ceil(grid_size.y / 32.0))
    _rd.compute_list_dispatch(compute_list, dispach_size.x, dispach_size.y, 1)
    _rd.compute_list_end()
    _rd.submit()


func render() -> void:
    if _rd == null:
        return

    _rd.sync()
    var output_bytes = _rd.texture_get_data(_output_texture, 0)
    _rd.texture_update(_input_texture, 0, output_bytes)
    _output_image.set_data(grid_size.x, grid_size.y, false, Image.FORMAT_L8, output_bytes)
    _render_texture.update(_output_image)


func cleanup_gpu() -> void:
    if _rd == null:
        return

    _rd.free_rid(_input_texture)
    _rd.free_rid(_output_texture)
    _rd.free_rid(_uniform_set)
    _rd.free_rid(_pipeline)
    _rd.free()
    _rd = null
#endregion


func _on_object_selected(obj_record: Dictionary) -> void:
    draw_object_on_renderer(obj_record)


func _on_rule_changed(new_rule: String) -> void:
    # change_rule(new_rule)
    var born_condition = new_rule.split("/")[0].substr(1)
    var survive_condition = new_rule.split("/")[1].substr(1)
 
    update_buffer_data(survive_condition, _survive_nums_buffer)
    update_buffer_data(born_condition, _born_nums_buffer)
    
    rule_label.text = "Rule: %s" % new_rule
    rule_edit.hide()


func update_buffer_data(condition: String, buffer_rid: RID) -> void:
    var nums_array = PackedInt32Array([condition.length()])
    for num in condition:
        nums_array.append(num.to_int())
    var bytes = nums_array.to_byte_array()
    _rd.buffer_update(buffer_rid, 0, bytes.size(), bytes)
    