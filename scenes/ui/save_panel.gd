class_name SavePanel
extends PanelContainer

var _save_content: String = ""
var _object_size := Vector2i.ZERO
var _rle_code := ""

@onready var save_object_preview: TextureRect = %SaveObjectPreview
@onready var rle_code_label: Label = %RleCode
@onready var name_edit: LineEdit = %NameEdit
@onready var description_edit: LineEdit = %DescriptionEdit
@onready var cancel_save_button: Button = %CancelSaveButton
@onready var save_file_button: Button = %SaveFileButton
@onready var save_db_button: Button = %SaveDBButton


func _ready() -> void:
    cancel_save_button.pressed.connect(_clear)
    save_file_button.pressed.connect(_on_save.bind(false))
    save_db_button.pressed.connect(_on_save.bind(true))


func _clear() -> void:
    rle_code_label.text = ""
    name_edit.text = ""
    description_edit.text = ""


func _on_save(to_db := false) -> void:
    var rle_code_label_text = rle_code_label.text
    var x = 0
    var l_name = name_edit.text
    var description = description_edit.text
    if to_db:
        DB.insert_row(l_name, _rle_code, _object_size.x, _object_size.y, description)
    else:
        _save_content = "#N %s\n#C %s\n%s" % [l_name, description, rle_code_label_text]
        save_rle()


func save_rle() -> void:
    var save_dialog := Controller.get_file_dialog()
    save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    save_dialog.title = "Save .rle Rle Code File"
    save_dialog.add_filter("*.rle", "Rle Code File")
    save_dialog.current_file = name_edit.text.strip_edges()
    save_dialog.file_selected.connect(_save_rle_file, CONNECT_ONE_SHOT)

    Controller.show_file_dialog(save_dialog)


func _save_rle_file(file_path: String) -> void:
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    file.store_string(_save_content)
    file.close()

    _clear()


func update_rle_label(rle_code: String, x: int, y: int, rule: String) -> void:
    var rle_text = "x = %d, y = %d, rule = %s\n%s" % [x, y, rule, rle_code]
    rle_code_label.text = rle_text
    _object_size = Vector2i(x, y)
    _rle_code = rle_code


@warning_ignore("INTEGER_DIVISION")
func update_object_preview(rle_code: String, x: int, y: int) -> void:
    var grid_size := Vector2i.ZERO
    if x >= 16.0 / 9.0 * y:
        grid_size.x = ceili(float(x) / 16) * 16
        grid_size.y = grid_size.x / 16 * 9
    else:
        grid_size.y = ceili(float(y) / 9) * 9
        grid_size.x = grid_size.y * 16 / 9
    save_object_preview.material.set_shader_parameter("grid_size", grid_size)

    var pos := Vector2i(grid_size.x - x, grid_size.y - y) / 2

    var image := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_L8)
    var cells_code = CAHelper.rle_decode(rle_code, x, y)
    CAHelper.add_cells_code_at(image, cells_code, x, pos.x, pos.y)
    var render_texture = ImageTexture.create_from_image(image)

    save_object_preview.material.set_shader_parameter("binary_texture", render_texture)
