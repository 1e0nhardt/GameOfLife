class_name CAHelper
extends Object

static var _illegal_cells_code_regex := RegEx.create_from_string("[^.O\n]")
static var _illegal_rle_code_regex := RegEx.create_from_string("[^ob\\$!,1234567890]")


static func add_object_at(img: Image, obj_name: String, pos_x: int, pos_y: int) -> void:
    if img == null:
        return

    var query_result = DB.select_row_by_name(obj_name.to_lower())[0]
    if not query_result:
        Logger.info("Object '%s' is not recorded!" % obj_name)
        return

    var cells_code = CAHelper.rle_decode(query_result["rle_code"], query_result["x"], query_result["y"]).replace("\n", "")

    for i in cells_code.length():
        var color: Color = Color.WHITE if cells_code[i] == "O" else Color.BLACK
        img.set_pixel(
            pos_x + i % query_result["x"],
            pos_y + floor(i / float(query_result["x"])),
            color
        )


static func add_cells_code_at(img: Image, cells_code: String, x: int, pos_x: int, pos_y: int) -> void:
    if img == null:
        return

    cells_code = cells_code.replace("\n", "")

    for i in cells_code.length():
        var color: Color = Color.WHITE if cells_code[i] == "O" else Color.BLACK
        img.set_pixel(
            pos_x + i % x,
            pos_y + floor(i / float(x)),
            color
        )

# 注意点:
# 0. 行尾的b可以省略，也可以留下。两种都支持
# 1. 如果表示一行的字符串中o,b的总数比行宽小，则剩余部分视为用b填充。($前一定是o)
# 2. 宽7的RLE中出现 2bo2$，相当于2bo4b$7b$。行尾空白和空白行合并。
# PS: cells_code 有些会省略行尾的"."，有些不会。不同行，用换行符分割。
static func rle_decode(rle_code: String, x: int, y: int) -> String:
    if _illegal_rle_code_regex.search(rle_code):
        Logger.info("Invalid RLE code: " + rle_code)
        return ""

    if not rle_code.ends_with("!"):
        rle_code += "!"

    var token := ""
    var cells_code := ""
    var curr_count := 0
    for ch in rle_code:
        if ch.is_valid_int():
            token += ch
        elif ch == "!":
            if curr_count != 0: # 兼容纯空区域，如 11$!
                cells_code += ".".repeat(x - curr_count) + "\n"
            curr_count = x
            break
        else:
            if ch == "b":
                var n = 1 if token == "" else int(token)
                cells_code += ".".repeat(n)
                curr_count += n
            elif ch == "o":
                var n = 1 if token == "" else int(token)
                cells_code += "O".repeat(n)
                curr_count += n
            elif ch == "$":
                var n = x - curr_count
                cells_code += ".".repeat(n) + "\n"
                if token != "":
                    for i in token.to_int() - 1:
                        cells_code += ".".repeat(x) + "\n"
                curr_count = 0

            token = ""

    if cells_code.length() != (x + 1) * y: # 每行多一个"\n"
        Logger.info("Rle code length error: %s, %d != (%d+1) * %d" % [rle_code, cells_code.length(), x, y])
        return ""

    return cells_code


static func _create_token(ch: String, count: int) -> String:
    if count == 1:
        return ch
    else:
        return str(count) + ch


