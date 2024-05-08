@icon("./mastodon_viewer_icon.svg")
class_name MastodonViewer
extends Control

const STATUS = preload("res://src/status.tscn")

## Example: https://mastodon.gamedev.place
@export var server_url: String
## Example: 109282546179741156
@export var user_id: String
## How many statuses are going to be loaded
@export var statuses_quantity: int = 5

func _ready() -> void:
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed.bind(http_request))

	var error = http_request.request("%s/api/v1/accounts/%s/statuses?limit=%s" \
		% [server_url, user_id, str(statuses_quantity)])
	if error != OK:
		show_error("An error occurred in the HTTP request.")
	
	await http_request.request_completed
	http_request.queue_free()

func _http_request_completed(result, _response_code, _headers, body, http_request):
	http_request.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		$Status.visible = false
	else:
		show_error("An error occurred in the HTTP request.")
		return
	
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	for status_dictionary: Dictionary in response:
		var new_status = STATUS.instantiate()
		%StatusList.add_child(new_status)
		
		var content_raw: String
		if status_dictionary.reblog:
			content_raw = status_dictionary.reblog.content
			new_status.set_username(status_dictionary.reblog.account.display_name)
			new_status.set_avatar(status_dictionary.reblog.account.avatar)
			if status_dictionary.reblog.media_attachments:
				new_status.set_media_attachments(status_dictionary.reblog.media_attachments)
		else:
			content_raw = status_dictionary.content
			new_status.set_username(status_dictionary.account.display_name)
			new_status.set_avatar(status_dictionary.account.avatar)
			if status_dictionary.media_attachments:
				new_status.set_media_attachments(status_dictionary.media_attachments)
		
		var regex = RegEx.new()
		regex.compile("<[^>]*>")
		var content_parsed = regex.sub(content_raw, "", true)
		new_status.set_content(content_parsed)

func show_error(message: String):
	$Status.text = message
	push_warning(message)
