extends PanelContainer

signal upgrade_selected(upgrade: Upgrade)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var button: Button = $Button

var current_upgrade: Upgrade

func _ready():
	button.pressed.connect(_on_button_pressed)

func display_upgrade(upgrade: Upgrade):
	current_upgrade = upgrade
	name_label.text = upgrade.name
	description_label.text = upgrade.description
	
	if upgrade.icon:
		icon_rect.texture = upgrade.icon
		icon_rect.show()
	else:
		icon_rect.hide()

func _on_button_pressed():
	if current_upgrade:
		emit_signal("upgrade_selected", current_upgrade)
