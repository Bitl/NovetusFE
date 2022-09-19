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
var NewServerTexture = load("res://textures/charcustom.png")
var NewServerTexturePath
var NewServerIcons = []
var ServerIndex
var Servers 
var serverconfig = ConfigFile.new()
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
	$Main/Serverlist/Versions.text = Version
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
			LinuxWinePrefix = config.get_value("Linux Settings", "wineprefix")
			LinuxWinePath = config.get_value("Linux Settings", "wine_exec_path")
			LinuxTerminal = config.get_value("Linux Settings", "terminal")
			NewServerIcons = config.get_value("General Settings", "savedicons")
			for i in $Main/AddServerWindow/ScrollContainer/HBoxContainer.get_children():
				if i is TextureButton:
					i.queue_free()
			for i in NewServerIcons:
				imageadd(i)
			$"Main/Settings/Linux Settings/Panel/WPBox".text = LinuxWinePrefix
			$"Main/Settings/Linux Settings/Panel/WPBox2".text = LinuxWinePath
			$"Main/Settings/Linux Settings/Panel/CheckBox".pressed = LinuxTerminal
		"/NovetusFE/servers.ini":
			for i in config.get_sections():
				$Main/Serverlist/ItemList.add_item(i,pathtoimage(config.get_value(i,"icon","res://textures/charcustom.png")))

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
	saveconfig()

func saveconfig():
	var config = ConfigFile.new()
	config.set_value("Linux Settings", "wineprefix", $"Main/Settings/Linux Settings/Panel/WPBox".text)
	config.set_value("Linux Settings", "wine_exec_path", $"Main/Settings/Linux Settings/Panel/WPBox2".text)
	config.set_value("Linux Settings", "terminal", $"Main/Settings/Linux Settings/Panel/CheckBox".pressed)
	config.set_value("General Settings", "savedicons", NewServerIcons)
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
	$Main/Serverlist/Versions.text = Version
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
	var uri = to_uri($Main/DirectConnectWindow/LineEdit.text.split(":")[0].to_ascii().get_string_from_ascii(),$Main/DirectConnectWindow/LineEdit.text.split(":")[1].to_ascii().get_string_from_ascii())
	launch("/bin/NovetusURI.exe novetus://" + uri)

func to_uri(ip, port):
	var uri = Marshalls.utf8_to_base64(ip) + "|" + Marshalls.utf8_to_base64(port) + "|" + Marshalls.utf8_to_base64(Version)
	uri = Marshalls.utf8_to_base64(uri)
	return uri

func _on_DirectConnect_pressed():
	$Main/DirectConnectWindow.popup()

func multiplayert_item_activated(index):
	match $Main/Multiplayer/ItemList.get_item_text(index):
		"Join":
			#$Main/DirectConnectWindow.popup()
			$Main/Serverlist.popup()
			refreshserverlist()
		"Back":
			menu("")

func DirectConnect_Close_pressed():
	$Main/DirectConnectWindow.visible = false


func Firsttime_Button_pressed():
	$Main/Menu.visible = true


func _on_AddServer_pressed():
	$Main/AddServerWindow.popup()

func new_icon_pressed():
	$Main/AddServerWindow/ImageSelect.current_dir = WorkingDirectory
	$Main/AddServerWindow/ImageSelect.popup()

func _on_ImageSelect_file_selected(path):
	NewServerIcons.append(path)
	imageadd(path)

func imageadd(path):
	NewServerTexturePath = path
	var t = TextureButton.new()
	t.texture_normal = pathtoimage(path,[56,56])
	$Main/AddServerWindow/ScrollContainer/HBoxContainer.add_child(t)
	NewServerTexture = t.texture_normal
	t.connect("pressed",self,"icon_pressed",[t.texture_normal,t,path])

func pathtoimage(path,resize=null):
	var img = Image.new()
	var err = img.load(path)
	if(err != 0):
		print("error loading the image")
		return null
	if resize != null:
		img.resize(resize[0],resize[1])
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img)
	return img_tex

func icon_pressed(icon,node,path):
	for i in $Main/AddServerWindow/ScrollContainer/HBoxContainer.get_children():
		if i is TextureButton:
			i.modulate = Color("707070")
	node.modulate = Color("ffffff")
	NewServerTexture = icon
	NewServerTexturePath = path
	print("pressed")
	print(NewServerTexture)
	print(icon)

func AddServer_Close_pressed():
	$Main/AddServerWindow.visible = false


func _on_Add_Server_pressed():
	if $Main/AddServerWindow/LineEdit.text == "": return
	saveconfig()
	addtoserverlist($Main/AddServerWindow/LineEdit2.text,NewServerTexture)
	
func refreshserverlist():
	$Main/Serverlist/ItemList.clear()
	loadconfig("/NovetusFE/servers.ini")

func addtoserverlist(servername, icon):
	if f.file_exists(WorkingDirectory + "/NovetusFE/servers.ini"):
		serverconfig.load(WorkingDirectory + "/NovetusFE/servers.ini")
	#var uri = to_uri($Main/AddServerWindow/LineEdit.text.split(":")[0].to_ascii().get_string_from_ascii(),$Main/AddServerWindow/LineEdit.text.split(":")[1].to_ascii().get_string_from_ascii())
	var port
	if ":" in $Main/AddServerWindow/LineEdit.text:
		port = $Main/AddServerWindow/LineEdit.text.split(":")[1].to_ascii().get_string_from_ascii()
	else:
		port = "53640"
	var ip = $Main/AddServerWindow/LineEdit.text.split(":")[0].to_ascii().get_string_from_ascii()
	#var port = $Main/AddServerWindow/LineEdit.text.split(":")[1].to_ascii().get_string_from_ascii()
	#serverconfig.set_value(servername, "uri", "novetus://" + uri)
	serverconfig.set_value(servername, "ip", ip)
	serverconfig.set_value(servername, "port", port)
	serverconfig.set_value(servername, "icon", NewServerTexturePath)
	serverconfig.save(WorkingDirectory + "/NovetusFE/servers.ini")
	refreshserverlist()
	#$Main/Serverlist/ItemList.add_item(servername,icon)
	
	#print($Main/Serverlist/ItemList.items[servername])


func mplist_item_selected(index):
	$Main/Serverlist/Join.disabled = false
	$Main/Serverlist/Edit.disabled = false
	ServerIndex = index


func _on_Join_pressed():
	$Overlay.visible = true
	yield(get_tree().create_timer(1),"timeout")
	var e = $Main/Serverlist/ItemList.get_item_text(ServerIndex)
	serverconfig.load(WorkingDirectory + "/NovetusFE/servers.ini")
	launch("/bin/NovetusURI.exe " + to_uri(serverconfig.get_value(e,"ip"),serverconfig.get_value(e,"port")))
	$Overlay.visible = false
	


func multi_Versions_pressed():
	$Main/Serverlist/Versions.text = Version
	$Main/VersionsWindow.popup()


func multi_closed():
	$Main/Serverlist.visible = false
