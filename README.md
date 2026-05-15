# Social Media Manager

Professional social media scheduling and publishing platform.

This app is not a permanent media host. Uploaded media is temporary content used
for previewing, editing, scheduling, publishing, and retrying failed publishing.
After a post publishes successfully, media and large temporary post payloads are
retained for 15 days, then removed automatically while lightweight calendar and
analytics history remains.

## Monorepo

```text
apps/
  api/      NestJS backend, Prisma, queues, storage, publishing workers
  mobile/   Flutter Android-first mobile app
```

## Backend Direction

- NestJS modular API
- PostgreSQL with Prisma ORM
- Redis + BullMQ for publishing and cleanup jobs
- S3-compatible storage in production
- Local disk storage for development/testing
- Signed upload URLs
- Workspace-based access control
- Billing and AI modules from the beginning
- Daily retention cleanup worker

## Local Services

```sh
docker compose up -d postgres redis minio
```

MinIO console:

```text
http://localhost:9001
```

Default development credentials:

```text
minioadmin / minioadmin
```

## API

```sh
npm install
npm run api:prisma:generate
npm run api:build
npm run api:dev
```

Copy `apps/api/.env.example` to `apps/api/.env` for local development.

## Hosted Development

The repository includes `render.yaml` for a no-card hosted development path on
Render:

- `social-media-manager-api`: NestJS API web service
- `social-media-manager-db`: Render PostgreSQL database
- `social-media-manager-queue`: Render Key Value service for BullMQ jobs

Render injects `DATABASE_URL`, `REDIS_URL`, and `JWT_ACCESS_SECRET`. Cloudflare
R2 is configured manually with the S3-compatible variables below:

```text
STORAGE_DRIVER=minio
MINIO_ENDPOINT=<account-id>.r2.cloudflarestorage.com
MINIO_PORT=
MINIO_ACCESS_KEY=<r2-access-key-id>
MINIO_SECRET_KEY=<r2-secret-access-key>
MINIO_BUCKET=<private-bucket-name>
MINIO_USE_SSL=true
```

The API deploy command runs Prisma migrations and seeds the Free, Pro, and
Business subscription plans before starting the server.

## Mobile

```sh
cd apps/mobile
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
```

The mobile app is currently the Android-first shell. It will be reconnected to
the NestJS API as the backend modules become available.
