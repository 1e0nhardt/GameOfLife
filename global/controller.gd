extends Node

@warning_ignore("UNUSED_SIGNAL")
signal item_clicked(item_label: ItemLabel)
@warning_ignore("UNUSED_SIGNAL")
signal object_selected(obj_record: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal settings_applied(settings: Dictionary)

const INFO_POPUP_SCENE = preload("res://scenes/ui/info_popup.tscn")
const SAVE_PANEL_POPUP_SCENE = preload("res://scenes/ui/save_panel_popup.tscn")
const SEARCH_PANEL_POPUP_SCENE = preload("res://scenes/ui/search_panel_popup.tscn")
const SETTINGS_POPUP_SCENE = preload("res://scenes/ui/settings_popup.tscn")

var _info_popup: InfoPopup = null
var _save_panel_popup: SavePanelPopup = null
var _search_panel_popup: SearchPanelPopup = null
var _settings_popup: SettingsPopup = null
var _file_dialog: FileDialog = null
var _file_dialog_callable: Callable


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if is_instance_valid(_file_dialog):
            _file_dialog.queue_free()
        if is_instance_valid(_info_popup):
            _info_popup.queue_free()
        if is_instance_valid(_save_panel_popup):
            _save_panel_popup.queue_free()


func get_file_dialog() -> FileDialog:
    if not _file_dialog:
        _file_dialog = FileDialog.new()
        _file_dialog.use_native_dialog = true
        _file_dialog.access = FileDialog.ACCESS_FILESYSTEM

        # _finize_file_dialog.unbind(1) 和另一个 _finize_file_dialog.unbind(1) 的比较被引擎判定为不相等。
        # 因此，这里使用变量储存 _file_dialog_callable，以确保后续清理连接时能正确保留。
        _file_dialog_callable = _finize_file_dialog.unbind(1)
        _file_dialog.file_selected.connect(_file_dialog_callable)
        _file_dialog.canceled.connect(_finize_file_dialog)
        _file_dialog.canceled.connect(_clear_file_dialog_connections)

    _file_dialog.clear_filters()

    return _file_dialog


func show_file_dialog(dialog: FileDialog) -> void:
    get_tree().root.add_child(dialog)
    dialog.popup_centered()


func _clear_file_dialog_connections() -> void:
    var connections = _file_dialog.file_selected.get_connections()
    for connection in connections:
        if connection["callable"] != _file_dialog_callable:
            _file_dialog.file_selected.disconnect(connection["callable"])


func _finize_file_dialog() -> void:
    _file_dialog.get_parent().remove_child(_file_dialog)


func get_info_popup() -> InfoPopup:
    if not _info_popup:
        _info_popup = INFO_POPUP_SCENE.instantiate()

    _info_popup.clear()
    return _info_popup


func show_info_popup(popup: InfoPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)


func get_save_panel_popup() -> SavePanelPopup:
    if not _save_panel_popup:
        _save_panel_popup = SAVE_PANEL_POPUP_SCENE.instantiate()
        
    _save_panel_popup.custom_minimum_size = Vector2.ZERO
    _save_panel_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
    _save_panel_popup.size = Vector2.ZERO
    return _save_panel_popup


func show_save_panel_popup(popup: SavePanelPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)
    popup.foucus_name_edit()


func get_search_panel_popup() -> SearchPanelPopup:
    if not _search_panel_popup:
        _search_panel_popup = SEARCH_PANEL_POPUP_SCENE.instantiate()
        
    _search_panel_popup.custom_minimum_size = Vector2.ZERO
    _search_panel_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
    _search_panel_popup.size = Vector2.ZERO
    return _search_panel_popup


func show_search_panel_popup(popup: SearchPanelPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)
    popup.foucus_search_edit()


func get_settings_popup() -> SettingsPopup:
    if not _settings_popup:
        _settings_popup = SETTINGS_POPUP_SCENE.instantiate()
        
    _settings_popup.custom_minimum_size = Vector2.ZERO
    _settings_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
    _settings_popup.size = Vector2.ZERO
    return _settings_popup


func show_settings_popup(popup: SettingsPopup, popup_size: Vector2) -> void:
    popup.size = popup_size
    popup.popup_anchored(Vector2(0.5, 0.5), PopupManager.Direction.OMNI, true)