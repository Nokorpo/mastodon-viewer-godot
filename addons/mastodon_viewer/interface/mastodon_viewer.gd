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
		_show_error("An error occurred in the HTTP request.")

func _update_user_status_updates(result: int, _response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_show_error("An error occurred in the HTTP request.")
		return

	$Status.visible = false
	var json = _parse_json(body)
	for status_dictionary in json:
		if status_dictionary.reblog:
			_create_reblog_status(status_dictionary)
		else:
			_create_post_status(status_dictionary)

func _create_post_status(status_dictionary: Dictionary) -> Control:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.content
	new_status.set_username(_get_username(status_dictionary.account))
	new_status.set_avatar(status_dictionary.account.avatar)
	new_status.set_content(HtmlParser.convert_html_to_bbcode(content_raw))
	if status_dictionary.media_attachments:
		new_status.set_media_attachments(status_dictionary.media_attachments)
	return null

func _create_reblog_status(status_dictionary: Dictionary) -> Control:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.reblog.content
	new_status.set_username(_get_username(status_dictionary.reblog.account))
	new_status.set_avatar(status_dictionary.reblog.account.avatar)
	new_status.set_content(HtmlParser.convert_html_to_bbcode(content_raw))
	if status_dictionary.reblog.media_attachments:
		new_status.set_media_attachments(status_dictionary.reblog.media_attachments)
	return null

static func _get_username(account: Dictionary) -> String:
	return account.display_name if not account.display_name.is_empty() else account.username

static func _parse_json(response_body: PackedByteArray) -> Variant:
	var json = JSON.new()
	json.parse(response_body.get_string_from_utf8())
	return json.get_data()

func _show_error(message: String) -> void:
	if !Engine.is_editor_hint():
		$Status.text = message
	push_warning(message)
