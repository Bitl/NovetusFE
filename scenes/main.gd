extends Control

var LinuxWinePrefix
var LinuxWinePath
var LinuxTerminal = "sh"
#var WorkingDirectory
var f = File.new()
var dir = Directory.new()
var CurrentMenu
var CTheme
var Drive = "Z:"

var Version = "2009E"
var PlayerName = "Noob"
var Map = ""
onready var WorkingDirectory = OS.get_executable_path().get_base_dir()

func _ready():
	OS.min_window_size = Vector2(700, 600)
	OS.max_window_size = Vector2(1920, 1080)
	#WorkingDirectory = OS.get_executable_path().get_base_dir()
	if !f.file_exists(WorkingDirectory + "/bin/Novetus.exe"):
		WorkingDirectory = OS.get_executable_path().get_base_dir() + "/.."
		print(WorkingDirectory)

	if f.file_exists(WorkingDirectory + "/bin/Novetus.exe"):
		$Main.visible = true
		print("visible")
	else:
		$Main.visible = false
		$Background/FirstTime.visible = false
		$Background/Info.visible = false
	if !f.file_exists(WorkingDirectory + "/bin/Novetus.exe"): return
	match OS.get_name():
		"X11":
			print("yea")
			Drive = "Z:"
			f.open(WorkingDirectory + "/Start.sh", File.WRITE)
			f.store_string('#!/bin/bash\nif [ -z "$4" ]; then WINEPREFIX=$1 $2 $3; else WINEPREFIX=$1 $2 $3 "$4"; fi')
			f.close()
		"Windows":
			Drive = "C:"
			$Main/Settings/ItemList.remove_item(0)
		_:
			$Background/Control2/RichTextLabel.text = "Your operating system is not supported.\nLinux and Windows only."
			$Main.visible = false
	if !dir.dir_exists(WorkingDirectory + "/NovetusFE"): dir.make_dir(WorkingDirectory + "/NovetusFE")
	if !dir.dir_exists(WorkingDirectory + "/NovetusFE/themes"): dir.make_dir(WorkingDirectory + "/NovetusFE/themes")
	loadconfig("/NovetusFE/nfeconfig.ini")
	for i in customconfig("/config/config.ini"):
		if "SelectedClient=" in i:
			Version = i.replace("SelectedClient=","")
		if "PlayerName=" in i:
			PlayerName = i.replace("PlayerName=","")
	for i in list_files_in_directory(WorkingDirectory + "/clients/"):
		$Main/VersionsWindow/Versions/ItemList.add_item(i, load("res://textures/studio.png"))
	$Main/VersionsWindow/Versions/ItemList.sort_items_by_text()
	$Background/Info.text = $Background/Info.text.replace("%PLAYER%",PlayerName)
	$Background/Info.text = $Background/Info.text.replace("%CLIENT%",Version)
	$Background/Info.text = $Background/Info.text.replace("%MAP%",Map)
	$Main/Menu.visible = false

func customconfig(configfile):
	var config = File.new()
	config.open(WorkingDirectory + configfile, File.READ)
	var content = config.get_as_text()
	content = content.split("\n")
	config.close()
	return content

func loadconfig(arg):
	var config = ConfigFile.new()
	var err = config.load(WorkingDirectory + arg)
	if err != OK:
		return
	match arg:
		"/NovetusFE/nfeconfig.ini":
			for i in config.get_sections():
				LinuxWinePrefix = config.get_value(i, "wineprefix")
				LinuxWinePath = config.get_value(i, "wine_exec_path")
				LinuxTerminal = config.get_value(i, "terminal")
			$"Main/Settings/Linux Settings/Panel/WPBox".text = LinuxWinePrefix
			$"Main/Settings/Linux Settings/Panel/WPBox2".text = LinuxWinePath
			$"Main/Settings/Linux Settings/Panel/CheckBox".pressed = LinuxTerminal

func main_item_activated(index):
	match $Main/Menu/ItemList.get_item_text(index):
		"Settings":
			menu("Settings")
			$Main/Settings/ItemList.grab_focus()
		"Studio":
			menu("Studio")
			$Main/Studio/ItemList.grab_focus()
		"Multiplayer":
			menu("Multiplayer")
			$Main/Multiplayer/ItemList.grab_focus()
		"Versions":
			$Main/VersionsWindow.popup()
			$Main/VersionsWindow/Versions/ItemList.grab_focus()

func settings_item_activated(index):
	match $Main/Settings/ItemList.get_item_text(index):
		"Back":
			menu("")
			$Main/Menu/ItemList.grab_focus()
		"Linux Settings":
			$"Main/Settings/Linux Settings".visible = true
		"General Settings":
			$"Main/Settings/General Settings".visible = true
		"Launch Novetus":
			$Overlay.visible = true
			yield(get_tree().create_timer(1),"timeout")
			launch("/bin/Novetus.exe")
			$Overlay.visible = false
			
			#$Main/Settings/ItemList.grab_focus()
			
func launch(program,arg=""):
	match OS.get_name():
		"Windows":
			if arg == "":
				#OS.shell_open(WorkingDirectory + program)
				OS.execute(WorkingDirectory + program,[])
			else:
				OS.execute(WorkingDirectory + program,[arg])
		"X11":
			if LinuxWinePrefix == "":
				if LinuxWinePath !="":
					OS.execute(LinuxWinePath,[WorkingDirectory + program])
				else:
					OS.shell_open(WorkingDirectory + program)
			else:
				if arg == "":
					OS.execute("sh",[WorkingDirectory + "/Start.sh", LinuxWinePrefix, LinuxWinePath, WorkingDirectory + program])
				else:
					OS.execute("sh",[WorkingDirectory + "/Start.sh", LinuxWinePrefix, LinuxWinePath, WorkingDirectory + program, arg])
