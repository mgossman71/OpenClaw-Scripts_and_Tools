# Grant Main Agent Full Admin in OpenClaw

## 1. Identify the limited main-agent device

```bash
openclaw devices list
```

Find the device that only has limited scopes (e.g. `operator.read`, `operator.pairing`).

---

## 2. Remove the limited device

```bash
openclaw devices remove <DEVICE_ID>
openclaw gateway restart
```

---

## 3. Trigger an admin-scope request

```bash
openclaw cron add \
  --name test-admin-scope \
  --cron "*/5 * * * *" \
  --agent main \
  --message "echo test" \
  --tools exec,read,write
```

---

## 4. Verify cron job creation (this confirms admin scope worked)

```bash
openclaw cron list
```

---

## 5. Verify main agent now has admin

```bash
openclaw devices list
```

Expected scopes:

```text
operator.admin
```

A fully elevated device may show:

```text
operator.admin
operator.read
operator.write
operator.approvals
operator.pairing
```

---

## 6. Remove the test cron job

```bash
openclaw cron delete <CRON_JOB_ID>
```

---

## 7. Create the real Plane polling job

```bash
openclaw cron add \
  --name plane-work-poller \
  --cron "*/5 * * * *" \
  --agent main \
  --message "Check Plane workspace skynet for new work requests. If new work exists, process it and update the Plane issue with progress." \
  --tools exec,read,write
```

---

## 8. Final verification

```bash
openclaw cron list
openclaw devices list
```

---

## Result

- Main agent has full admin rights  
- Cron creation works without pairing prompts  
- Automation is fully enabled
