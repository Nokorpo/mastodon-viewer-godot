extends TextureRect

func set_media(url: String) -> void:
	var image_request := ImageRequest.new()
	add_child(image_request)
	image_request.image_request_completed.connect(_image_request_completed)
	image_request.request_image(url)

func _image_request_completed(new_texture: Texture) -> void:
	texture = new_texture
