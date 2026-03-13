#!/usr/bin/env python3
"""
Bulk import data into NetBox from CSV files.

Reads CSV files from the data/ directory and imports them via the REST API.
Supports: sites, devices, prefixes, ip_addresses, vlans.

Usage:
    python automation/bulk_import_csv.py data/sites.csv --object-type sites
    python automation/bulk_import_csv.py data/devices.csv --object-type devices
"""

import argparse
import csv
import sys
from pathlib import Path

import pynetbox

from config import NETBOX_URL, NETBOX_TOKEN

nb = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)

# Map object types to pynetbox endpoints
ENDPOINTS = {
    "sites": nb.dcim.sites,
    "devices": nb.dcim.devices,
    "racks": nb.dcim.racks,
    "manufacturers": nb.dcim.manufacturers,
    "device-types": nb.dcim.device_types,
    "device-roles": nb.dcim.device_roles,
    "interfaces": nb.dcim.interfaces,
    "prefixes": nb.ipam.prefixes,
    "ip-addresses": nb.ipam.ip_addresses,
    "vlans": nb.ipam.vlans,
}


def load_csv(filepath: str) -> list[dict]:
    """Load CSV file and return list of dicts."""
    path = Path(filepath)
    if not path.exists():
        print(f"ERROR: File not found: {filepath}")
        sys.exit(1)

    with path.open() as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Loaded {len(rows)} rows from {filepath}")
    return rows


def import_rows(endpoint, rows: list[dict]):
    """Import rows into the given NetBox endpoint."""
    created = 0
    skipped = 0
    errors = 0

    for i, row in enumerate(rows, 1):
        # Remove empty values
        data = {k: v for k, v in row.items() if v}

        try:
            obj = endpoint.create(data)
            print(f"  [{i}] CREATED: {obj}")
            created += 1
        except pynetbox.RequestError as e:
            if "already exists" in str(e).lower() or "must be unique" in str(e).lower():
                print(f"  [{i}] EXISTS: {data.get('name', data.get('prefix', data.get('address', '?')))}")
                skipped += 1
            else:
                print(f"  [{i}] ERROR: {e}")
                errors += 1

    print(f"\nResults: {created} created, {skipped} skipped, {errors} errors")


def main():
    parser = argparse.ArgumentParser(description="Bulk import CSV data into NetBox")
    parser.add_argument("csv_file", help="Path to CSV file")
    parser.add_argument("--object-type", required=True, choices=list(ENDPOINTS.keys()),
                        help="NetBox object type to import")
    args = parser.parse_args()

    endpoint = ENDPOINTS[args.object_type]
    rows = load_csv(args.csv_file)
    import_rows(endpoint, rows)


if __name__ == "__main__":
    main()
