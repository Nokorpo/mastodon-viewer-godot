@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"MastodonViewer",
		"Control",
		preload("res://addons/mastodon_viewer/wrapper.gd"),
		preload("res://addons/mastodon_viewer/mastodon_viewer_icon.svg")
	)

func _exit_tree():
	remove_custom_type("MastodonViewer")
