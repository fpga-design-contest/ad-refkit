import asyncio
import websockets
import io
import os
import cv2
from PIL import Image
import time
import fcntl

class ImageServer:

    def __init__(self, loop, address , port):
        self.loop = loop
        self.address = address
        self.port = port

    async def _handler(self, websocket, path):
        lock = open("/root/app/pcam-test-websocket/lock", "r")
        with io.BytesIO() as stream:
            while True:
                # img = cv2.imread("image.png")
                binary = ""
                fcntl.flock(lock, fcntl.LOCK_EX)
                with open("image.png", "rb") as f:
                    binary = f.read()
                fcntl.flock(lock, fcntl.LOCK_UN)
                
                try:
                    ##await websocket.send(img.encode())
                    await websocket.send(binary)
                except Exception as e:
                    print('image send Error.')
                    print(e)
                    break
                
                time.sleep(5)

    def run(self):
        self._server = websockets.serve(self._handler, self.address, self.port)
        self.loop.run_until_complete(self._server)
        self.loop.run_forever()

if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    ws_is = ImageServer(loop, '0.0.0.0', 9998)
    ws_is.run()
