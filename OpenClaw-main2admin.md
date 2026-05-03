# OpenClaw — Grant Main Agent Full Admin (Working Process)

## 1. Install / Upgrade OpenClaw
npm install -g openclaw@latest

---

## 2. Enable Gateway-Based Execution
openclaw config set tools.exec.host gateway
openclaw config set tools.exec.security full
openclaw config set tools.exec.ask off

---

## 3. Enable Elevated (Admin) Execution
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.webchat '["*"]'

---

## 4. Configure Approvals (Correct Format)

mkdir -p ~/.openclaw

cat > ~/.openclaw/exec-approvals.json <<'EOF'
{
  "version": 1,
  "defaults": {
    "security": "full",
    "ask": "off",
    "askFallback": "full"
  },
  "agents": {},
  "allowlist": []
}
EOF

---

## 5. Restart Gateway

openclaw gateway restart
sleep 5
openclaw gateway status

---

## 6. Verify Configuration

openclaw approvals get --gateway

Expected output:
Defaults  security=full, ask=off, askFallback=full
Capability: admin-capable

---

## 7. Validate From Main Agent (Web UI)

whoami
crontab -l
touch /root/test-admin-from-agent.txt
ls -l /root/test-admin-from-agent.txt

Expected:
- No approval prompts
- Commands execute immediately
- File is created successfully

---

## Result

Main agent has:
- Full system command execution
- No approval prompts
- Elevated (admin-level) permissions
- Gateway-based execution enabled
