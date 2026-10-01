#!/usr/bin/env python3
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = {
    "agents": {},
    "knowledge": {},
    "pathways": {},
}

def read_json(handler):
    length = int(handler.headers.get("content-length", "0"))
    if not length:
        return {}
    return json.loads(handler.rfile.read(length).decode("utf-8"))

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(fmt % args)

    def send_json(self, status, payload):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        body = read_json(self)

        if self.path == "/v2/agents":
            rid = "agent_demo_001"
            STATE["agents"][rid] = {"id": rid, "name": body["name"]}
            return self.send_json(200, {"data": {"agent": STATE["agents"][rid]}, "errors": None})

        if self.path == "/v1/knowledge/learn":
            rid = "kb_demo_001"
            STATE["knowledge"][rid] = {"id": rid, **body, "status": "COMPLETED"}
            return self.send_json(200, {"data": STATE["knowledge"][rid], "errors": None})

        if self.path == "/v1/pathway/create":
            rid = "path_demo_001"
            STATE["pathways"][rid] = {
                "pathway_id": rid,
                "name": body.get("name", ""),
                "description": body.get("description", ""),
                "nodes": [],
                "edges": [],
            }
            return self.send_json(200, {"status": "success", "pathway_id": rid})

        if self.path.startswith("/v1/pathway/"):
            rid = self.path.rsplit("/", 1)[-1]
            if rid not in STATE["pathways"]:
                return self.send_json(404, {"error": "not found"})
            STATE["pathways"][rid].update(body)
            return self.send_json(200, {
                "status": "success",
                "message": "Pathway updated successfully",
                "pathway_data": STATE["pathways"][rid],
            })

        return self.send_json(404, {"error": "unknown route", "path": self.path})

    def do_PATCH(self):
        body = read_json(self)

        if self.path.startswith("/v2/agents/"):
            rid = self.path.rsplit("/", 1)[-1]
            if rid not in STATE["agents"]:
                return self.send_json(404, {"error": "not found"})
            STATE["agents"][rid].update(body)
            return self.send_json(200, {"data": STATE["agents"][rid], "errors": None})

        return self.send_json(404, {"error": "unknown route", "path": self.path})

    def do_GET(self):
        if self.path.startswith("/v2/agents/"):
            rid = self.path.rsplit("/", 1)[-1]
            obj = STATE["agents"].get(rid)
            if not obj:
                return self.send_json(404, {"error": "not found"})
            return self.send_json(200, {"data": obj, "errors": None})

        if self.path.startswith("/v1/knowledge/"):
            rid = self.path.rsplit("/", 1)[-1]
            obj = STATE["knowledge"].get(rid)
            if not obj:
                return self.send_json(404, {"error": "not found"})
            return self.send_json(200, {"data": obj, "errors": None})

        if self.path.startswith("/v1/pathway/"):
            rid = self.path.rsplit("/", 1)[-1]
            obj = STATE["pathways"].get(rid)
            if not obj:
                return self.send_json(404, {"error": "not found"})
            return self.send_json(200, {
                "status": "success",
                "pathway_id": rid,
                "name": obj.get("name"),
                "description": obj.get("description"),
                "nodes": obj.get("nodes", []),
                "edges": obj.get("edges", []),
            })

        return self.send_json(404, {"error": "unknown route", "path": self.path})

    def do_DELETE(self):
        if self.path.startswith("/v2/agents/"):
            rid = self.path.rsplit("/", 1)[-1]
            STATE["agents"].pop(rid, None)
            return self.send_json(200, {"data": None, "errors": None})

        if self.path.startswith("/v1/knowledge/"):
            rid = self.path.rsplit("/", 1)[-1]
            STATE["knowledge"].pop(rid, None)
            return self.send_json(200, {"data": None, "errors": None})

        if self.path.startswith("/v1/pathway/"):
            rid = self.path.rsplit("/", 1)[-1]
            STATE["pathways"].pop(rid, None)
            return self.send_json(200, {"status": "success"})

        return self.send_json(404, {"error": "unknown route", "path": self.path})

if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 18080), Handler)
    print("Mock Bland API listening on http://127.0.0.1:18080", flush=True)
    server.serve_forever()
