import board
import neopixel
import socket
import syslog

HOST = "127.0.0.1"  # Standard loopback interface address (localhost)
PORT = 60485  # Port to listen on (non-privileged ports are > 1023)

pixels = neopixel.NeoPixel(board.D18, 1)
pixels[0] = (20, 20, 20)

n = 0
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
    server_socket.bind((HOST, PORT))
    server_socket.listen()      
    server_socket.settimeout(0.2)
    syslog.syslog(f"server socket binded to the {HOST}:{PORT}")
    while True:
        try:
            conn, addr = server_socket.accept()
        except socket.timeout:
            server_socket.settimeout(0.2)
            n += 5
            v = 100 + 3 * abs(((n % 100) // 50) * 50 - n % 50)
            pixels[0] = (v, v, v)
            continue
        except Exception as e:
            syslog.syslog(syslog.LOG_ERR, e)
            server_socket.settimeout(10)
            continue
  
        with conn:
            syslog.syslog(f"connected by {addr}")
            pixels[0] = (0, 0, 255)
            while True:
                server_socket.settimeout(None)
                data = conn.recv(1024)
                s = data.decode("ascii")
                #print(s)
                err = f"error wrong data {data}"
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
                                    err = None
                if not err is None:
                    syslog.syslog(syslog.LOG_ERR, err)

                if not data:
                    server_socket.settimeout(0.2)
                    conn.close()
                    pixels[0] = (20, 20, 20)
                    syslog.syslog(f"disconnected {addr}")
                    break
