#!/usr/bin/env python3
"""Populate NetBox via Django ORM (run inside the container)."""
import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'netbox.settings')
django.setup()

from dcim.models import Region, Site, Manufacturer, DeviceRole, DeviceType, Rack, Device
from ipam.models import VLAN, Prefix, IPAddress

# Regions
for name, slug in [('Asia Pacific','apac'),('North America','na'),('Europe','eu')]:
    Region.objects.get_or_create(name=name, slug=slug)
print('Regions: OK')

# Sites
for name, slug, status, reg, fac in [
    ('Chennai DC1','chennai-dc1','active','apac','Equinix CH1'),
    ('Mumbai DC1','mumbai-dc1','active','apac','NTT Mumbai'),
    ('US-East DC1','us-east-dc1','active','na','Equinix DC5'),
    ('London DC1','london-dc1','planned','eu','Telehouse North'),
]:
    region = Region.objects.get(slug=reg)
    Site.objects.get_or_create(name=name, slug=slug, defaults={'status':status,'region':region,'facility':fac})
print('Sites: OK')

# Manufacturers
for name, slug in [('Cisco','cisco'),('Juniper','juniper'),('Arista','arista'),('Dell','dell'),('Palo Alto','paloalto')]:
    Manufacturer.objects.get_or_create(name=name, slug=slug)
print('Manufacturers: OK')

# Device Roles
for name, slug in [('Router','router'),('Switch','switch'),('Firewall','firewall'),('Server','server'),('AP','ap')]:
    DeviceRole.objects.get_or_create(name=name, slug=slug)
print('Device Roles: OK')

# Device Types
for mfr_slug, model, slug, height in [
    ('cisco','Catalyst 9300','c9300',1),('cisco','ISR 4451','isr4451',2),
    ('juniper','EX4300','ex4300',1),('arista','DCS-7050TX','dcs7050tx',1),
    ('paloalto','PA-3260','pa3260',2),('dell','PowerEdge R750','r750',2),
    ('cisco','Catalyst 9800','c9800',1),
]:
    mfr = Manufacturer.objects.get(slug=mfr_slug)
    DeviceType.objects.get_or_create(manufacturer=mfr, model=model, slug=slug, defaults={'u_height':height})
print('Device Types: OK')

# Racks
for name, site_slug, height in [('RACK-A01','chennai-dc1',42),('RACK-A02','chennai-dc1',42),
                                  ('RACK-B01','mumbai-dc1',42),('RACK-C01','us-east-dc1',48)]:
    site = Site.objects.get(slug=site_slug)
    Rack.objects.get_or_create(name=name, site=site, defaults={'status':'active','u_height':height})
print('Racks: OK')

# Devices
for name, site_slug, dtype_slug, role_slug in [
    ('CHN-RTR-01','chennai-dc1','isr4451','router'),('CHN-SW-01','chennai-dc1','c9300','switch'),
    ('CHN-SW-02','chennai-dc1','c9300','switch'),('CHN-FW-01','chennai-dc1','pa3260','firewall'),
    ('MUM-RTR-01','mumbai-dc1','isr4451','router'),('MUM-SW-01','mumbai-dc1','ex4300','switch'),
    ('USE-RTR-01','us-east-dc1','isr4451','router'),('USE-SW-01','us-east-dc1','dcs7050tx','switch'),
    ('CHN-SRV-01','chennai-dc1','r750','server'),('CHN-WLC-01','chennai-dc1','c9800','ap'),
]:
    site = Site.objects.get(slug=site_slug)
    dtype = DeviceType.objects.get(slug=dtype_slug)
    role = DeviceRole.objects.get(slug=role_slug)
    Device.objects.get_or_create(name=name, defaults={'site':site,'device_type':dtype,'role':role,'status':'active'})
print('Devices: OK')

# VLANs
for vid, name, site_slug in [(100,'Management','chennai-dc1'),(200,'Servers','chennai-dc1'),
    (300,'Users','chennai-dc1'),(100,'Management','mumbai-dc1'),(200,'Servers','mumbai-dc1'),(400,'Guest','chennai-dc1')]:
    site = Site.objects.get(slug=site_slug)
    VLAN.objects.get_or_create(vid=vid, name=name, site=site, defaults={'status':'active'})
print('VLANs: OK')

# Prefixes
for prefix, site_slug in [('10.1.0.0/16','chennai-dc1'),('10.2.0.0/16','mumbai-dc1'),('10.3.0.0/16','us-east-dc1'),
    ('10.1.1.0/24','chennai-dc1'),('10.1.2.0/24','chennai-dc1'),('10.2.1.0/24','mumbai-dc1'),
    ('172.16.0.0/12',None),('192.168.1.0/24',None)]:
    site = Site.objects.get(slug=site_slug) if site_slug else None
    Prefix.objects.get_or_create(prefix=prefix, defaults={'site':site,'status':'active'})
print('Prefixes: OK')

# IP Addresses
for addr in ['10.1.1.1/24','10.1.1.2/24','10.1.1.3/24','10.1.1.4/24',
             '10.2.1.1/24','10.2.1.2/24','10.3.1.1/24','10.3.1.2/24']:
    IPAddress.objects.get_or_create(address=addr, defaults={'status':'active'})
print('IP Addresses: OK')

print('\n=== ALL DATA POPULATED SUCCESSFULLY ===')
