@tool
@icon("./mastodon_viewer_icon.svg")
class_name MastodonViewer
extends Control

const STATUS = preload("res://src/status.tscn")

## The URL pointing to a Mastodon user profile.
## [br][br]
## This URL should point to the same instance where the account is hosted in.
## It won't work for links to an external profile, like this [b]incorrect[/b]
## example: "https://mastodon.gamedev.place/@nokorpo@gamedev.lgbt"
## [br][br]
## Example: https://gamedev.lgbt/@nokorpo
@export var profile_url: String:
	set(url):
		profile_url = url
		if Engine.is_editor_hint() and self.is_inside_tree() and not url.is_empty():
			var url_parser: UrlParser = UrlParser.new(url)
			if server_url == url_parser.server_url and username == url_parser.path:
				print("User already loaded, skipping.")
				return
			else:
				print("Setting user id and domain for url: %s" % url)
				server_url = url_parser.server_url
				_request_user_data(url_parser.domain, url_parser.path)

## How many status updates (posts) should be shown.
## [br][br]
## It defaults to 5 posts.
@export var statuses_quantity: int = 5

@export_group("User data")
## The URL of the Mastodon instance where the user is registered. It should be
## loaded automatically when setting the [member profile_url].
## [br][br]
## Example: "https://gamedev.lgbt/"
@export var server_url: String
## Number ID assigned to the user by its instance. It should be loaded
## automatically when setting the [member profile_url].
## [br][br]
## Example: 112569134535397857
@export var user_id: String
## Number ID assigned to the user by its instance. It should be loaded
## automatically when setting the [member profile_url].
## [br][br]
## Example: "nokorpo"
@export var username: String


func _request_user_data(domain: String, user_name_from_path: String) -> void:
	var request_url = "https://%s/api/v1/accounts/lookup?acct=%s@%s" \
		% [domain, user_name_from_path, domain]
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_update_user_data)
	http_request.request_completed.connect(http_request.queue_free.unbind(4))
	var error = http_request.request(request_url)
	if error != OK:
		show_error("Error retrieving user data. Please, check the user exists.")

func _update_user_data(result, _response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		show_error("Error retrieving user data. Please, check the user exists.")
		return

	var json = _parse_json(body)
	if json.has("error"):
		show_error("Error retrieving user. The server returned: %s" % json["error"])
		return

	user_id = json["id"]
	username = json["username"]
	print("Successfully set user id and domain.")

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

func _create_post_status(status_dictionary: Dictionary) -> MastodonStatus:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.content
	new_status.set_username(status_dictionary.account.display_name)
	new_status.set_avatar(status_dictionary.account.avatar)
	new_status.set_content(_remove_html_tags(content_raw))
	if status_dictionary.media_attachments:
		new_status.set_media_attachments(status_dictionary.media_attachments)
	return null

func _create_reblog_status(status_dictionary: Dictionary) -> MastodonStatus:
	var new_status = STATUS.instantiate()
	%StatusList.add_child(new_status)
	var content_raw: String = status_dictionary.reblog.content
	new_status.set_username(status_dictionary.reblog.account.display_name)
	new_status.set_avatar(status_dictionary.reblog.account.avatar)
	new_status.set_content(_remove_html_tags(content_raw))
	if status_dictionary.reblog.media_attachments:
		new_status.set_media_attachments(status_dictionary.reblog.media_attachments)
	return null

func show_error(message: String):
	if !Engine.is_editor_hint():
		$Status.text = message
	push_warning(message)

static func _remove_html_tags(html: String) -> String:
	var html_tags_regex: RegEx = RegEx.new()
	html_tags_regex.compile("<[^>]*>")
	return html_tags_regex.sub(html, "", true)

static func _parse_json(response_body: PackedByteArray) -> Variant:
	var json = JSON.new()
	json.parse(response_body.get_string_from_utf8())
	return json.get_data()


class UrlParser:
	var server_url: String
	var domain: String
	var path: String

	func _init(url: String) -> void:
		var url_parts = url.split("/")
		server_url = "/".join([url_parts[0], "", url_parts[2]])
		domain = url_parts[2]
		path = url_parts[3]
