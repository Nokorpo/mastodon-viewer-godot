extends HTTPRequest
class_name ImageRequest
## HTTPRequest that returns a texture

var file_extension: String
var _url: String

signal image_request_completed(new_texture: ImageTexture)

func request_image(url: String) -> void:
	_url = url
	file_extension = _get_image_extension(url)
	
	request_completed.connect(_http_request_completed)
	
	var error = request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Image couldn't be downloaded. Try a different image.")
		return

	var image := Image.new()
	var error
	match file_extension:
		"png":
			error = image.load_png_from_buffer(body)
		"jpg", "jpeg":
			error = image.load_jpg_from_buffer(body)
	
	if error != OK:
		push_warning("Couldn't load the image with the following URL: '%s'" % _url)
	else:
		image_request_completed.emit(ImageTexture.create_from_image(image))
	queue_free()

func _get_image_extension(path: String) -> String:
	var regex = RegEx.new()
	regex.compile("[0-9a-z]+$")
	var content_parsed = regex.search(path)
	return content_parsed.strings[0]
