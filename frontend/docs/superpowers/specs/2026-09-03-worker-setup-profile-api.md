# Worker setup profile API

- Endpoint: `PUT /api/workers/setup-profile`
- Auth: Bearer access token (ApiClient)
- Body: 3-step JSON via `WorkerSetupProfileMapper.toBody`
- Submit from step 3; navigate status only on success
