class_name SearchPanel
extends PanelContainer

const ITEM_LABEL = preload("res://scenes/ui/item_label.tscn")

var _item_labels := []
var _selected_item: ItemLabel

@onready var search_edit: LineEdit = %SearchEdit
@onready var search_button: Button = %SearchButton
@onready var search_result_vbox: VBoxContainer = %SearchResultVBox
@onready var preview: TextureRect = %Preview
@onready var description: Label = %Description
@onready var cancel_button: Button = %CancelButton
@onready var ok_button: Button = %OkButton
@onready var delete_button: Button = %DeleteButton


func _ready() -> void:
    Controller.item_clicked.connect(_on_item_clicked)
    search_edit.text_submitted.connect(_on_search_edit_text_submitted)
    search_button.pressed.connect(_on_search_button_pressed)
    ok_button.pressed.connect(
        func():
            if _selected_item:
                Controller.object_selected.emit(_selected_item.get_meta("record"))
    )
    delete_button.pressed.connect(
        func():
            if _selected_item:
                DB.delete_row_by_id(_selected_item.get_meta("record")["id"])
            clear_renderer_and_label()
            _on_search_edit_text_submitted(search_edit.text)
            delete_button.hide()
    )

    var empty_image = Image.create(16, 9, false, Image.FORMAT_L8)
    var mask_texture = ImageTexture.create_from_image(empty_image)
    preview.material.set_shader_parameter("mask_texture", mask_texture)


func _gui_input(event: InputEvent) -> void:
    # 阻止滚轮事件
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            accept_event()


@warning_ignore("INTEGER_DIVISION")
func update_renderer(obj_name: String, x: int, y: int) -> void:
    var grid_size := Vector2i.ZERO
    if x >= 16.0 / 9.0 * y:
        grid_size.x = ceili(float(x) / 16) * 16
        grid_size.y = grid_size.x / 16 * 9
    else:
        grid_size.y = ceili(float(y) / 9) * 9
        grid_size.x = grid_size.y * 16 / 9
    preview.material.set_shader_parameter("grid_size", grid_size)

    var pos := Vector2i(grid_size.x - x, grid_size.y - y) / 2

    var image := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_L8)
    CAHelper.add_object_at(image, obj_name, pos.x, pos.y)
    var render_texture = ImageTexture.create_from_image(image)

    preview.material.set_shader_parameter("binary_texture", render_texture)


func add_item_label(record: Dictionary) -> void:
    var item_label_instance = ITEM_LABEL.instantiate()
    search_result_vbox.add_child(item_label_instance)
    item_label_instance.text = record["name"]
    _item_labels.append(item_label_instance)
    item_label_instance.set_meta("record", record)


func clear_item_labels() -> void:
    _item_labels.clear()
    for child in search_result_vbox.get_children():
        child.queue_free()


func _on_item_clicked(item: ItemLabel) -> void:
    if item not in _item_labels:
        return

    item.selected = true
    _selected_item = item

    for item_label in _item_labels:
        if item_label != item:
            item_label.selected = false

    var record = item.get_meta("record")
    update_renderer(record["name"], record["x"], record["y"])
    description.text = record["description"] + "\nCells: %s\n x=%s, y=%s" % [record["cells"], record["x"], record["y"]]
    delete_button.show()


func clear_renderer_and_label() -> void:
    preview.material.set_shader_parameter("grid_size", Vector2i(16, 9))
    var image := Image.create(16, 9, false, Image.FORMAT_L8)
    var render_texture = ImageTexture.create_from_image(image)
    preview.material.set_shader_parameter("binary_texture", render_texture)    
    description.text = "Some description."


func _on_search_edit_text_submitted(text: String) -> void:
    clear_item_labels()
    var records := []

    if ":" in text:
        var args = text.split(":")
        if args.size() == 2:
            if args[0] == "id":
                records = DB.select_row_by_id(args[1].to_int())

            elif args[0] == "cells":
                if not args[1].is_valid_int():
                    Logger.warn("Invalid search query! Valid format -> cells: x, where x is an integer.")
                records = DB.select_rows_by_cells(args[1])

            elif args[0] == "size":
                var size_numbers: Array = args[1].split(",")

                if size_numbers.size() != 2:
                    Logger.warn("Invalid search query! Valid format -> size: x, y, where x and y are integers.")
                    return

                size_numbers = size_numbers.map(func(x): return x.strip_edges())

                if not (size_numbers[0].is_valid_int() and size_numbers[1].is_valid_int()):
                    Logger.warn("Invalid search query! Valid format -> size: x, y, where x and y are integers.")
                    return

                records = DB.select_rows_by_size(
                    size_numbers[0].to_int(),
                    size_numbers[1].to_int()
                )

            elif args[0] == "rle":
                records = DB.select_row_by_rle_code(args[1].strip_edges())
        else:
            Logger.warn("Invalid search query! Valid format -> name or id: x or cells: x or size: x, y.")
            return
    else:
        records = DB.select_rows_by_fuzzy_name(text)

    for record in records:
        add_item_label(record)


func _on_search_button_pressed() -> void:
    _on_search_edit_text_submitted(search_edit.text)
