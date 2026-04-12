# OpenClaw YOLO Exec Setup

Enable OpenClaw to run system commands on its host without approval prompts.

**Assumes:** OpenClaw installed, gateway running, you accept the risk of unrestricted host exec.

---

## Step 1 -- Apply the YOLO exec preset

Sets `tools.exec.security=full` and `ask=off`, updates `~/.openclaw/exec-approvals.json`.

> **Run on:** Host command line

```bash
openclaw exec-policy preset yolo
```

## Step 2 -- Enable elevated execution

Allows the agent to run commands in elevated mode.

> **Run on:** Host command line

```bash
openclaw config set tools.elevated.enabled true
```

## Step 3 -- Allow your chat surface to use elevated mode

Pick **only** the surface you use. Replace `["*"]` with a specific user ID for tighter security.

> **Run on:** Host command line

**Telegram:**
```bash
openclaw config set tools.elevated.allowFrom.telegram '["*"]'
```

**Discord:**
```bash
openclaw config set tools.elevated.allowFrom.discord '["*"]'
```

**Slack:**
```bash
openclaw config set tools.elevated.allowFrom.slack '["*"]'
```

**Webchat:**
```bash
openclaw config set tools.elevated.allowFrom.webchat '["*"]'
```

## Step 4 -- Target exec at the gateway host

Ensures commands execute on the machine running OpenClaw.

> **Run on:** Host command line

```bash
openclaw config set tools.exec.host gateway
```

## Step 5 -- Enable shell commands from chat

Enables `/bash` and `!` prefixed commands in your chat surface.

> **Run on:** Host command line

```bash
openclaw config set commands.bash true
```

## Step 6 -- Restart the gateway

Picks up all config changes.

> **Run on:** Host command line

```bash
openclaw gateway restart
```

If that doesn't work in your environment, restart the service directly:

```bash
systemctl --user restart openclaw-gateway.service
```

## Step 7 -- Approve pending device requests

Exec access often fails due to a pending device/scope-upgrade approval, even when policy is correct.

> **Run on:** Host command line

```bash
openclaw devices approve --latest
```

To inspect first:

```bash
openclaw devices list
```

---

## Verify

> **Run on:** Host command line

```bash
openclaw config get tools.elevated.enabled
openclaw config get tools.elevated.allowFrom
openclaw config get tools.exec.host
openclaw config get commands.bash
openclaw gateway status
```

### Test from chat

> **Run in:** Your chat surface (Telegram, Discord, Slack, or Webchat)

```
/elevated full
```

Then:

```
/bash id
```

Then:

```
! uname -a
```

If those return output, you're done.

---

## Quick copy-paste block

All steps in one shot. Replace `telegram` with your surface.

> **Run on:** Host command line

```bash
openclaw exec-policy preset yolo
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.telegram '["*"]'
openclaw config set tools.exec.host gateway
openclaw config set commands.bash true
openclaw gateway restart
openclaw devices approve --latest
```

---

## Troubleshooting

**Wrong allowlist key** -- Don't use a placeholder like `PROVIDER`. Use the actual surface name (`telegram`, `discord`, `slack`, `webchat`).

**"pairing required" / "scope-upgrade" errors** -- Run `openclaw devices approve --latest`.

**Gateway won't restart** -- Use your actual process manager (`systemctl`, Docker, supervisor, etc.) instead of `openclaw gateway restart`.

**Still broken** -- Run these in order to find the blocker:

> **Run on:** Host command line

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
```
