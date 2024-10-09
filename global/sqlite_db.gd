extends Node

const DB_NAME := "res://assets/patterns"
const TABLE_NAME := "gol_patterns"
const TABLE_DICT := {
    "id": {"data_type":"int", "primary_key": true, "not_null": true},
    "name": {"data_type":"text", "not_null": true, "unique": true},
    "code": {"data_type":"text", "not_null": true},
    "x": {"data_type":"int", "not_null": true},
    "y": {"data_type":"int", "not_null": true},
    "cells": {"data_type":"int", "not_null": true},
    "description": {"data_type":"text"},
}
# const VERBOSITY_LEVEL : int = SQLite.VERBOSE
const VERBOSITY_LEVEL : int = SQLite.NORMAL

var db : SQLite = null

var query_result: Array = []:
    get():
        return db.query_result


func _init() -> void:
    db = SQLite.new()
    db.path = DB_NAME
    db.verbosity_level = VERBOSITY_LEVEL
    db.read_only = true

    db.open_db()
    # db.drop_table(TABLE_NAME)
    db.create_table(TABLE_NAME, TABLE_DICT)


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        db.close_db()


func insert_row(a_name: String, code: String, x: int, y: int, description: String) -> void:
    db.insert_row(TABLE_NAME, {
        "name": a_name,
        "code": code,
        "x": x,
        "y": y,
        "cells": code.count("O"),
        "description": description,
    })


func delete_row_by_id(id: int) -> void:
    db.delete_rows(TABLE_NAME, "id = %s" % id)


func delete_row_by_name(a_name: String) -> void:
    db.delete_rows(TABLE_NAME, "LOWER(name) = '%s'" % a_name)


func select_row_by_id(id: int) -> Array:
    return db.select_rows(TABLE_NAME, "id = %s" % id, ["*"])


func select_row_by_name(a_name: String) -> Array:
    return db.select_rows(TABLE_NAME, "LOWER(name) = '%s'" % a_name, ["*"])


func select_row_by_code(code: String) -> Array:
    return select_rows_by_condition("code = '%s'" % code)


func select_rows_by_condition(condition: String) -> Array:
    return db.select_rows(TABLE_NAME, condition, ["*"])


func select_rows_by_fuzzy_name(a_name: String) -> Array:
    return select_rows_by_condition("LOWER(name) LIKE '%%%s%%'" % a_name)


func select_rows_by_cells(cells: int) -> Array:
    return select_rows_by_condition("cells = %s" % cells)


func select_rows_by_size(x: int, y: int) -> Array:
    return select_rows_by_condition("x = %s AND y = %s" % [x, y])


func query(query_string: String) -> void:
    db.query(query_string)


func export_to_json(json_name: String) -> void:
    db.export_to_json(json_name)


func update_rows(condition: String, new_dict: Dictionary) -> void:
    db.update_rows(TABLE_NAME, condition, new_dict)


func update_code_by_id(id: int, new_code: String, x: int, y: int) -> void:
    if new_code.length() != x * y:
        print("The new code length is not equal to x * y! Won't update!")
        return
        
    db.update_rows(
        TABLE_NAME, "id = %s" % id, 
        {"code": new_code, "x": x, "y": y, "cells": new_code.count("O")}
    )


func update_code_by_name(a_name: String, new_code: String, x: int, y: int) -> void:
    if new_code.length() != x * y:
        print("The new code length is not equal to x * y! Won't update!")
        return
        
    db.update_rows(
        TABLE_NAME, "LOWER(name) = '%s'" % a_name, 
        {"code": new_code, "x": x, "y": y, "cells": new_code.count("O")}
    )


func update_description_by_id(id: int, new_description: String) -> void:
    db.update_rows(
        TABLE_NAME, "id = %s" % id, 
        {"description": new_description}
    )


func update_description_by_name(a_name: String, new_description: String) -> void:
    db.update_rows(
        TABLE_NAME, "LOWER(name) = '%s'" % a_name, 
        {"description": new_description}
    )


func update_name_by_id(id: int, new_name: String) -> void:
    db.update_rows(
        TABLE_NAME, "id = %s" % id, 
        {"name": new_name}
    )


func update_name_by_name(a_name: String, new_name: String) -> void:
    db.update_rows(
        TABLE_NAME, "LOWER(name) = '%s'" % a_name, 
        {"name": new_name}
    )