func menu(menu, parent=$Main):
	for i in $Main.get_children():
		if i is Control:
			i.visible = false
	if menu == "": 
		$Main.visible = true
		$Main/Menu.visible = true
		return
	CurrentMenu = menu
	parent.get_node(menu).visible = !parent.get_node(menu).visible


func Back_pressed():
	match CurrentMenu:
		"Settings":
			$"Main/Settings/Linux Settings".visible = false
			$"Main/Settings/General Settings".visible = false


func _on_Save_pressed():
	var config = ConfigFile.new()
	config.set_value("Linux Settings", "wineprefix", $"Main/Settings/Linux Settings/Panel/WPBox".text)
	config.set_value("Linux Settings", "wine_exec_path", $"Main/Settings/Linux Settings/Panel/WPBox2".text)
	config.set_value("Linux Settings", "terminal", $"Main/Settings/Linux Settings/Panel/CheckBox".pressed)
	config.save(WorkingDirectory + "/NovetusFE/nfeconfig.ini")
	if CTheme != null: get_tree().change_scene_to(CTheme)


func _on_ThemeButton_pressed():
	pass # Replace with function body.


func _on_MenuButton_about_to_show():
	$"Main/Settings/General Settings/Panel/OptionButton".clear()
	$"Main/Settings/General Settings/Panel/OptionButton".add_item("Default")
	for i in list_files_in_directory(WorkingDirectory + "/NovetusFE/themes"):
		$"Main/Settings/General Settings/Panel/OptionButton".add_item(i)
	pass

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

func _on_OptionButton_item_selected(index):
	CTheme = load(WorkingDirectory + "/NovetusFE/themes/" + $"Main/Settings/General Settings/Panel/OptionButton".get_item_text(index))


func versionslist_activated(index):
	match $Main/VersionsWindow/Versions/ItemList.get_item_text(index):
		"Back":
			menu("")
			$Main/Menu/ItemList.grab_focus()
		_:
			Version = $Main/VersionsWindow/Versions/ItemList.get_item_text(index)
			$Main/VersionsWindow.visible = false
	$Background/Info.text = "Hello, %PLAYER%! Client Selected: %CLIENT%, Map Selected: %MAP%"
	$Background/Info.text = $Background/Info.text.replace("%PLAYER%",PlayerName)
	$Background/Info.text = $Background/Info.text.replace("%CLIENT%",Version)
	$Background/Info.text = $Background/Info.text.replace("%MAP%",$Main/Maps.current_file)

func studio_item_activated(index):
	match $Main/Studio/ItemList.get_item_text(index):
		"Back":
			menu("")
			$Main/Studio/ItemList.grab_focus()
		"Launch without map":
			launch("/clients/"+ Version + "/RobloxApp_studio.exe")
		"Launch with map":
			$Overlay.visible = true
			yield(get_tree().create_timer(1),"timeout")
			launch("/clients/"+ Version + "/RobloxApp_studio.exe", Drive + Map)
			$Overlay.visible = false
		"Play Solo":
			$Overlay.visible = true
			yield(get_tree().create_timer(1),"timeout")
			launch("/clients/"+ Version + "/RobloxApp_solo.exe", Drive + Map)
			$Overlay.visible = false
			
func _input(event):
	if Input.is_action_just_pressed("versions"):
		$Main/VersionsWindow.popup()
	if Input.is_action_just_pressed("map"):
		$Main/Maps.current_dir = WorkingDirectory + "/maps"
		$Main/Maps.popup()
	if Input.is_action_just_pressed("charcus"):
		$Main/CharCus.popup()


func _on_Maps_confirmed():
	print($Main/Maps.current_file)
	Map = str($Main/Maps.current_dir.replace(WorkingDirectory,"") + "/" + $Main/Maps.current_file)
	#Map = "../.." + Map
	#var counter = 0
	#for i in Map:
	#	if i == "/":
	#		Map[counter] = "//"
	#	counter += 1
	Map = Map.replacen("/","//")
	Map = WorkingDirectory.replacen("/","//") + Map
	$Background/Info.text = "Hello, %PLAYER%! Client Selected: %CLIENT%, Map Selected: %MAP%"
	$Background/Info.text = $Background/Info.text.replace("%PLAYER%",PlayerName)
	$Background/Info.text = $Background/Info.text.replace("%CLIENT%",Version)
	$Background/Info.text = $Background/Info.text.replace("%MAP%",$Main/Maps.current_file)
	print(Map)


func DirectConnect_Join_pressed():
	var ip = $Main/DirectConnectWindow/LineEdit.text.split(":")[0].to_ascii().get_string_from_ascii()
	var port = $Main/DirectConnectWindow/LineEdit.text.split(":")[1].to_ascii().get_string_from_ascii()
	var uri = Marshalls.utf8_to_base64(ip) + "|" + Marshalls.utf8_to_base64(port) + "|" + Marshalls.utf8_to_base64(Version)
	uri = Marshalls.utf8_to_base64(uri)
	launch("/bin/NovetusURI.exe novetus://" + uri)


func _on_DirectConnect_pressed():
	$Main/DirectConnectWindow.popup()

func multiplayert_item_activated(index):
	match $Main/Multiplayer/ItemList.get_item_text(index):
		"Join":
			$Main/DirectConnectWindow.popup()
		"Back":
			menu("")

func DirectConnect_Close_pressed():
	$Main/DirectConnectWindow.visible = false


func Firsttime_Button_pressed():
	$Main/Menu.visible = true