static func rle_encode(cells_code: String, x: int, y: int) -> String:
    cells_code = cells_code.replace("\n", "")

    var rle_code := ""
    var curr_count := 0
    var current_char := cells_code[0]
    for i in y:
        for j in x:
            if cells_code[i * x + j] == current_char:
                curr_count += 1
            else:
                rle_code += _create_token(current_char, curr_count)
                curr_count = 1
                current_char = cells_code[i * x + j]

        if current_char == "O":
            rle_code += _create_token(current_char, curr_count)

        if rle_code.length() > 0 and rle_code[-1] == "$":
            if rle_code.length() > 1:
                if not rle_code[-2].is_valid_int(): # 中间的空行
                    rle_code = rle_code.left(-1) + "2"
                else:
                    var k = 2
                    var count_str := ""
                    while k <= rle_code.length() and rle_code[-k].is_valid_int():
                        count_str = rle_code[-k] + count_str
                        k += 1
                    rle_code = rle_code.left(-k+1) + str(count_str.to_int() + 1)
            elif rle_code.length() == 1: # 处理起始空两行或以上的情况
                rle_code = "2"

        rle_code += "$"
        curr_count = 0
        if i == y - 1:
            if rle_code.length() > 1 and rle_code[-1] == "$" and not rle_code[-2].is_valid_int():
                rle_code = rle_code.left(-1)
            rle_code += "!"
        else:
            current_char = cells_code[(i + 1)* x]

    return rle_code.replace(".", "b").replace("O", "o")


static func save_cells_code_to_db_from_file(filepath: String) -> void:
    if filepath.get_file() in ["10x10maxdensity.rle", "13x13maxdensity.rle", "15gsynthp46.rle", "empty.rle"]:
        return

    var is_rle := filepath.ends_with(".rle")
    var content_lines := FileAccess.get_file_as_string(filepath).strip_edges().split("\n")
    var code_lines := []
    var cells_code := ""
    var comments := []
    var name := ""
    var description := ""
    var x := 0
    var y := 0
    var in_code := false # 有些文件的注释和编码中间非要空几行... -> fireshiprake.rle

    for line in content_lines:
        line = line.strip_edges()

        if line == "" and not in_code:
            continue

        if line.begins_with("!") or line.begins_with("#"):
            comments.append(line.substr(1))
        else:
            in_code = true
            if not is_rle:
                # plusar.cells 里面全是死细胞的行为空。所以，这里加上一个'.'，方便后续补齐。
                if line == "":
                    line = "."
            code_lines.append(line)
            x = max(x, line.length())
            y += 1

    for i in comments.size():
        if i == 0:
            if comments[i].begins_with("Name:"):
                name = comments[i].substr(5).strip_edges()
            elif comments[i].begins_with("N"):
                name = comments[i].substr(1).strip_edges()
            else:
                name = comments[i].strip_edges()
            name = name.replace("'", " ")
            name = name.replace(".cells", "").replace(".rle", "")
        else:
            if comments[i].begins_with("C "):
                description = comments[i].substr(2).strip_edges() + "\n"
            else:
                description += comments[i] + "\n"

    if DB.select_row_by_name(name.to_lower()):
        # Logger.info("Duplicated name at: " + filepath)
        return

    if is_rle:
        # x = n, y = m, rule=S23/B3
        x = code_lines[0].split(",")[0].split("=")[1].to_int()
        y = code_lines[0].split(",")[1].split("=")[1].to_int()

        # 限制一下模式大小。26cellquadraticgrowth=16193x15089
        if x > 1000 or y > 1000:
            Logger.warn("Skip pattern which is too large: %s" % filepath)
            return

        code_lines.pop_front()
        cells_code = rle_decode("".join(code_lines), x, y)
        if cells_code == "":
            Logger.warn("Invalid rle code at: " + filepath)
            return
    else:
        for line in code_lines:
            if line.length() < x:
                cells_code += line + ".".repeat(x - line.length())
            else:
                cells_code += line

            cells_code += "\n"

    if _illegal_cells_code_regex.search(cells_code):
        Logger.info("Invalid cells code: " + cells_code)
        return

    DB.insert_row(name, CAHelper.rle_encode(cells_code, x, y), x, y , description)


static func insert_rows_from_folder(folderpath: String) -> void:
    var dir = DirAccess.open(folderpath)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir():
                # Logger.debug("Processing: " + file_name)
                save_cells_code_to_db_from_file(folderpath + "/" + file_name)
            file_name = dir.get_next()
    else:
        Logger.info("An error occurred when trying to access the path.")

    Logger.info("Done!")
