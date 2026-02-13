// WebSocket JavaScript library for jok framework
// This file provides the JavaScript implementation of WebSocket functionality
// that is called from Zig code via extern functions.
//
// Written by Claude Sonnet 4.5, reviewed by Jack-Ji

mergeInto(LibraryManager.library, {
    wasm_websocket_create: function(url_ptr, url_len, ws_ptr) {
        try {
            const url = UTF8ToString(url_ptr, url_len);
            const ws = new WebSocket(url);
            ws.binaryType = 'arraybuffer';

            if (!Module._websockets) {
                Module._websockets = {};
                Module._websocket_next_id = 1;
            }

            const id = Module._websocket_next_id++;
            Module._websockets[id] = ws;

            ws.onopen = function() {
                try {
                    Module.ccall('jok_websocket_on_open', null, ['number'], [id]);
                } catch (e) {
                    console.error('Error calling jok_websocket_on_open:', e);
                }
            };

            ws.onmessage = function(event) {
                const data = new Uint8Array(event.data);
                const data_ptr = _malloc(data.length);
                try {
                    HEAPU8.set(data, data_ptr);
                    Module.ccall('jok_websocket_on_message', null, ['number', 'number', 'number'], [id, data_ptr, data.length]);
                } finally {
                    _free(data_ptr);
                }
            };

            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
                try {
                    Module.ccall('jok_websocket_on_error', null, ['number'], [id]);
                } catch (e) {
                    console.error('Error calling jok_websocket_on_error:', e);
                }
            };

            ws.onclose = function() {
                try {
                    Module.ccall('jok_websocket_on_close', null, ['number'], [id]);
                } catch (e) {
                    console.error('Error calling jok_websocket_on_close:', e);
                }
                delete Module._websockets[id];
            };

            return id;
        } catch (e) {
            console.error('Failed to create WebSocket:', e);
            return 0;
        }
    },

    wasm_websocket_send: function(handle, data_ptr, len) {
        if (!Module._websockets) return;

        const ws = Module._websockets[handle];
        if (ws && ws.readyState === WebSocket.OPEN) {
            const data = HEAPU8.slice(data_ptr, data_ptr + len);
            ws.send(data.buffer);
        }
    },

    wasm_websocket_destroy: function(handle) {
        if (!Module._websockets) return;

        const ws = Module._websockets[handle];
        if (ws) {
            ws.onopen = null;
            ws.onmessage = null;
            ws.onerror = null;
            ws.onclose = null;
            delete Module._websockets[handle];
            ws.close();
        }
    }
});
