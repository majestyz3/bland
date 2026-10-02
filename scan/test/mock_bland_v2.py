#!/usr/bin/env python3
"""Mock of the Bland API endpoints used by scan/. Test-only.

Deliberately pessimistic where Bland's behavior is undocumented: publishing a
judge mints a NEW draft version, so the module must stay idempotent anyway.
Also asserts the safety rules on every request it sees.
"""
import json, re, sys, uuid
from http.server import BaseHTTPRequestHandler, HTTPServer

S = {"agents": {}, "versions": {}, "kb": {}, "evals": {}, "eval_versions": {},
     "scenarios": {}, "checks": {}, "envs": {}, "alarms": {}}
VIOLATIONS = []

def nid(): return str(uuid.uuid4())

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): sys.stderr.write("%s %s\n" % (self.command, self.path))
    def body(self):
        n = int(self.headers.get("content-length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}
    def send(self, code, data):
        raw = json.dumps({"data": data, "errors": None} if code < 400 else {"data": None, "errors": [data]}).encode()
        self.send_response(code); self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(raw))); self.end_headers(); self.wfile.write(raw)
    def nf(self): self.send(404, {"error": "NOT_FOUND", "path": self.path})

    def do_POST(self):
        p, b = self.path, self.body()
        if p == "/v2/agents":
            i = nid(); S["agents"][i] = {"id": i, "name": b.get("name")}
            S["envs"][i] = {"dev": None, "staging": None, "production": None}
            return self.send(201, {"agent": S["agents"][i]})
        m = re.fullmatch(r"/v2/agents/([^/]+)/versions", p)
        if m:
            snap = b.get("snapshot") or {}
            if snap.get("contact", {}).get("inboundNumbers"): VIOLATIONS.append("inbound numbers in snapshot")
            if not snap.get("knowledge", {}).get("kbIds"): VIOLATIONS.append("no kbIds in snapshot")
            text = json.dumps(snap)
            if "kb_source_fixture_0001" in text: VIOLATIONS.append("source KB id leaked into new snapshot")
            v = nid(); S["versions"][v] = {"id": v, "agent_id": m.group(1), "name": b.get("name"), "snapshot": snap}
            return self.send(201, {"version": S["versions"][v]})
        m = re.fullmatch(r"/v2/agents/([^/]+)/publish", p)
        if m:
            S["envs"][m.group(1)]["staging"] = b.get("version_id")
            return self.send(201, {"semver": "0.1.0", "environments": self.envs(m.group(1)), "warnings": []})
        m = re.fullmatch(r"/v2/agents/([^/]+)/promote", p)
        if m:
            VIOLATIONS.append("promotion called while enable_promotion should be false")
            return self.send(201, {"environments": self.envs(m.group(1))})
        m = re.fullmatch(r"/v2/agents/([^/]+)/environments/staging/check-runs", p)
        if m:
            cfg = S["checks"].get(m.group(1) + "staging")
            if not cfg: return self.send(400, {"error": "BAD_REQUEST"})
            if b.get("version_id") not in S["versions"]: VIOLATIONS.append("check run for unknown version")
            r = nid(); S.setdefault("runs", {})[r] = {"id": r, "cfg": cfg}
            return self.send(202, {"id": r, "status": "PENDING"})
        if p == "/v1/knowledge/learn":
            if b.get("type") != "text" or not b.get("text"): VIOLATIONS.append("bad KB body")
            i = "kb_" + nid()[:8]; S["kb"][i] = {"id": i, "status": "COMPLETED", "name": b.get("name")}
            return self.send(200, S["kb"][i])
        if p == "/v1/evals/agents":
            i, v = nid(), nid()
            S["evals"][i] = {"id": i, "name": b.get("name"), "current_version_id": v, "active_version_id": None}
            S["eval_versions"][v] = {"id": v, "state": "editable"}
            return self.send(201, {"agent": S["evals"][i], "version": S["eval_versions"][v]})
        m = re.fullmatch(r"/v1/evals/agents/([^/]+)/publications", p)
        if m:
            e = S["evals"][m.group(1)]
            e["active_version_id"] = e["current_version_id"]
            S["eval_versions"][e["active_version_id"]]["state"] = "archived"
            nv = nid(); S["eval_versions"][nv] = {"id": nv, "state": "editable"}
            e["current_version_id"] = nv     # pessimistic: new draft after publish
            return self.send(201, e)
        if p == "/v1/agent-testing/scenarios":
            if b.get("scenario_type") != "AGENT" or not b.get("agent_id"): VIOLATIONS.append("scenario not agent-targeted")
            i = nid(); S["scenarios"][i] = dict(b, id=i); return self.send(201, S["scenarios"][i])
        if p == "/v1/alarms":
            i = nid(); S["alarms"][i] = dict(b, id=i); return self.send(201, S["alarms"][i])
        self.nf()

    def envs(self, a):
        return [{"id": a + "-" + k, "env_type": k, "current_version_id": v} for k, v in S["envs"][a].items()]

    def do_PUT(self):
        p, b = self.path, self.body()
        m = re.fullmatch(r"/v2/agents/([^/]+)/environments/([^/]+)/checks", p)
        if m:
            for e in b.get("evals", []):
                if S["eval_versions"].get(e.get("eval_agent_version_id"), {}).get("state") != "archived":
                    VIOLATIONS.append("checks pinned to an unpublished judge version")
            if not 1 <= len(b.get("scenario_ids", [])) <= 5: VIOLATIONS.append("checks need 1-5 scenarios")
            S["checks"][m.group(1) + m.group(2)] = b; return self.send(200, b)
        m = re.fullmatch(r"/v1/agent-testing/scenarios/([^/]+)", p)
        if m and m.group(1) in S["scenarios"]:
            S["scenarios"][m.group(1)].update(b); return self.send(200, S["scenarios"][m.group(1)])
        self.nf()

    def do_PATCH(self):
        p, b = self.path, self.body()
        m = re.fullmatch(r"/v1/evals/agents/([^/]+)/versions/([^/]+)", p)
        if m:
            v = S["eval_versions"].get(m.group(2))
            if not v: return self.nf()
            if v["state"] != "editable": return self.send(409, {"error": "VERSION_NOT_EDITABLE"})
            v.update(b); return self.send(200, v)
        m = re.fullmatch(r"/v1/evals/agents/([^/]+)", p)
        if m and m.group(1) in S["evals"]:
            S["evals"][m.group(1)].update(b); return self.send(200, S["evals"][m.group(1)])
        m = re.fullmatch(r"/v1/alarms/([^/]+)", p)
        if m and m.group(1) in S["alarms"]:
            S["alarms"][m.group(1)].update(b); return self.send(200, S["alarms"][m.group(1)])
        m = re.fullmatch(r"/v2/agents/([^/]+)", p)
        if m and m.group(1) in S["agents"]:
            S["agents"][m.group(1)].update(b); return self.send(200, S["agents"][m.group(1)])
        self.nf()

    def do_GET(self):
        p = self.path.split("?")[0]
        if p == "/__violations": return self.send(200, VIOLATIONS)
        m = re.fullmatch(r"/v2/agents/([^/]+)/check-runs/([^/]+)", p)
        if m:
            run = S.get("runs", {}).get(m.group(2))
            if not run: return self.nf()
            vs = [{"name": S["evals"][e["eval_agent_id"]]["name"], "required": e["required"], "match_rate": 1.0, "score": 92.0, "passed": True} for e in run["cfg"]["evals"]]
            return self.send(200, {"id": run["id"], "status": "PASSED", "overall_passed": True, "verdicts": vs})
        m = re.fullmatch(r"/v2/agents/([^/]+)/versions/([^/]+)", p)
        if m: return self.send(200, S["versions"][m.group(2)]) if m.group(2) in S["versions"] else self.nf()
        m = re.fullmatch(r"/v2/agents/([^/]+)/environments/([^/]+)/checks", p)
        if m: return self.send(200, S["checks"][m.group(1) + m.group(2)]) if m.group(1) + m.group(2) in S["checks"] else self.nf()
        m = re.fullmatch(r"/v2/agents/([^/]+)/environments", p)
        if m: return self.send(200, self.envs(m.group(1))) if m.group(1) in S["envs"] else self.nf()
        m = re.fullmatch(r"/v2/agents/([^/]+)", p)
        if m: return self.send(200, {"agent": S["agents"][m.group(1)]}) if m.group(1) in S["agents"] else self.nf()
        m = re.fullmatch(r"/v1/knowledge/([^/]+)", p)
        if m: return self.send(200, S["kb"][m.group(1)]) if m.group(1) in S["kb"] else self.nf()
        m = re.fullmatch(r"/v1/evals/agents/([^/]+)/versions/([^/]+)", p)
        if m: return self.send(200, S["eval_versions"][m.group(2)]) if m.group(2) in S["eval_versions"] else self.nf()
        m = re.fullmatch(r"/v1/evals/agents/([^/]+)", p)
        if m: return self.send(200, S["evals"][m.group(1)]) if m.group(1) in S["evals"] else self.nf()
        m = re.fullmatch(r"/v1/agent-testing/scenarios/([^/]+)", p)
        if m: return self.send(200, S["scenarios"][m.group(1)]) if m.group(1) in S["scenarios"] else self.nf()
        m = re.fullmatch(r"/v1/alarms/([^/]+)", p)
        if m: return self.send(200, S["alarms"][m.group(1)]) if m.group(1) in S["alarms"] else self.nf()
        self.nf()

    def do_DELETE(self):
        p = self.path
        for key, rx in [("agents", r"/v2/agents/([^/]+)"), ("kb", r"/v1/knowledge/([^/]+)"), ("evals", r"/v1/evals/agents/([^/]+)"),
                        ("scenarios", r"/v1/agent-testing/scenarios/([^/]+)"), ("alarms", r"/v1/alarms/([^/]+)")]:
            m = re.fullmatch(rx, p)
            if m: S[key].pop(m.group(1), None); return self.send(200, {"deleted": True})
        m = re.fullmatch(r"/v2/agents/([^/]+)/environments/([^/]+)/checks", p)
        if m: S["checks"].pop(m.group(1) + m.group(2), None); return self.send(200, {"deleted": True})
        self.nf()

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 18081), H).serve_forever()
