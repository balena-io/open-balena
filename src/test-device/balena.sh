#!/usr/bin/env bash

set -ae

[[ $VERBOSE =~ on|On|Yes|yes|true|True ]] && set -x

function cleanup() {
   rm -f "${tmpimg}"

   # crash loop backoff
   sleep "$(( (RANDOM % 5) + 5 ))s"
}
trap 'cleanup' EXIT

if [[ "$PRODUCTION_MODE" =~ true ]]; then
    exit
fi

until test -f "${GUEST_IMAGE%.*}.ready"; do sleep "$(( (RANDOM % 5) + 5 ))s"; done

tmpimg="$(mktemp)"
cat <"${GUEST_IMAGE}" >"${tmpimg}"

# https://www.qemu.org/docs/master/system/qemu-manpage.html
# .. depending on the target architecture: kvm, xen, hvf, nvmm, whpx (default: tcg)
if test -r /dev/kvm && test -w /dev/kvm; then
    accel=kvm
fi

exec /usr/bin/qemu-system-x86_64 \
  -accel "${accel:-tcg}" \
  -bios /usr/share/ovmf/OVMF.fd \
  -chardev socket,id=serial0,path=/run/console.sock,server=on,wait=off \
  -cpu max \
  -device ahci,id=ahci \
  -device ide-hd,drive=disk,bus=ahci.0 \
  -device virtio-net-pci,netdev=n1 \
  -drive file="${tmpimg}",media=disk,cache=none,format=raw,if=none,id=disk \
  -m "${MEMORY}" \
  -machine type=q35 \
  -netdev "user,id=n1,dns=127.0.0.1,guestfwd=tcp:10.0.2.100:80-cmd:netcat haproxy 80,guestfwd=tcp:10.0.2.100:443-cmd:netcat haproxy 443" \
  -nodefaults \
  -nographic \
  -serial chardev:serial0 \
  -smp "${CPU}"
