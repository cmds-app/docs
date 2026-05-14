# Mailgun Callback Integration — v26.2 Status

## Summary

The Mailgun webhook callback feature is **code-complete** in v26.2, but the `MailgunCallbackEnabled` flag **must remain `false`** in the v26.2 Production release unless the Mailgun account itself has been configured end-to-end to POST events to the Production environment.

Shipping the flag as `false` (the v26.2 default in `config/AppSettings.json`) preserves v26.1 send-path behavior. Flipping it to `true` without the corresponding Mailgun-side configuration will cause outbound email to never transition to `Delivered`.

## What was shipped in v26.2

### New webhook receiver

**Endpoint:** `POST api/messages/handle-webhook`
**File:** `source/InSite.UI/Api/Controllers/MessageController.cs:33`

The endpoint validates every inbound request:

| Check | Failure code | Implementation |
|---|---|---|
| Body deserializes as `Payload` with signature | 0, 1 | `TryDeserializePayload` |
| `EventData` present (missing = 200 OK, ignored) | — | `TryDeserializePayload` |
| `UserVariables` present | 2 | `TryDeserializePayload` |
| Event GUID parseable | 3 | `TryDeserializePayload` |
| `mailout-id` user variable is a valid GUID | 4 | `ValidateUserVariables` |
| `environment-domain` user variable present | 5 | `ValidateUserVariables` |
| `environment-domain` matches current request host | 6 | `ValidateUserVariables` |
| `sender-domain` user variable present | 7 | `ValidateUserVariables` |
| Signature timestamp parseable | 8 | `ValidateSignature` |
| Signature age within 5-minute tolerance | 9 | `ValidateSignature` |
| Signature token not reused (replay protection via `MemoryCache`) | 10 | `ValidateSignature` |
| Sender domain matches a configured `Mailgun.Domains[]` entry | 11 | `ValidateSignature` |
| HMAC signature valid against that domain's token | 12 | `ValidateSignature` |

Valid payloads dispatch `HandleMailoutCallback` to the command bus, which is handled by `MessageAggregate.HandleMailoutCallback` in `src/library/Shift.Sdk/Service/Messaging/Messages/Process/Write/`.

### Supported event types

All seven Mailgun event types are implemented in `MessageController.GetStatus`:

- `Accepted`
- `Delivered` (captures SMTP code, message, description)
- `Failed` (splits into `Failed` vs `TemporaryFailed` based on `e.IsTemporary`; captures SMTP diagnostics)
- `Complained`
- `Opened` (captures IP, geolocation, user agent)
- `Clicked` (captures IP, geolocation, user agent, URL)
- `Unsubscribed` (captures IP, geolocation, user agent)

### New Mailgun webhook model classes

22 model classes under `source/InSite.UI/Api/Models/MailgunWebhook/` deserialize the Mailgun payload (`Payload`, `PayloadSignature`, `EventDataAccepted/Delivered/Failed/Complained/Opened/Clicked/Unsubscribed`, `EnvelopeData`, `MessageData`, `ClientInfo`, `GeolocationData`, `DeliveryStatusData`, `StorageData`, `AccountData`, `EventDataFlags`, `EventLogLevel`, `MessageDataHeaders`, `MessageDataAttachment`, `JsonEventDataConverter`).

### New configuration key

`config/AppSettings.json:26`

```json
"MailgunCallbackEnabled": false
```

Bound to `Application.MailgunCallbackEnabled` (`src/library/Shift.Common/Configuration/Application.cs:44`) and exposed to the send path via `MailgunServerSettings.MailgunCallbackEnabled` (`src/library/Shift.Common/Mail/MailgunServerSettings.cs:19,32`).

## What the flag actually controls

The flag does **not** gate the webhook endpoint. The endpoint is always live and will accept any payload that passes signature validation.

The flag gates the **sender-side** behavior in exactly two places:

### 1. Optimistic "Delivered" shortcut in `MailgunServer.SendAsync`

`src/library/Shift.Common/Mail/MailgunServer.cs:201`

```csharp
// If the scheduled delivery time is in the past (or within the next few minutes) then there is not
// enough time for an admin to login to Mailgun and cancel it. Therefore, consider it a delivered email
// message - when callbacks from Mailgun are not yet supported.

var cutoff = DateTimeOffset.Now.AddMinutes(_settings.MinutesBeforeCancellationIsDisallowed);

if (email.MailoutScheduled <= cutoff && !_settings.MailgunCallbackEnabled)
{
    result = MailgunStatus.Deliver();
}
```

