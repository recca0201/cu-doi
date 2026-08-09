# Azure DevOps API Authentication

## Table of Contents

- [Overview](#overview)
- [Creating a Personal Access Token](#creating-a-personal-access-token)
- [Authentication Pattern](#authentication-pattern)
- [Common Headers](#common-headers)
- [API Version](#api-version)
- [Error Handling](#error-handling)
- [Troubleshooting Authentication](#troubleshooting-authentication)
- [Security Best Practices](#security-best-practices)
- [Alternative Authentication Methods](#alternative-authentication-methods)

## Overview

Azure DevOps REST APIs use **Personal Access Tokens (PAT)** for authentication via HTTP Basic Auth. The PAT acts as an alternative password with fine-grained permissions.

## Creating a Personal Access Token

### Step-by-Step

1. **Access Token Settings**
   - Navigate to Azure DevOps: `https://dev.azure.com/{organization}`
   - Click user icon (top right) → **Personal Access Tokens**
   - Or direct: `https://dev.azure.com/{organization}/_usersSettings/tokens`

2. **Create New Token**
   - Click **+ New Token**
   - Enter a descriptive name (e.g., "CLI Access", "Automation Script")
   - Select expiration (30/60/90 days, or custom up to 1 year)
   - Choose scopes based on needed operations:

### Recommended Scopes

| Scope | Access Level | Use Case |
|-------|-------------|----------|
| **Work Items** | Read & Write | Create/update tasks, bugs, user stories |
| **Code** | Read & Write | Manage repos, branches, PRs, commits |
| **Build** | Read | Access build pipelines and results |
| **Release** | Read | Access release pipelines |
| **Project and Team** | Read | List projects, teams, iterations |
| **Identity** | Read | Resolve user emails to IDs |
| **Graph** | Read | Access organization structure |

**Minimum Scopes for Common Operations:**
- Work item management: `Work Items (Read & Write)`
- PR management: `Code (Read & Write)`
- Sprint planning: `Work Items (Read & Write)` + `Project and Team (Read)`
- Capacity planning: `Work (Read & Write)` + `Project and Team (Read)`

3. **Save Token Securely**
   - **CRITICAL:** Token shown only once - copy immediately
   - Store in password manager or secure vault
   - Never commit to version control
   - Use environment variables for scripts

## Authentication Pattern

### Basic Structure

Azure DevOps uses HTTP Basic Authentication where:
- **Username:** Empty (literally `:` prefix)
- **Password:** Your PAT

```bash
# Manual base64 encoding (not recommended, use curl -u instead)
echo -n ":YOUR_PAT" | base64
# Output: OllPVVJfUEFU

curl -H "Authorization: Basic OllPVVJfUEFU" \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"
```

### Recommended: Using curl -u Flag

The `-u` flag automatically handles base64 encoding:

```bash
# Best practice: Use curl -u with colon prefix
curl -u ":YOUR_PAT" \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"

# Or with environment variable (recommended)
export AZURE_DEVOPS_PAT="your-pat-token"
curl -u ":${AZURE_DEVOPS_PAT}" \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"
```

### Environment Variable Setup

**Bash/Zsh (Linux/macOS):**
```bash
# Temporary (current session only)
export AZURE_DEVOPS_PAT="your-pat-token"
export AZURE_DEVOPS_ORG="your-organization"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export AZURE_DEVOPS_PAT="your-pat-token"' >> ~/.bashrc
echo 'export AZURE_DEVOPS_ORG="your-organization"' >> ~/.bashrc
source ~/.bashrc
```

**PowerShell (Windows):**
```powershell
# Temporary (current session)
$env:AZURE_DEVOPS_PAT="your-pat-token"
$env:AZURE_DEVOPS_ORG="your-organization"

# Permanent (user profile)
[Environment]::SetEnvironmentVariable("AZURE_DEVOPS_PAT", "your-pat-token", "User")
[Environment]::SetEnvironmentVariable("AZURE_DEVOPS_ORG", "your-organization", "User")
```

**Windows CMD:**
```cmd
REM Temporary
set AZURE_DEVOPS_PAT=your-pat-token
set AZURE_DEVOPS_ORG=your-organization

REM Permanent (requires restart)
setx AZURE_DEVOPS_PAT "your-pat-token"
setx AZURE_DEVOPS_ORG "your-organization"
```

## Common Headers

### Standard GET Request
```bash
curl -u ":${AZURE_DEVOPS_PAT}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"
```

### POST/PATCH with JSON
```bash
curl -u ":${AZURE_DEVOPS_PAT}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"field":"value"}' \
  "https://dev.azure.com/{org}/_apis/endpoint?api-version=7.1"
```

### Work Item Operations (JSON Patch)
```bash
curl -u ":${AZURE_DEVOPS_PAT}" \
  -X PATCH \
  -H "Content-Type: application/json-patch+json" \
  -H "Accept: application/json" \
  -d '[{"op":"add","path":"/fields/System.Title","value":"New Title"}]' \
  "https://dev.azure.com/{org}/_apis/wit/workitems/{id}?api-version=7.1"
```

## API Version

**Current Version:** `7.1` (as of 2024)

Always include `api-version` parameter:
```bash
# Correct
curl "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"

# Incorrect (will fail)
curl "https://dev.azure.com/{org}/_apis/projects"
```

**Version History:**
- `7.1` - Current (2023+)
- `7.0` - Previous stable
- `6.0` - Legacy (still supported)

Use `7.1` for all new integrations.

## Error Handling

### Common HTTP Status Codes

| Code | Meaning | Common Causes | Solution |
|------|---------|---------------|----------|
| 200 | Success | Request completed | Parse response |
| 201 | Created | Resource created successfully | Parse response for new ID |
| 204 | No Content | Delete succeeded | No response body |
| 400 | Bad Request | Invalid JSON, missing required fields | Check request body format |
| 401 | Unauthorized | Invalid PAT, expired token | Regenerate PAT, check environment variable |
| 403 | Forbidden | Insufficient permissions | Add required scopes to PAT |
| 404 | Not Found | Wrong project/repo/work item ID | Verify resource exists |
| 429 | Too Many Requests | Rate limit exceeded | Implement backoff, reduce frequency |
| 500 | Server Error | Azure DevOps issue | Retry with exponential backoff |
| 503 | Service Unavailable | Maintenance or overload | Wait and retry |

### Error Response Format

```json
{
  "message": "Detailed error message",
  "typeKey": "ErrorType",
  "errorCode": 12345,
  "eventId": 3000
}
```

### Parsing Errors in curl

```bash
# Save response to file for inspection
curl -u ":${AZURE_DEVOPS_PAT}" \
  -w "\nHTTP Status: %{http_code}\n" \
  -o response.json \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"

# Show HTTP status code
curl -u ":${AZURE_DEVOPS_PAT}" \
  -w "\nStatus: %{http_code}\n" \
  -s \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"

# Follow redirects and show errors
curl -u ":${AZURE_DEVOPS_PAT}" \
  -f \
  -L \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"
```

## Troubleshooting Authentication

### Issue: 401 Unauthorized

**Symptoms:**
```json
{
  "message": "TF400813: The user '' is not authorized to access this resource."
}
```

**Solutions:**
1. Verify PAT is not expired (check token settings in Azure DevOps)
2. Ensure colon prefix: `-u ":${PAT}"` not `-u "${PAT}"`
3. Check environment variable is set: `echo $AZURE_DEVOPS_PAT`
4. Regenerate PAT if needed
5. Verify organization name is correct

### Issue: 403 Forbidden

**Symptoms:**
```json
{
  "message": "Access denied. Check that you have the appropriate permissions."
}
```

**Solutions:**
1. Check PAT scopes match operation requirements
2. Add missing scopes to existing PAT or create new one
3. Verify you're a member of the project/organization
4. Check if specific permissions are required (e.g., PR approval permissions)

### Issue: Invalid JSON Response

**Symptoms:**
HTML error page instead of JSON

**Solutions:**
1. Verify organization name (common typo)
2. Check URL structure (`dev.azure.com` not `visualstudio.com`)
3. Ensure API version parameter is included
4. Check for typos in endpoint path

### Testing Authentication

**Quick PAT validation:**
```bash
# Should return list of projects
curl -u ":${AZURE_DEVOPS_PAT}" \
  "https://dev.azure.com/${AZURE_DEVOPS_ORG}/_apis/projects?api-version=7.1"

# Pretty print with jq
curl -u ":${AZURE_DEVOPS_PAT}" \
  "https://dev.azure.com/${AZURE_DEVOPS_ORG}/_apis/projects?api-version=7.1" \
  | jq .
```

## Rate Limiting

Azure DevOps implements rate limiting to prevent abuse:

**Limits:**
- ~200 requests per user per minute (varies by operation)
- Burst capacity for occasional spikes
- Stricter limits on expensive operations (queries, batch updates)

**Handling Rate Limits:**
```bash
# Check rate limit headers (if available)
curl -i -u ":${AZURE_DEVOPS_PAT}" \
  "https://dev.azure.com/{org}/_apis/projects?api-version=7.1"

# Implement retry with backoff
retry_count=0
max_retries=3
while [ $retry_count -lt $max_retries ]; do
  response=$(curl -w "%{http_code}" -u ":${AZURE_DEVOPS_PAT}" \
    "https://dev.azure.com/{org}/_apis/endpoint")

  if [ "$response" != "429" ]; then
    break
  fi

  retry_count=$((retry_count + 1))
  sleep $((2 ** retry_count))  # Exponential backoff: 2, 4, 8 seconds
done
```

## Security Best Practices

1. **Never expose PAT in code:**
   - Use environment variables
   - Add `.env` files to `.gitignore`
   - Rotate tokens regularly (every 90 days)

2. **Minimize token scope:**
   - Only grant necessary permissions
   - Use separate tokens for different purposes
   - Revoke unused tokens

3. **Monitor token usage:**
   - Review token activity in Azure DevOps
   - Revoke if suspicious activity detected
   - Set expiration dates

4. **Secure storage:**
   - Use password managers (1Password, LastPass, etc.)
   - Use secret management tools (Azure Key Vault, HashiCorp Vault)
   - Never commit to Git repositories

5. **Token rotation:**
   - Create new token before old expires
   - Update environment variables and configurations
   - Revoke old token after migration

## Alternative Authentication Methods

### OAuth 2.0
For web applications and third-party integrations. More complex but better for user-facing apps.

### Azure Active Directory (AAD)
For enterprise scenarios with SSO and conditional access policies.

### Service Principals
For automated scenarios and CI/CD pipelines in Azure-integrated environments.

**Note:** PAT is recommended for personal use, scripts, and CLI tools. Use OAuth/AAD for production applications.
