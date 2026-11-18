#!/usr/bin/env python3
"""Tiny LOCAL-ONLY sidecar used by the merchant integration tests.

The local Laravel API has no object storage, so a driver cannot upload the
delivery proof photo that is required before an order can be completed. The
integration test (which cannot touch the filesystem from inside the iOS
simulator app) asks this helper to run a small, whitelisted SQL statement
against the throwaway sqlite DB instead.

Usage: python3 local_sqlite_helper.py /abs/path/to/e2e_merchant.sqlite [port]
Binds 127.0.0.1 only. Never point it at a real database.
"""
import json
import sqlite3
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

DB = sys.argv[1]
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8002
ALLOWED = ("update ", "insert ", "select ", "delete ")


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body):
        raw = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        payload = json.loads(self.rfile.read(length) or b"{}")
        sql = str(payload.get("sql", "")).strip()
        if not sql.lower().startswith(ALLOWED):
            return self._send(400, {"error": "statement not allowed"})
        con = sqlite3.connect(DB, timeout=10)
        try:
            cur = con.execute(sql, payload.get("params", []))
            rows = cur.fetchall() if cur.description else []
            con.commit()
            self._send(200, {"rows": rows, "changes": con.total_changes})
        except Exception as e:  # noqa: BLE001
            self._send(500, {"error": str(e)})
        finally:
            con.close()

    def log_message(self, *args):
        pass


HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
