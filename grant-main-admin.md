# Grant Main Agent Full Admin in OpenClaw

## 1. Remove the limited device
```bash
openclaw devices remove <DEVICE_ID>
openclaw gateway restart
2. Trigger an admin-scope request

Run a command that requires admin privileges (e.g. create a cron job):

openclaw cron add \
  --name test-admin-scope \
  --cron "*/5 * * * *" \
  --agent main \
  --message "echo test" \
  --tools exec,read,write
3. Find the pending request
openclaw devices list

Look for:

Pending (1)
RequestId: <REQUEST_ID>
4. Approve the request
openclaw devices approve <REQUEST_ID>
5. Verify main agent now has admin
openclaw devices list

Expected:

operator.admin
operator.read
operator.write
operator.approvals
operator.pairing
6. Confirm functionality
openclaw cron list
Result
Main agent has full admin rights
No more pairing prompts for admin operations
Cron, exec, and automation fully enabled
