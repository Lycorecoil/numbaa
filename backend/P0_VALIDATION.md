# NUMBAA — Story Pack P0 V1.0 validation

Date: 2026-11-04 (Africa/Lagos).
Local repository: `D:\Projects\NUMBAA`.
Branch: `fix/builder-security-p0`.
Base: `main` at `f0ce86fab81ed4a9c7eef97cea1b870637c19d12`.

## Changes

- SEC-01: site creation requires the authenticated user's ID. The service checks business ownership with a parameterized query and locks the business with `FOR SHARE` before any insertion. Missing identity returns 401; foreign/missing business returns 403. The HTTP request and successful response formats are unchanged.
- SEC-02: product lookup, update, deletion and image update use both product ID and site ID. The controller still verifies site ownership. Missing/cross-site targets return 404. Image uploads check the target before calling Vercel Blob, and check the scoped update result afterward.
- DATA-01: site creation and site/section replacement use `BEGIN`, `COMMIT`, `ROLLBACK` on one checked-out client, including section reads. Connections are released in `finally`; failed rollback discards the connection and preserves the original error. Site deletion uses one atomic DELETE with the existing cascading foreign keys for sections and products (migration 001).
- Added tests using the built-in Node.js test runner; no new dependencies or lockfile changes.

## Exact changed files

1. `backend/package.json`
2. `backend/src/config/database.ts`
3. `backend/src/modules/site/site.controller.ts`
4. `backend/src/modules/site/site.service.ts`
5. `backend/src/modules/product/product.controller.ts`
6. `backend/src/modules/product/product.service.ts`
7. `backend/tests/p0.test.cjs`
8. `backend/tests/postgres.test.cjs`
9. `backend/P0_VALIDATION.md`

## Commands and actual results

| Command / inspection | Result |
| --- | --- |
| `git --version` | 2.50.1.windows.1 |
| `node --version` / `npm --version` | v24.0.1 / 11.17.0 |
| `Get-Command flutter,dart,psql,redis-server,gh -ErrorAction SilentlyContinue` | Not found in PATH |
| `Get-Service -Name '*postgres*','*redis*' -ErrorAction SilentlyContinue` | PostgreSQL 17 service running; no Redis service returned |
| PostgreSQL executable inspection | `C:\Program Files\PostgreSQL\17\bin\psql.exe` exists |
| Initial sandboxed `git ls-remote` | Failed: restricted network proxy; retry outside sandbox succeeded |
| `git clone https://github.com/Lycorecoil/numbaa.git D:\Projects\NUMBAA` | Succeeded; destination did not previously exist |
| `git status --short --branch` / `git log -1` | Clean initial main; base SHA above |
| `git switch -c fix/builder-security-p0` | Succeeded |
| `npm ci` (backend) | Succeeded: 323 packages installed, 324 audited |
| Initial sandboxed `npm run build` | Failed with EPERM creating dist outside writable roots |
| `npm run build` outside sandbox | Succeeded, no TypeScript errors |
| `npm test` outside sandbox | Build succeeded; 26 tests passed, 0 failed; 1 PostgreSQL integration suite skipped because TEST_DATABASE_URL is unset |
| `psql -X -w -h localhost -U postgres -d postgres -c 'SELECT version();'` | Connection reached PostgreSQL; authentication failed: no password supplied. No database writes performed |
| `npm audit --json` outside sandbox | 18 existing findings: 7 moderate, 10 high, 1 critical (proxy-addr). Dependency remediation remains outside this P0 change |
| `git diff --check` | Passed (Git may report LF/CRLF normalization warning) |
| Diff and API call-site review | Only the nine files listed above; no Flutter, routes, schema, framework, deployment configuration or secrets changed |

The initial audit invocation inside the network sandbox returned zero findings; this is not used as evidence. The network-enabled audit and npm ci both reported the 18 findings above.

## Automated scenarios

The 26 passing tests use mocked database/Blob dependencies and exercise the real services and controllers:

- Owner site creation; foreign/missing business rejection before insertion; missing identity; authenticated identity forwarding and response shape.
- Product mutations bind both IDs; authorized update/deletion; cross-site update/deletion/upload return 404; denied site ownership stops all three operations before mutation or external transfer.
- Authorized upload order and scoped image update; concurrent target deletion returns 404.
- Successful transaction uses one client, commits and releases; BEGIN/work/COMMIT failures roll back and release; rollback failure discards; acquisition failure never starts work.
- Creation and section replacement roll back on simulated section insertion error; clearing sections commits; missing site causes no section mutation; deletion uses a single cascading statement.

Mocks establish control flow and query scoping, not PostgreSQL persistence. Absence of partially persisted data remains unverified in this environment.

## Running PostgreSQL integration tests

Provide `TEST_DATABASE_URL` through the shell/secret manager for a **dedicated disposable PostgreSQL database**, then run `npm test` from backend. Do not commit credentials. PostgreSQL 13+ provides the built-in `gen_random_uuid()` used by the migration.

The integration suite creates a unique schema, applies the actual initial table definitions (without installing the pgcrypto extension), uses a pool limited to one connection, then drops its own schema in `finally`. The test user needs CREATE permission on the test database. It does not require Redis or Vercel credentials.

It checks real successful commits, creation failure with zero persisted sites/sections, update rollback preserving original fields and sections, cross-site product isolation, authorized mutations, connection reuse after failure and cascading deletion. These seven integration scenarios were **not executed** here because no test credentials were supplied.

## Remaining review and limitations

- Run the PostgreSQL suite with dedicated test credentials before merge; Redis/JWT session integration and Flutter runtime checks were not run (Redis/Flutter/Dart unavailable).
- Review the existing dependency vulnerabilities separately. No dependency upgrades were made.
- A product deleted concurrently after the pre-upload check may leave an unused Blob object; the scoped database write cannot modify a different site's product and returns 404. Blob/database distributed atomicity is not part of this P0 pack.
- Valid routes and JSON response fields are preserved. Deleting an absent/cross-site product now explicitly returns 404 rather than unconditional success.
- Human review should confirm the deployed schema retains migration 001's cascading foreign keys and validate the 401/403/404 behavior with real authenticated sessions.
- No production deployment or merge was performed. All commits are restricted to the work branch; main remains at the base SHA.

## Publication and external blocker

- Implementation commit: `f618fcbde14e8984f2eae3ae3dbf22b7442ebeb8`.
- `git push -u origin fix/builder-security-p0` succeeded; branch published and tracking origin.
- GitHub connector PR creation was attempted with the requested title, head and base, including validation evidence and remaining risks. GitHub returned **403 Resource not accessible by integration**. No PR was created by this attempt; no restriction was bypassed.
- Remaining action: an authorized user/integration must open the PR from `fix/builder-security-p0` to `main`: https://github.com/Lycorecoil/numbaa/compare/main...fix/builder-security-p0?expand=1
- Requested PR title: `fix(P0): secure builder ownership, product isolation and DB transactions`.
- The complete description submitted with the failed request covered SEC-01, SEC-02, DATA-01, all nine files, actual test outcomes and the review points above. This report can be used to prepare the PR manually.
