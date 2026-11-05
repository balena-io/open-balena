# Migrating to openBalena v5 (device types)

## TL;DR

openBalena **v5** changes how the API resolves device types. It now fetches them from a
URL (`DEVICE_TYPES_V1_PROXY_URL`) and no longer scans balenaOS build artifacts in the
image S3 bucket. We had to make this change since we plan to stop publishing balenaOS
releases to the legacy image bucket that older openBalena versions read, and then turn
that bucket off.

| Your setup | Deadline | What to do |
| --- | --- | --- |
| Default balena bucket, want **new** OS releases | **<BUCKET_PUBLISHING_END_DATE>** | [Upgrade to openBalena ≥ v5](#you-use-the-default-balena-bucket) |
| Default balena bucket, want **any** OS releases or to **provision new devices** | **<LEGACY_BUCKET_SHUTDOWN_DATE>** | [Upgrade to openBalena ≥ v5](#you-use-the-default-balena-bucket) |
| Custom `IMAGE_STORAGE_BUCKET` | Before you upgrade to v5 | [Serve your device type list from a static URL](#you-use-a-custom-s3-bucket) |

> [!WARNING]
> After **<LEGACY_BUCKET_SHUTDOWN_DATE>**, openBalena instances that still rely on the
> legacy image bucket cannot resolve device types and therefore cannot generate a
> `config.json`, so they **cannot provision new devices**. To avoid this, migrate in one of the ways described below.

## What changed

Before v5, the API built its device type list by scanning
`<IMAGE_STORAGE_BUCKET>/images/<slug>/<version>/device-type.json` in S3.

Starting with v5, the API fetches the list from the URL set in the
`DEVICE_TYPES_V1_PROXY_URL` environment variable of the `api` service. That URL must
return a JSON array of device type objects, in the same format as balenaCloud's
`/device-types/v1` endpoint. By default, v5 points it at balenaCloud:

```yaml
DEVICE_TYPES_V1_PROXY_URL: https://api.balena-cloud.com/device-types/v1
```

This was introduced in
[open-balena-api#2447](https://github.com/balena-io/open-balena-api/pull/2447)
(open-balena-api v50.1.0).

## Timeline

- **<RELEASE_DATE>**: openBalena v5.0.0 is released.
- **<BUCKET_PUBLISHING_END_DATE>**: We stop publishing new balenaOS releases to the legacy image
  bucket. openBalena < v5 instances will not be able to fetch any new balenaOS release published
  after this date.
- **<LEGACY_BUCKET_SHUTDOWN_DATE>**: The legacy bucket is turned off. openBalena < v5
  instances that rely on it will not be able to resolve **any** balenaOS release or device type.
  As a result their `/device-types/v1` endpoints will either return no results or fail.
  This also means that a `config.json` can no longer be generated (for example with
  `balena config generate` or `balena os configure`), so **no new devices can be
  provisioned** on those instances.

## Who is affected and what to do

### You use the default balena bucket

This applies to you if you never changed `IMAGE_STORAGE_BUCKET`, which defaults to
`resin-production-img-cloudformation`.

| Date | What happens if you are still on openBalena < v5 |
| --- | --- |
| **<BUCKET_PUBLISHING_END_DATE>** | No **new** balenaOS releases appear. Existing releases keep working. |
| **<LEGACY_BUCKET_SHUTDOWN_DATE>** | **No** balenaOS releases are available, not even existing ones. You can no longer generate a `config.json`, so you **cannot provision new devices**. |

**Action:** upgrade to openBalena v5 or newer before **<BUCKET_PUBLISHING_END_DATE>**, and no
later than **<LEGACY_BUCKET_SHUTDOWN_DATE>**:

```bash
make update
```

You don't need to change any configuration, because the default
`DEVICE_TYPES_V1_PROXY_URL` already points to balenaCloud. As with any major upgrade,
consider deploying v5 in parallel first and pointing a test device at it. See
[Compatibility](../README.md#compatibility).

### You use a custom S3 bucket

This applies to you if you override `IMAGE_STORAGE_BUCKET` to host your own balenaOS
builds or device types.

**This is a breaking change for you.** Once you upgrade to v5, the API ignores the
`device-type.json` files in your bucket when it builds the device type list. If you
upgrade without changing anything, you'll get balenaCloud's device types instead of
your own.

**Action:** before you upgrade, publish your device type list as a static JSON file and
point `DEVICE_TYPES_V1_PROXY_URL` at it:

1. Build a single JSON **array** with one object per device type. Use the contents of
   each `images/<slug>/<latest-version>/device-type.json` that you currently host. This
   is the same shape as `GET https://api.balena-cloud.com/device-types/v1`. Each object
   needs a `slug`. `aliases` are honoured too.
2. Serve that file at a stable URL that the `api` container can reach, for example
   using nginx, a static website on your S3/MinIO bucket, or any other static file host.
   The API fetches the URL exactly as configured and doesn't append any path. It
   caches the response.
3. Set `DEVICE_TYPES_V1_PROXY_URL` on the `api` service to that URL. Use a
   `docker-compose.override.yml` file, or a service variable when you deploy on
   balenaCloud. An entry in `.env` does **not** work, because `docker-compose.yml` sets
   this variable explicitly.
4. Update the file whenever you publish a new device type or balenaOS version.

Example `docker-compose.override.yml`:

```yaml
services:
  api:
    environment:
      DEVICE_TYPES_V1_PROXY_URL: https://files.example.com/device-types/v1
```

Example nginx location:

```nginx
location = /device-types/v1 {
    default_type application/json;
    alias /srv/openbalena/device-types.json;
}
```

The `IMAGE_STORAGE_*` settings are still required, so keep them configured. They will be
dropped in a later version.

## Questions

Please ask in the [openBalena forums](https://forums.balena.io/c/open-balena).
