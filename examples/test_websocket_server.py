#!/usr/bin/env python3
"""
Simple WebSocket echo server for testing jok WebSocket implementation.
Uses basic socket programming with WebSocket handshake.
Operates in binary mode for game development use cases.
"""

import socket
import hashlib
import base64
import struct
import logging
import threading

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def parse_headers(data):
    headers = {}
    lines = data.decode('utf-8').split('\r\n')
    for line in lines[1:]:
        if ':' in line:
            key, value = line.split(':', 1)
            headers[key.strip()] = value.strip()
    return headers

def create_handshake_response(key):
    GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
    accept = base64.b64encode(
        hashlib.sha1((key + GUID).encode()).digest()
    ).decode()

    response = (
        'HTTP/1.1 101 Switching Protocols\r\n'
        'Upgrade: websocket\r\n'
        'Connection: Upgrade\r\n'
        f'Sec-WebSocket-Accept: {accept}\r\n'
        '\r\n'
    )
    return response.encode()

def decode_frame(data):
    if len(data) < 2:
        return None

    byte1, byte2 = struct.unpack('BB', data[:2])
    opcode = byte1 & 0x0F
    masked = byte2 & 0x80
    payload_len = byte2 & 0x7F

    offset = 2

    if payload_len == 126:
        payload_len = struct.unpack('>H', data[offset:offset+2])[0]
        offset += 2
    elif payload_len == 127:
        payload_len = struct.unpack('>Q', data[offset:offset+8])[0]
        offset += 8

    if masked:
        mask = data[offset:offset+4]
        offset += 4
        payload = bytearray(data[offset:offset+payload_len])
        for i in range(len(payload)):
            payload[i] ^= mask[i % 4]
    else:
        payload = data[offset:offset+payload_len]

    return opcode, payload

def encode_frame(data):
    frame = bytearray()
    frame.append(0x82)  # FIN + binary frame

    payload = data.encode() if isinstance(data, str) else data
    length = len(payload)

    if length < 126:
        frame.append(length)
    elif length < 65536:
        frame.append(126)
        frame.extend(struct.pack('>H', length))
    else:
        frame.append(127)
        frame.extend(struct.pack('>Q', length))

    frame.extend(payload)
    return bytes(frame)

def handle_client(client_socket, address):
    client_id = f"{address[0]}:{address[1]}"
    logging.info(f"Client connected: {client_id}")

    try:
        # WebSocket handshake
        data = client_socket.recv(4096)
        headers = parse_headers(data)

        if 'Sec-WebSocket-Key' in headers:
            response = create_handshake_response(headers['Sec-WebSocket-Key'])
            client_socket.send(response)
            logging.info(f"WebSocket handshake completed with {client_id}")

            # Echo loop
            while True:
                data = client_socket.recv(4096)
                if not data:
                    break

                result = decode_frame(data)
                if result:
                    opcode, payload = result

                    if opcode == 0x8:  # Close frame
                        logging.info(f"Close frame received from {client_id}")
                        break
                    elif opcode == 0x2:  # Binary frame
                        message = payload.decode('utf-8')
                        logging.info(f"Received from {client_id}: {message}")

                        # Echo back
                        echo_msg = f"Echo: {message}"
                        client_socket.send(encode_frame(echo_msg))
                        logging.info(f"Sent to {client_id}: {echo_msg}")

    except Exception as e:
        logging.error(f"Error with client {client_id}: {e}")
    finally:
        client_socket.close()
        logging.info(f"Connection closed: {client_id}")

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', 8080))
    server.listen(5)

    logging.info("Starting WebSocket server on ws://localhost:8080")
    logging.info("Server is ready to accept connections")

    try:
        while True:
            client_socket, address = server.accept()
            client_thread = threading.Thread(
                target=handle_client,
                args=(client_socket, address)
            )
            client_thread.daemon = True
            client_thread.start()
    except KeyboardInterrupt:
        logging.info("\nServer stopped by user")
    finally:
        server.close()

if __name__ == "__main__":
    main()
