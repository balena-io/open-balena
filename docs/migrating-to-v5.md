# Migrating to openBalena v5.0.0 (device types)

**TL;DR:** Upgrade to openBalena v5.0.0 to keep receiving balenaOS releases and provisioning new devices. If you host your own S3 bucket or custom builds,
[serve your device type list from a URL](#you-use-a-custom-s3-bucket-or-custom-builds)
before you upgrade.

| Your setup | Act before | What to do |
| --- | --- | --- |
| Default bucket, want **new** balenaOS releases | **January 2027** | [Upgrade to openBalena v5.0.0](#you-use-the-default-bucket) |
| Default bucket, want **any** balenaOS release or to **provision new devices** | **July 2027** | [Upgrade to openBalena v5.0.0](#you-use-the-default-bucket) |
| Restricted or air-gapped network | Before you upgrade | [Allow access to balenaCloud or host your own endpoint](#you-run-on-a-restricted-or-air-gapped-network) |
| Custom `IMAGE_STORAGE_BUCKET` or custom builds | Before you upgrade | [Serve your device type list from a URL](#you-use-a-custom-s3-bucket-or-custom-builds) |

## Timeline

- **From January 2027:** new balenaOS releases may stop appearing in the S3 bucket
  openBalena currently reads from. openBalena releases older than v5.0.0 may not see
  balenaOS releases published after this date.
- **From July 2027:** the bucket will be made private. openBalena releases older than
  v5.0.0 that rely on it will not be able to resolve **any** balenaOS release or device
  type. Their `/device-types/v1` endpoint will return no results or fail, so a
  `config.json` can no longer be generated (for example with `balena config generate`
  or `balena os configure`) and **no new devices can be provisioned**.

## What changed

Before openBalena v5.0.0, the API built its device type list by scanning
`<IMAGE_STORAGE_BUCKET>/images/<slug>/<version>/device-type.json` in S3.

From openBalena v5.0.0, the API fetches the list from the URL in the
`DEVICE_TYPES_V1_PROXY_URL` environment variable of the `api` service. The URL must
return a JSON array of device type objects, in the same format as balenaCloud's
`/device-types/v1` endpoint. By default it points at balenaCloud:

```yaml
DEVICE_TYPES_V1_PROXY_URL: https://api.balena-cloud.com/device-types/v1
```

The pipeline that builds balenaOS also publishes this list, so openBalena stays current
without a separate upload. The variable was added in open-balena-api v50.1.0
([open-balena-api#2447](https://github.com/balena-io/open-balena-api/pull/2447)).

## What to do

### You use the default bucket

This is you if you never changed `IMAGE_STORAGE_BUCKET`.

**Action:** upgrade to openBalena v5.0.0 or newer, ideally before January 2027 and no
later than July 2027:

```bash
make update
```

No configuration change is needed. As with any major upgrade, consider deploying
openBalena v5.0.0 in parallel first and pointing a test device at it. See
[Compatibility](../README.md#compatibility).

### You run on a restricted or air-gapped network

The default setup adds a runtime dependency on balenaCloud: the `api` container must be
able to reach `https://api.balena-cloud.com` over HTTPS.

**Action:** before you upgrade, either allow outbound HTTPS from the `api` container to
`api.balena-cloud.com`, or host your own endpoint as described in the
[next section](#you-use-a-custom-s3-bucket-or-custom-builds).

### You use a custom S3 bucket or custom builds

This is you if you override `IMAGE_STORAGE_BUCKET` to host your own balenaOS builds or
device types.

**This is a breaking change for you.** From openBalena v5.0.0, the API ignores the
`device-type.json` files in your bucket. If you upgrade without changing anything, you
get balenaCloud's device types instead of your own.

**Action:** before you upgrade, publish your device type list at a URL and point
`DEVICE_TYPES_V1_PROXY_URL` at it:

1. Build one JSON **array** with one object per device type, using each
   `images/<slug>/<latest-version>/device-type.json` you host today. This is the same
   shape as `GET https://api.balena-cloud.com/device-types/v1`. Each object needs a
   `slug`; `aliases` are honoured too.
2. Serve the file at a stable URL the `api` container can reach, for example with
   nginx, a static website on your S3/MinIO bucket, or any static file host. The API
   fetches the URL exactly as configured, without appending a path, and caches the
   response.
3. Set `DEVICE_TYPES_V1_PROXY_URL` on the `api` service, using a
   `docker-compose.override.yml` file or a service variable on balenaCloud. Setting it in
   `.env` does **not** work, because `docker-compose.yml` sets this variable explicitly.
4. Update the file whenever you publish a new device type or balenaOS version. You
   maintain this endpoint from then on.

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

Keep your `IMAGE_STORAGE_*` settings configured. They are still required and will be
removed in a later version.

### You can't upgrade yet

If you run open-balena-api v50.1.0 or later, you can set `DEVICE_TYPES_V1_PROXY_URL`
yourself without upgrading openBalena. Otherwise, plan to upgrade before July 2027.

## Questions

Please ask in the [openBalena forums](https://forums.balena.io/c/open-balena).
