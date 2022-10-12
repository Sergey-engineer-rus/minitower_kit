import board
import neopixel
import socket

HOST = "127.0.0.1"  # Standard loopback interface address (localhost)
PORT = 60485  # Port to listen on (non-privileged ports are > 1023)

pixels = neopixel.NeoPixel(board.D18, 1)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()      
    while True:
        pixels[0] = (50, 50, 50)
        conn, addr = s.accept()
        with conn:
            #print(f"Connected by {addr}")
            pixels[0] = (50, 128, 50)
            while True:
                data = conn.recv(1024)
                s = data.decode("ascii")
                #print(s)
                if len(s) > 8 and len(s) < 16:
                    if s[0] == '(' and s[-1] == ')':
                        a = s[1:-1].split(', ')
                    if len(a) == 3:
                        if a[0].isdigit() and a[1].isdigit() and a[2].isdigit():
                            b = int(a[0])
                            g = int(a[1])
                            r = int(a[2])
                            if b < 256 and g < 256 and r < 256:
                                #print("r=%d g=%d b=%d "% (r, g, b))
                                pixels[0] = (r, g, b)
                if not data:
                    conn.close()
                    #print(f"Disnnected {addr}\n")
                    break

#camera = PiCamera()

#camera.start_preview()
#sleep(10000)
#camera.stop_preview()

