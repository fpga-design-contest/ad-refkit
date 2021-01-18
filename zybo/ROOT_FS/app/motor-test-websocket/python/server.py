from websocket_server import WebsocketServer
from datetime import datetime

import os

def new_client(client, server):
    server.send_message_to_all(datetime.now().isoformat() + ": new client joined!")

def recv_message(client, server, message):
    print("recv", message);
    content = message.split(' ')
    print("left:{}, right:{}, left ang.:{}, right ang.:{}, sec.:{}".format(content[1], content[2], content[3], content[4], content[5]))
    os.system("/root/app/motor-test-websocket/build/motor-test-websocket {} {} {} {} {}".format(content[1], content[2], content[3], content[4], content[5]))
    server.send_message_to_all("")

server = WebsocketServer(9999, host="0.0.0.0")
server.set_fn_new_client(new_client)
server.set_fn_message_received(recv_message)
server.run_forever()

