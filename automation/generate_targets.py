#!/usr/bin/env python3
"""Generate Prometheus file-based service discovery targets from NetBox.

Run inside NetBox container:
  docker compose exec -T netbox python /opt/netbox/netbox/manage.py shell < /tmp/generate_targets.py
"""
import json
from dcim.models import Device
from virtualization.models import VirtualMachine

targets = []

# Physical devices with primary IPs
for device in Device.objects.filter(status='active', primary_ip4__isnull=False):
    ip = str(device.primary_ip4.address.ip)
    targets.append({
        "targets": [f"{ip}:9100"],
        "labels": {
            "job": "netbox-devices",
            "device": device.name,
            "site": device.site.slug,
            "role": device.role.slug,
            "device_type": device.device_type.model,
        }
    })

# Virtual machines
for vm in VirtualMachine.objects.filter(status='active', primary_ip4__isnull=False):
    ip = str(vm.primary_ip4.address.ip)
    targets.append({
        "targets": [f"{ip}:9100"],
        "labels": {
            "job": "netbox-vms",
            "vm": vm.name,
            "cluster": vm.cluster.name if vm.cluster else "",
        }
    })

print(json.dumps(targets, indent=2))
