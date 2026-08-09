# System architecture

## Architecture style
- React Native mobile client
- Offline-first local queue for inspections
- REST API sync service when network is available

## Constraints
- Photo attachments must be capped at 10MB each
- Sync recovery should resume queued uploads after connectivity returns
- Critical user feedback should appear within 1 second after user action

## Integrations
- Authentication service
- Media upload service
- Inspection sync API