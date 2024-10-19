class_name SelectState
extends GolState

const ITEM_LABEL = preload("res://scenes/ui/item_label.tscn")

var _mask_rect: Rect2i
var _selecting := false
var _option_labels := []
var _inited := false


func _ready() -> void:
    Controller.item_clicked.connect(_on_rmb_options_item_clicked)


func enter() -> void:
    super.enter()
    if not _inited:
        _setup_rmb_options()


func exit() -> void:
    _mask_rect = Rect2i()
    _mask_rect.size = Vector2i.ONE
    gol.draw_rect_on_mask(_mask_rect)


func on_unhandled_input(event: InputEvent) -> void:
    if PopupManager.any_popup_showing():
        return
        
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
            else:
                _mask_rect.size = gol.get_pixel_coords_at_mouse() - _mask_rect.position + Vector2i.ONE
                _selecting = false

    if event is InputEventMouseMotion and _selecting:
        _mask_rect.size = gol.get_pixel_coords_at_mouse() - _mask_rect.position + Vector2i.ONE
        gol.draw_rect_on_mask(_mask_rect)


func _setup_rmb_options() -> void:
    _inited = true
    add_item_label("Add Object At Mouse")
    add_item_label("Clear")
    add_item_label("Search")
    add_item_label("Save Selection")


func add_item_label(id: String) -> void:
    var item_label_instance = ITEM_LABEL.instantiate()
    gol.rmb_options_vbox.add_child(item_label_instance)
    item_label_instance.text = id
    _option_labels.append(item_label_instance)


func _on_rmb_options_item_clicked(item: ItemLabel) -> void:
    if item not in _option_labels:
        return
    
    _selecting = false

    match item.text:
        "Add Object At Mouse":
            var search_panel_popup := Controller.get_search_panel_popup()
            Controller.show_search_panel_popup(search_panel_popup, Vector2(1080, 610))
        "Search":
            var search_panel_popup := Controller.get_search_panel_popup()
            var search_string := "rle: " + gol.encode_selected_rect(_mask_rect)
            search_panel_popup.save_rle_code(search_string)
            Controller.show_search_panel_popup(search_panel_popup, Vector2(1080, 610))
        "Clear":
            gol.clear_rect_on_renderer(_mask_rect)
        "Save Selection":
            var rle_code = gol.encode_selected_rect(_mask_rect)
            var x = _mask_rect.size.x
            var y = _mask_rect.size.y
            var save_panel_popup := Controller.get_save_panel_popup()
            save_panel_popup.save_rle_data(rle_code, x, y, gol.rule_label.text.split(":")[1].strip_edges())
            Controller.show_save_panel_popup(save_panel_popup, Vector2(768, 600))
            

    gol.rmb_options.hide()
