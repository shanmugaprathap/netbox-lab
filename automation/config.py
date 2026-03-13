"""NetBox connection configuration."""

import os

NETBOX_URL = os.environ.get("NETBOX_URL", "http://localhost:8000")
NETBOX_TOKEN = os.environ.get("NETBOX_TOKEN", "0ziJQ0XHGruTT6uzGi9knLwW8WQDDh8JTENVd9bi")
