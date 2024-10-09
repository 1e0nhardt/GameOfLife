class_name SelectState
extends GolState

const ITEM_LABEL = preload("res://scenes/item_label.tscn")

var _mask_rect: Rect2i
var _selecting := false
var _option_labels := []
var _inited := false


func _ready() -> void:
    EventBus.item_clicked.connect(_on_rmb_options_item_clicked)


func enter() -> void:
    super.enter()
    if not _inited:
        _setup_rmb_options()


func exit() -> void:
    _mask_rect = Rect2i()
    _mask_rect.size = Vector2i.ONE
    gol.draw_rect_on_mask(_mask_rect)


func on_unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("change_mode"):
        transition_requested.emit(self, State.DRAW)
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        _selecting = false
        
    var click_at_rmb_menu := gol.handle_right_click_event(event)
    if click_at_rmb_menu:
        return
        
    if event is InputEventMouseButton:
        event = event as InputEventMouseButton

        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.is_pressed():
                _mask_rect.position = gol.get_pixel_coords_at_mouse()
                _mask_rect.size = Vector2i.ZERO
                _selecting = true
            elif event.is_released():
                _mask_rect.size = gol.get_pixel_coords_at_mouse() - _mask_rect.position + Vector2i.ONE
                _selecting = false

            gol.draw_rect_on_mask(_mask_rect)

    if event is InputEventMouseMotion and _selecting:
        _mask_rect.size = gol.get_pixel_coords_at_mouse() - _mask_rect.position + Vector2i.ONE
        gol.draw_rect_on_mask(_mask_rect)


func _setup_rmb_options() -> void:
    _inited = true
    add_item_label("Add At Mouse")
    add_item_label("Clear")
    add_item_label("Search")


func add_item_label(id: String) -> void:
    var item_label_instance = ITEM_LABEL.instantiate()
    gol.rmb_options_vbox.add_child(item_label_instance)
    item_label_instance.text = id
    _option_labels.append(item_label_instance)


func _on_rmb_options_item_clicked(item: ItemLabel) -> void:
    if item not in _option_labels:
        return

    match item.text:
        "Add At Mouse":
            gol.search_panel.show()
            gol.search_edit.grab_focus()
        "Search":
            gol.search_panel.show()
            var search_string := "rle: %d,%d,%s" % [_mask_rect.size.x, _mask_rect.size.y, gol.encode_selected_rect(_mask_rect)]
            gol.search_edit.text = search_string
            gol.search_edit.text_submitted.emit(search_string)
        "Clear":
            gol.clear_rect_on_renderer(_mask_rect)

    gol.rmb_options.hide()
