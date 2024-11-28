extends PanelContainer

const MEDIA_ATTACHMENT = preload("res://addons/mastodon_viewer/interface/media_attachment.tscn")

func set_username(username: String) -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/Username.text = username

func set_content(content: String) -> void:
	$MarginContainer/VBoxContainer/Content.text = content

func set_avatar(url: String) -> void:
	var image_request = ImageRequest.new()
	add_child(image_request)
	image_request.image_request_completed.connect(_image_request_completed)
	image_request.request_image(url)

func set_media_attachments(media_array: Array) -> void:
	%MediaAttachments.visible = true
	%MediaAttachments.columns = media_array.size()
	for media in media_array:
		var new_media = MEDIA_ATTACHMENT.instantiate()
		%MediaAttachments.add_child(new_media)
		new_media.set_media(media.url)

func _image_request_completed(new_texture):
	$MarginContainer/VBoxContainer/HBoxContainer/Avatar.texture = new_texture
