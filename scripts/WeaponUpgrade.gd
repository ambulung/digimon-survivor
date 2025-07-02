# File: WeaponUpgrade.gd
class_name WeaponUpgrade extends Resource

## A unique identifier, e.g., "whip" or "magic_wand"
@export var id: String

## The name shown to the player, e.g., "Energy Whip"
@export var name: String

## The scene that contains the weapon's logic, timer, and visuals.
@export var weapon_scene: PackedScene

## An icon for the upgrade card.
@export var icon: Texture2D

## The list of all possible levels.
## Level 0 (index 0) is ALWAYS for acquiring the weapon.
## Level 1 (index 1) is the first upgrade, and so on.
@export var levels: Array[WeaponLevel]