- **Flag `false`** — near-immediate emails are marked `Delivered` synchronously at send time. No callback required. This is the v26.1 behavior.
- **Flag `true`** — the optimistic shortcut is skipped. The mailout stays in its intermediate state (`Queued`) and only transitions to `Delivered` when Mailgun POSTs a `delivered` webhook.

### 2. UI wording on the Send Email page

`source/InSite.UI/UI/Admin/Contacts/People/Forms/SendEmail.aspx.cs:487`

```csharp
else if (email.MailoutStatus == "Delivered" && !ServiceLocator.AppSettings.Application.MailgunCallbackEnabled)
    ScreenStatus.AddMessage(AlertType.Success, $"The email message has been delivered to <strong>{Email.Recipient.Email}</strong>.");
else
    ScreenStatus.AddMessage(AlertType.Warning, $"No email message has been sent.");
```

- **Flag `false`** — the admin sees "delivered" immediately.
- **Flag `true`** — the admin sees the "No email message has been sent" warning because `MailoutStatus` is not yet `Delivered`.

## Why the flag must remain `false` in Production

Setting the flag to `true` requires **all** of the following in the target environment, otherwise every outbound email gets stuck short of `Delivered`:

1. **Mailgun hosted configuration** — a webhook URL of `https://<env-host>/api/messages/handle-webhook` has been registered in the Mailgun dashboard for every event type the system needs (`delivered`, `failed`, `complained`, `opened`, `clicked`, `unsubscribed`).
2. **Signing key parity** — each `AppSettings.Integration.Mailgun.Domains[].Token` equals the Mailgun HTTP webhook signing key for that domain. Any mismatch causes `InvalidPayload(12)` and the callback never reaches the aggregate.
3. **Domain match** — the sending domain used by the outbox appears in `AppSettings.Integration.Mailgun.Domains[].Domain` and matches the `sender-domain` user variable attached to outbound messages. Mismatch → `InvalidPayload(11)`.
4. **User variables attached on send** — outbound mail is tagged with `mailout-id` (GUID), `environment-domain` (= the request host receiving the callback), and `sender-domain`. Missing values → `InvalidPayload(4|5|7)`; host mismatch → `InvalidPayload(6)`.
5. **Network reachability** — Mailgun's webhook senders can reach the environment over HTTPS (no firewall / VPN / IP allowlist blocking).

None of items 1–5 are controlled by the v26.2 source code — they live in the Mailgun dashboard and in per-environment config. There is no evidence in the repo that the Production Mailgun account has been updated to point at the v26.2 Production endpoint.

## Recommendation for the v26.2 Production release

- **Keep** `MailgunCallbackEnabled: false` in the Production `AppSettings.json` override.
- **Regression-test with the flag `false`** on `ui/admin/contacts/people/send-email` and any mailout flow that routes through `MailgunServer.SendAsync`. Behavior should be identical to v26.1.
- **Only flip to `true` in UAT** to validate the callback path, and only after a Mailgun admin has:
  - Added the UAT environment host to Mailgun's webhook URL list
  - Verified the UAT signing key is stored in `AppSettings.Integration.Mailgun.Domains[].Token`
  - Confirmed outbound mail in UAT carries the required user variables
- **The Mailout Failures report** (`ui/admin/messages/mailouts/failures/search`) will appear empty in Production while the flag is `false` — this is expected, because the report is populated by webhook callbacks.

## References

- Endpoint: `source/InSite.UI/Api/Controllers/MessageController.cs`
- Models: `source/InSite.UI/Api/Models/MailgunWebhook/*`
- Setting binding: `src/library/Shift.Common/Configuration/Application.cs:44`
- Sender shortcut: `src/library/Shift.Common/Mail/MailgunServer.cs:201`
- Send UI wording: `source/InSite.UI/UI/Admin/Contacts/People/Forms/SendEmail.aspx.cs:487`
- Command handler: `src/library/Shift.Sdk/Service/Messaging/Messages/Process/Write/Handlers/MessageCommandReceiver.cs:83`
- Aggregate: `src/library/Shift.Sdk/Service/Messaging/Messages/State/MessageAggregate.cs:94`
- DB migrations: `source/InSite.Maintenance/Scripts/Upgrades/v26.2/262.2026.0224.1524 TEC-466.sql`, `262.2026.0319.1504 TEC-466.sql`
- Tickets: TEC-466
