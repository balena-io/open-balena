# usage:
# docker build -t openbalena-airgapped-devicetypes --build-arg=AWS_ACCESS_KEY_ID=$BALENA_IMAGES_S3_ACCESS_KEY_ID --build-arg=AWS_SECRET_ACCESS_KEY=$BALENA_IMAGES_S3_SECRET_ACCESS_KEY --DEVICE_TO_BUILD='[["raspberrypi3-64","~=5.2.8"], ["raspberrypi4-64","~=5.2.8"], ["jetson-tx2","~=5.2.8"], ["jetson-tx2-nx-devkit",">=2.50.0"], ["jetson-nano","~=5.2.8"]]'.

FROM python:3-alpine as downloader
RUN pip3 install --no-cache-dir --upgrade pipenv
ARG AWS_ACCESS_KEY_ID=""
ARG AWS_SECRET_ACCESS_KEY=""
ARG AWS_CONFIG_FILE=/root/.aws/config


WORKDIR /root/.aws
RUN printf "[default]]\naws_access_key_id = %s\naws_secret_access_key = %s" $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY > $AWS_CONFIG_FILE

WORKDIR /s3images
COPY Pipfile .
COPY Pipfile.lock .
RUN pipenv install
COPY downloader.py .

ARG DEVICES_TO_DOWNLOAD
RUN pipenv run python3 downloader.py "${DEVICES_TO_DOWNLOAD}"

FROM balena/open-balena-base:v18.0.1 as runtime

RUN curl -fsSL -o /sbin/mc https://dl.min.io/client/mc/release/linux-amd64/mc \
    && chmod +x /sbin/mc \
    && mkdir -p /root/.mc

# systemd and minio config
COPY config /usr/src/app/config
COPY config/services/ /etc/systemd/system/

# Enable copy devicetype service
RUN systemctl enable copy-devicetypes.service
# todo: stop this container once done

WORKDIR /s3images
COPY --from=downloader /s3images/images /s3images/images



