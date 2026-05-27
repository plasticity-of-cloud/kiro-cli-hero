# Kiro CLI + Microsoft Entra ID Integration Guide

## Purpose

Connect Kiro Pro+/Power subscription directly to Microsoft Entra ID (via M365 plasticity.cloud tenant) to maintain **organizational-level data privacy** without depending on AWS IAM Identity Centre.

### Why This Matters

| Auth Method | Data Used for Service Improvement? |
|---|---|
| GitHub / Google / Builder ID (any tier) | **Yes** — individual subscriber |
| IAM Identity Center | No — organizational |
| **External IdP (Entra ID)** | **No — organizational** |

> Source: [kiro.dev/docs/getting-started/authentication](https://kiro.dev/docs/getting-started/authentication)

---

## Prerequisites

- Microsoft 365 subscription with `plasticity.cloud` domain
- DNS control for `plasticity.cloud` (to add TXT verification record)
- AWS account (Spendbase member account) for Kiro profile
- Microsoft Entra admin center access: https://entra.microsoft.com

---

## Step 1: Create Enterprise Application in Entra ID

1. Go to **Microsoft Entra admin center** → https://entra.microsoft.com
2. Navigate to **Enterprise applications** → **New application**
3. Select **"Create your own application"**
4. Name: `Kiro-Entra`
5. Select: **"Integrate any other application you don't find in the gallery (Non-gallery)"**
6. Click **Create**

---

## Step 2: Configure the Application

### 2.1 Expose API Endpoint

1. Go to **App registrations** → **All applications** → **Kiro-Entra**
2. Select **"Expose an API"**
3. Click **"Add"** next to "Application ID URI" → save with default value
4. Add **two scopes**:

| Scope Name | Who can consent? | Display Name | State |
|---|---|---|---|
| `codewhisperer:completions` | Admins and Users | codewhisperer:completions | Enabled |
| `codewhisperer:conversations` | Admins and Users | codewhisperer:conversations | Enabled |

### 2.2 Add Redirect URIs

1. Go to **Authentication (Preview)** for the Kiro-Entra app
2. Click **"Add Redirect URI"** → select **"Mobile and desktop application"**
3. Add these two URIs:
   ```
   kiro://kiro.oauth/callback
   http://localhost/oauth/callback
   ```

### 2.3 Set Access Token Version to OAuth 2.0

1. Go to **App registrations** → **Kiro-Entra** → **Manifest**
2. Find `"api"` → `"requestedAccessTokenVersion"`
3. Change value from `null` to `2`
4. **Save**

---

## Step 3: Create Kiro Profile in AWS Console

1. Open AWS Console → navigate to **Kiro console**: https://us-east-1.console.aws.amazon.com/amazonq/developer/home
2. Select **"Get started"** → **"Connect an existing Identity provider"**
3. From Entra ID (**App registrations → Kiro-Entra → Overview**), copy:
   - **Application (client) ID** → paste into Kiro "Application ID"
   - **Directory (tenant) ID** → paste into Kiro "Tenant ID"
4. Click **Create**

### 3.1 Add and Verify Domain

1. In Kiro console → **Settings** → **Identity management → Domains**
2. Click **"Add domain"** → enter `plasticity.cloud`
3. Copy the **verification token**
4. In your DNS provider (Route53 or wherever plasticity.cloud is managed):
   - Create a **TXT record** with the verification token
5. Wait a few minutes → status changes to **"Verified"**

---

## Step 4: Set Up SCIM Provisioning

### 4.1 Generate SCIM Token in Kiro

1. Kiro console → **Settings** → **Identity Management → Access Tokens**
2. Click **"Generate Token"** → copy the token

### 4.2 Configure Provisioning in Entra

1. Entra admin center → **Enterprise Apps** → **Kiro-Entra** → **Provisioning**
2. Set **Provisioning Mode** to **Automatic**
3. Configure:
   - **Tenant URL**: Copy "SCIM Endpoint" from Kiro Settings → Identity management
   - **Secret Token**: Paste the token from step 4.1
4. Click **"Test Connection"** → verify success
5. Click **Save**

### 4.3 Fix Attribute Mapping

1. **Refresh the page** after saving provisioning
2. Go to **Attribute Mapping (Preview)**
3. Select **"Provision Microsoft Entra ID Users"**
4. Edit **externalId** → set Source attribute to `objectId` → Save

### 4.4 Remove Unsupported Attributes

**Delete these from the mapping** (they will cause provisioning failures):

- `urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:employeeNumber`
- `urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:department`
- `urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:manager`
- `phoneNumbers[type eq "work"].value`
- `phoneNumbers[type eq "mobile"].value`
- `phoneNumbers[type eq "fax"].value`

Save after removing all.

---

## Step 5: Add Users and Subscribe

1. Entra → **Enterprise Apps** → **Kiro-Entra** → **Users and groups**
2. Add yourself (`ecosystem@plasticity.cloud`)
3. Go to **Provisioning** → **Provision on Demand** to sync immediately
4. In Kiro console → **Subscriptions** → assign yourself **Pro+** or **Power** tier

---

## Step 6: Log In via Kiro CLI

```bash
kiro-cli login
# Select: "Your organization"
# Enter: ecosystem@plasticity.cloud
# Browser opens → authenticate via Entra ID
```

---

## Step 7 (Optional): Enable API Keys for CI/CD

1. AWS Console → Kiro settings: https://us-east-1.console.aws.amazon.com/amazonq/developer/home#/settings
2. Toggle **API keys** to **On**
3. Go to https://app.kiro.dev → **API Keys** section
4. Create key → copy `ksk_...` value
5. Use in CI/CD:
   ```bash
   export KIRO_API_KEY="ksk_..."
   kiro-cli chat --no-interactive --trust-tools=read,grep "your prompt"
   ```

---

## Migration Order of Operations

| # | Action | When |
|---|---|---|
| 1 | Set up Entra ID integration (Steps 1-5 above) | **Before** deleting AWS org |
| 2 | Verify login works via `kiro-cli login` with "Your organization" | **Before** deleting AWS org |
| 3 | Delete old AWS org / join Spendbase | After verification |
| 4 | Confirm Kiro profile still accessible from member account | After migration |
| 5 | Apply Activate credits to cover Kiro subscription billing | After migration |

---

## Key References

- Kiro Authentication Methods: https://kiro.dev/docs/getting-started/authentication
- Kiro + Entra ID Setup: https://kiro.dev/docs/enterprise/identity-provider/microsoft-entra
- Kiro Enterprise: https://kiro.dev/enterprise/
- Kiro Data Protection: https://kiro.dev/docs/privacy-and-security/data-protection/#service-improvement
- Kiro CLI Headless Mode: https://kiro.dev/docs/cli/headless/
- Kiro Subscription Guide: https://kiro.dev/docs/enterprise/subscribe/

---

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Login fails with authorization error | Access token version not set to 2 | Edit Manifest → set `api.requestedAccessTokenVersion` to `2` |
| Login screen shows error | Scopes not configured | Add both `codewhisperer:*` scopes in Expose an API |
| User has no subscription after login | Attribute mapping wrong | Set externalId source to `objectId`, delete all subscriptions, re-provision |
| Login redirect fails | Missing redirect URIs | Add both `kiro://kiro.oauth/callback` and `http://localhost/oauth/callback` |
| Users/groups don't appear in Kiro | Provisioning not triggered | Use "Provision on Demand" in Entra (auto-sync takes ~40 min) |
