@tool
extends Control

const MASTODON_VIEWER_NODE = preload("res://addons/mastodon_viewer/interface/mastodon_viewer.tscn")

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
			if url.count("/") < 3:
				show_error("The URL is not a valid Mastodon user profile URL.")
				return
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

var mastodon_viewer_instance: Control

func _ready() -> void:
	if !Engine.is_editor_hint():
		mastodon_viewer_instance = MASTODON_VIEWER_NODE.instantiate()
		mastodon_viewer_instance.server_url = server_url
		mastodon_viewer_instance.user_id = user_id
		mastodon_viewer_instance.statuses_quantity = statuses_quantity
		add_child(mastodon_viewer_instance)

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

func show_error(message: String):
	if !Engine.is_editor_hint():
		mastodon_viewer_instance.get_node("Status").text = message
	push_warning(message)

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
