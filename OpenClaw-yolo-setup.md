# OpenClaw Host Exec Runbook

This runbook enables OpenClaw to run system commands on the host it is installed on.

It assumes:
- OpenClaw is already installed
- the gateway service itself is already working
- you want OpenClaw to execute commands on the local host
- you understand this is a high-trust configuration

---

## What this setup does

It configures three things:

1. **Host exec policy**  
   Allows exec requests to run without interactive approval prompts.

2. **Elevated access**  
   Allows your chat surface to request elevated execution.

3. **Shell command support**  
   Enables `/bash` and `!` style commands from chat.

---

## Recommended repeatable process

### 1) Apply the local exec preset

```bash
openclaw exec-policy preset yolo

This is the easiest current way to open local host exec policy.

It updates:

tools.exec.*
local exec approvals in ~/.openclaw/exec-approvals.json
2) Enable elevated execution
openclaw config set tools.elevated.enabled true
3) Allow your actual chat surface to request elevated execution

Use only the one you actually use.

Telegram
openclaw config set tools.elevated.allowFrom.telegram '["*"]'
Webchat
openclaw config set tools.elevated.allowFrom.webchat '["*"]'
Discord
openclaw config set tools.elevated.allowFrom.discord '["*"]'
Slack
openclaw config set tools.elevated.allowFrom.slack '["*"]'

If you want tighter security, replace ["*"] with the specific identity instead of allowing everyone on that surface.

4) Force exec to run on the gateway host
openclaw config set tools.exec.host gateway

This makes command execution target the OpenClaw host itself.

5) Enable shell-style commands
openclaw config set commands.bash true

This enables:

/bash ...
! ...
6) Restart the gateway
openclaw gateway restart

If your environment uses systemd user services and that restart path is unreliable, use your normal service restart method instead.

Example:

systemctl --user restart openclaw-gateway.service
7) Approve the pending device request if OpenClaw still says pairing is required
openclaw devices approve --latest

If needed, inspect first:

openclaw devices list

Or approve a specific request:

openclaw devices approve <request-id>

This matters because exec access often fails due to device scope approval, even when the exec policy is already correct.

Verification

Run:

openclaw config get tools.elevated.enabled
openclaw config get tools.elevated.allowFrom
openclaw config get tools.exec.host
openclaw config get tools.exec.security
openclaw config get tools.exec.ask
openclaw config get commands.bash
openclaw approvals get
openclaw gateway status

You want the gateway to be running and healthy.

Chat-side test

From your OpenClaw chat surface:

/elevated full

Then test:

/bash id

Then:

! uname -a

If those work, OpenClaw can execute commands on the host.

Fast copy-paste version

Use this if you want the shortest repeatable setup:

openclaw exec-policy preset yolo
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.telegram '["*"]'
openclaw config set tools.exec.host gateway
openclaw config set commands.bash true
openclaw gateway restart
openclaw devices approve --latest

Replace the Telegram line with the surface you actually use.

Webchat variant
openclaw exec-policy preset yolo
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.webchat '["*"]'
openclaw config set tools.exec.host gateway
openclaw config set commands.bash true
openclaw gateway restart
openclaw devices approve --latest
Telegram variant
openclaw exec-policy preset yolo
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.telegram '["*"]'
openclaw config set tools.exec.host gateway
openclaw config set commands.bash true
openclaw gateway restart
openclaw devices approve --latest
Safer version

Use a specific identity instead of ["*"].

Example pattern:

openclaw config set tools.elevated.allowFrom.telegram '["<your-telegram-id>"]'

That is safer than wildcard elevated access.

What usually goes wrong
1) Wrong allowlist key

Do not do this:

openclaw config set tools.elevated.allowFrom.PROVIDER '["ID_OR_*"]'

That creates a literal PROVIDER key instead of the real surface.

2) Pairing or scope-upgrade approval is still pending

Symptoms:

pairing required
scope-upgrade
gateway probe fails even though the service is running

Fix:

openclaw devices approve --latest
3) Gateway service restart problems

If openclaw gateway restart does not work in your environment, restart the service using the process manager you actually use.

Examples:

systemctl --user restart openclaw-gateway.service
Docker restart
supervisor
tmux or screen session restart
Troubleshooting ladder

If it still does not work, run:

openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor

That is the fastest sequence for finding the next blocker.

Summary

For most systems, this is the core pattern:

openclaw exec-policy preset yolo
openclaw config set tools.elevated.enabled true
openclaw config set tools.elevated.allowFrom.<surface> '["*"]'
openclaw config set tools.exec.host gateway
openclaw config set commands.bash true
openclaw gateway restart
openclaw devices approve --latest

Replace <surface> with:

telegram
webchat
discord
slack
