class_name HtmlParser
extends RefCounted

static var instance: HtmlParser:
	get():
		instance = HtmlParser.new()
		return instance

static func convert_html_to_bbcode(html: String) -> String:
	return instance.parse(html)

func parse(html: String) -> String:
	var parser = XMLParser.new()
	parser.open_buffer(html.to_utf8_buffer())
	var paragraphs := _get_paragraphs(parser)
	var parsed_text := _convert_lines_to_bbcode(paragraphs)
	return parsed_text

func _get_paragraphs(parser: XMLParser) -> Array[String]:
	var paragraphs: Array[String] = []
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name: String = parser.get_node_name()
			if node_name == "p" or node_name == "span":
				var paragraph: ParagraphContent = _get_paragraph_content(parser)
				paragraphs.append(paragraph.content)
				parser.seek(paragraph.buffer_position)
	return paragraphs

func _get_paragraph_content(parser: XMLParser) -> ParagraphContent:
	var current_paragraph: String = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_TEXT:
			var text: String = parser.get_node_data()
			current_paragraph += _format_line(text)
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "p":
			break
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "a":
			var link: LinkContent = _get_link_content(parser)
			parser.seek(link.buffer_position)
			current_paragraph += _format_link(link)
	return HtmlParser.ParagraphContent.new(current_paragraph, parser.get_node_offset())

class ParagraphContent:
	var content: String
	var buffer_position: int
	func _init(_content, _buffer_position) -> void:
		content = _content
		buffer_position = _buffer_position

func _format_line(line: String) -> String:
	var text := line.xml_unescape()
	# Required to prevent bbcode insertion (or breaking the RichText)
	text = text.replace("[", "[lb]")
	text = text.replace("]", "[rb]")
	return text

func _convert_lines_to_bbcode(lines: Array[String]) -> String:
	var bbcode: String = ""
	for line in lines:
		var formated_line := "[p]%s[/p][p] [/p]" % line
		bbcode += formated_line
	return bbcode

func _get_link_content(parser: XMLParser) -> LinkContent:
	var text: String = ""
	var address: String = parser.get_named_attribute_value_safe("href")
	
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_TEXT:
			text += _format_line(parser.get_node_data())
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "a":
			break
	return HtmlParser.LinkContent.new(text, address, parser.get_node_offset())

func _format_link(link: LinkContent) -> String:
	# The final space is required for links to not get joined. For example,
	# multiple hastags like "#a #b #c" will appear as "#a#b#c" without the space
	return "[url=%s]%s[/url] " % [link.address, link.text]

class LinkContent:
	var text: String
	var address: String
	var buffer_position: int
	func _init(_text, _address, _buffer_position) -> void:
		text = _text
		address = _address
		buffer_position = _buffer_position
