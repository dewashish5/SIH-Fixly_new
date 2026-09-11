# Federation admin auth + cut societies

## Hierarchy
`super_admin` → federation (`federation_admin`) → workers. No societies.

## Admin
- Federations page: Add Federation modal (email unique, password + auto-generate).
- Remove Settings Societies tab / society create UI.
- Fix `adminRole` to use `user.adminRole`.

## Backend
- `POST /api/admin/federations` (super_admin): create Cooperative + User (bcrypt), status approved.
- Stop society create/update/assign admin routes.
- Workers use federation only.

## Mobile
- Worker identity form: add state + district; send on setup-profile.
