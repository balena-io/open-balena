# based on https://forums.balena.io/t/supported-devices-in-open-balena/357665/21
# As of 04/June/2024 openbalena claims to requires at least v5.2.8: https://github.com/balena-io/open-balena?tab=readme-ov-file#compatibility.
# However, this might not be 100% true, e.g. the jetson-tx2-nx-devkit have been tested to work with 2.113.

import asyncio
import boto3
import os
import json
import sys
from packaging.version import Version
from packaging.specifiers import SpecifierSet


# AWS credentials are taken from $AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# See https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html for options
bucket_name = "resin-production-img-cloudformation"

# Initialize AWS S3 client
s3 = boto3.client("s3")

async def download_object(obj_key, download_path):
    dirpath = os.path.dirname(download_path)
    try:
        os.makedirs(dirpath, exist_ok=True)
    except:
        print(f"Failed to download {obj_key} due to {exc}")
    try:
        await asyncio.to_thread(s3.download_file, bucket_name, obj_key, download_path)
        print(f"Downloaded {obj_key}")
    except Exception as exc:
        print(f"Failed to download {obj_key} due to {exc}")


def filter_objects(device_type, spec, page, background_tasks):
    for obj in page["Contents"]:
        if obj["Key"].rsplit("/", 1)[-1] == "device-type.json":
            version_str = obj["Key"].rsplit("/", 2)[1]
            try:
                if Version(version_str) in spec:
                    download_path = f"{obj['Key']}"
                    task = asyncio.create_task(download_object(obj["Key"], download_path))
                    background_tasks.add(task)
                    task.add_done_callback(background_tasks.discard)
                    print("scheduled downloads: ", len(background_tasks))
            except:
                print(f"Failed to parse version {version_str} for device {device_type}")


async def main(json_input):
    background_tasks = set()
    devices_types_with_versionspec = json.loads(json_input)
    for device_type, device_version_spec in devices_types_with_versionspec:
        paginator = s3.get_paginator("list_objects_v2")
        prefix = ""
        if device_type == "":
            prefix = "images/"
        else:
            prefix = f"images/{device_type}/"
        pages = paginator.paginate(Bucket=bucket_name, MaxKeys=10000, Prefix=prefix)
        try:
            spec = SpecifierSet(device_version_spec)
        except:
            print(f"Failed to parse version specifier {device_version_spec} for device {device_type}")
        for page in pages:
            filter_objects(device_type, spec, page, background_tasks)
    while len(background_tasks) > 0:
        print("ongoing downloads: ", len(background_tasks))
        await asyncio.sleep(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            'Usage: \nexport AWS_ACCESS_KEY_ID=<your_key_id> && export AWS_SECRET_ACCESS_KEY=<your_access_key>\npython script.py \'[["raspberrypi3-64","~=5.2.8"], ["raspberrypi4-64","~=5.2.8"]]\'\nSee https://peps.python.org/pep-0440/#compatible-release for versionspec syntax '
        )
        sys.exit(1)
    json_input = sys.argv[1]
    asyncio.run(main(json_input))
