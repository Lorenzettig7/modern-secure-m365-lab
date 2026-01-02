# Incident Runbook — Teams/SharePoint access denied

## Symptoms
- User gets “Access denied” to a Team, channel, or SharePoint site

## Scope check
- One site/team or multiple?
- Is the user internal or a guest?

## Where to look
- Teams admin center → Teams → Manage team → Members
- SharePoint admin center → Sites → Active sites → Permissions
- Entra ID group membership (if using groups)

## Root cause patterns
- Missing membership after governance restructure
- Guest access restricted / external sharing policy
- Permission inheritance broken

## Fix
1. Validate the resource and expected access model
2. Add user to the correct group/team role
3. Validate SharePoint permissions (Owners/Members/Visitors)
4. Re-test access

## Prevention
- Maintain ownership + access matrix
- Keep standard roles (Owners/Members/Visitors)
- Review external sharing posture routinely
