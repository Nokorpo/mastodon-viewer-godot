extends Control

const STATUS = preload("res://addons/mastodon_viewer/interface/status.tscn")

var server_url: String
var user_id: String
var statuses_quantity: int

func _ready() -> void:
	_request_user_status_updates()

func _request_user_status_updates() -> void:
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_update_user_status_updates)
	http_request.request_completed.connect(http_request.queue_free.unbind(4))
	var error = http_request.request("%s/api/v1/accounts/%s/statuses?limit=%s" \
		% [server_url, user_id, str(statuses_quantity)])
	if error != OK:
		show_error("An error occurred in the HTTP request.")

func _update_user_status_updates(result, _response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		show_error("An error occurred in the HTTP request.")
		return

	$Status.visible = false
	var json = _parse_json(body)
	for status_dictionary: Dictionary in json:
		if status_dictionary.reblog:
			_create_reblog_status(status_dictionary)
		else:
			_create_post_status(status_dictionary)

func _create_post_status(status_dictionary: Dictionary) -> Control:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.content
	new_status.set_username(status_dictionary.account.display_name)
	new_status.set_avatar(status_dictionary.account.avatar)
	new_status.set_content(_remove_html_tags(content_raw))
	if status_dictionary.media_attachments:
		new_status.set_media_attachments(status_dictionary.media_attachments)
	return null

func _create_reblog_status(status_dictionary: Dictionary) -> Control:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.reblog.content
	new_status.set_username(status_dictionary.reblog.account.display_name)
	new_status.set_avatar(status_dictionary.reblog.account.avatar)
	new_status.set_content(_remove_html_tags(content_raw))
	if status_dictionary.reblog.media_attachments:
		new_status.set_media_attachments(status_dictionary.reblog.media_attachments)
	return null

static func _remove_html_tags(html: String) -> String:
	var html_tags_regex: RegEx = RegEx.new()
	html_tags_regex.compile("<[^>]*>")
	return html_tags_regex.sub(html, "", true)

static func _parse_json(response_body: PackedByteArray) -> Variant:
	var json = JSON.new()
	json.parse(response_body.get_string_from_utf8())
	return json.get_data()

func show_error(message: String):
	if !Engine.is_editor_hint():
		$Status.text = message
	push_warning(message)
