#!/usr/bin/env python3
"""Provision a v2 API token and test authentication against NetBox v4.5."""
import requests
import json

NETBOX_URL = "http://localhost:8000"

# Step 1: Provision token
print("Provisioning token...")
resp = requests.post(
    f"{NETBOX_URL}/api/users/tokens/provision/",
    json={"username": "admin", "password": "admin"},
    timeout=10,
)
resp.raise_for_status()
data = resp.json()
key = data["key"]
token = data["token"]
bearer = f"{key}.{token}"
print(f"Key: {key}")
print(f"Token: {token}")
print(f"Bearer: {bearer}")
print(f"Version: {data['version']}")

# Step 2: Test with Bearer format (v2)
print("\n--- Testing Bearer key.token ---")
r = requests.get(
    f"{NETBOX_URL}/api/status/",
    headers={"Authorization": f"Bearer {bearer}"},
    timeout=10,
)
print(f"Status: {r.status_code}")
print(f"Response: {r.text[:200]}")

# Step 3: Test with Token format (v1)
print("\n--- Testing Token <token> ---")
r = requests.get(
    f"{NETBOX_URL}/api/status/",
    headers={"Authorization": f"Token {token}"},
    timeout=10,
)
print(f"Status: {r.status_code}")
print(f"Response: {r.text[:200]}")

# Step 4: Save working token to config
if r.status_code == 200 or requests.get(
    f"{NETBOX_URL}/api/status/",
    headers={"Authorization": f"Bearer {bearer}"},
    timeout=10,
).status_code == 200:
    print(f"\nWORKING_BEARER={bearer}")
    print(f"WORKING_TOKEN={token}")
