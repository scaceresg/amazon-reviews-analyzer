"""Configuration loader from YAML files in `config/`.

The active environment is selected via the ``APP_ENV`` environment variable
(defaults to ``dev``). Any key from the YAML file can be overridden by setting
an environment variable with the same name in uppercase.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import yaml

CONFIG_DIR = Path(__file__).resolve().parents[2] / "config"


def load_config(env: str | None = None) -> dict[str, Any]:
    """Load the configuration for the given environment.

    Args:
        env: Environment name (``dev`` or ``prod``). Falls back to ``APP_ENV``
            or ``dev`` if not provided.

    Returns:
        Merged configuration dict (YAML values + environment variable overrides).
    """
    env = env or os.getenv("APP_ENV", "dev")
    config_path = CONFIG_DIR / f"{env}.yaml"
    if not config_path.exists():
        config_path = CONFIG_DIR / "config.example.yaml"

    with config_path.open("r", encoding="utf-8") as fp:
        config: dict[str, Any] = yaml.safe_load(fp) or {}

    for key in list(config):
        env_override = os.getenv(key.upper())
        if env_override is not None:
            config[key] = env_override

    return config
