extends Node

var network = NetworkedMultiplayerENet.new()
var server_address = "127.0.0.1"
# var server_address = "a988-62-98-80-82.ngrok.io"
var port = 4050
var match_room = {
	"status": "waiting",
	"players": {}
}

var client_clock = 0	# time in ms
var decimal_corrector: float = 0
var latency_array = []
var latency = 0			# latency in ms
var delta_latency = 0

var logged_room_id = -1

signal log_status(new_status)
signal refresh_room_status(new_status)

func connect_to_server():
	emit_signal("log_status", "Connecting to " + server_address + " ...")
	network.create_client(server_address, port)
	get_tree().set_network_peer(network)
	printt("Connected at port", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

func disconnect_from_server():
	network.close_connection()
	get_tree().network_peer = null
	emit_signal("log_status", "Disconnected from the server")	

remote func return_match_room_status(room_status):
	printt("return_match_room_status", room_status)
	if get_tree().get_network_unique_id() in room_status.players:
		logged_room_id = room_status.id
		match_room = room_status
	emit_signal("refresh_room_status", room_status)

func fetch_user_join_room(room_id):
	rpc_id(1, "fetch_user_join_room", room_id)
	
remote func user_load_battlefield(room_id):
	logged_room_id = int(room_id)
	get_tree().change_scene("res://scenes/BattleField.tscn")

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state, logged_room_id)

remote func receive_room_state(room_state):
	var battlefield_node = get_tree().get_root().get_node("BattleField")
	if battlefield_node:
		battlefield_node.update_world_state(room_state)

# when the player is in the lobby, not in a match
remote func return_match_rooms(match_rooms):
	for match_room in match_rooms:
		return_match_room_status(match_room)

func fetch_player_damage():
	rpc_id(1, "fetch_player_damage", logged_room_id)

func determine_latency():
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())

remote func return_latency(client_time):
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_port = latency_array[4]
		for i in range(latency_array.size() - 1, -1, -1):
			if latency_array[i] > 2 * mid_port and latency_array[i] > 20: # this latency is a spike
				latency_array.remove(i) # we don't need it for calculation
			else:
				total_latency += latency_array[i]
		var average_latency = total_latency / latency_array.size()
		delta_latency = average_latency - latency
		latency = average_latency
		#print("New latency ", latency)
		#print("Delta latency ", delta_latency)
		latency_array.clear()

func fetch_server_time():
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "determine_latency")
	self.add_child(timer)

remote func return_server_time(server_time, client_time): # in ms
	latency = (OS.get_system_time_msecs() - client_time) / 2
	client_clock = server_time + latency
	
func _ready():
	pass

func _physics_process(delta): #0.01667
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_corrector += (delta * 1000) - int(delta * 1000)
	if decimal_corrector >= 1.00:
		client_clock += 1
		decimal_corrector -= 1.00

func _on_peer_connected(peer_id):
	if peer_id == 1:
		print("Successfully connected to the server")
		emit_signal("log_status", "Successfully connected to the server")
		fetch_server_time()

func _on_peer_disconnected(peer_id):
	if peer_id == get_tree().get_network_unique_id():
		print("disconnected ", peer_id)
		emit_signal("log_status", "Disconnected from the server")
