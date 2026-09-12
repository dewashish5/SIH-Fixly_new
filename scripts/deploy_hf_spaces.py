#!/usr/bin/env python3
"""Push Fixly ML Docker Spaces to Hugging Face. Needs HF PRO (or eligible ZeroGPU later)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

from huggingface_hub import HfApi, whoami

ROOT = Path(__file__).resolve().parents[1]
TOKEN = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_HUB_TOKEN")
if not TOKEN:
    sys.exit("Set HF_TOKEN")

api = HfApi(token=TOKEN)
me = whoami(token=TOKEN)
print(f"user={me.get('name')} isPro={me.get('isPro')}")

SPACES = [
    {
        "repo_id": f"{me['name']}/fixly-service-discovery",
        "folder": ROOT / "ai_ml" / "service_discovery",
        "files": [
            ("Dockerfile", "Dockerfile"),
            ("requirements.txt", "requirements.txt"),
            ("discovery_api.py", "discovery_api.py"),
            ("service_classifier.pkl", "service_classifier.pkl"),
            ("vectorizer.pkl", "vectorizer.pkl"),
            ("README_HF.md", "README.md"),
        ],
    },
    {
        "repo_id": f"{me['name']}/fixly-identity-verification",
        "folder": ROOT / "ai_ml" / "identity_verification",
        "files": [
            ("Dockerfile", "Dockerfile"),
            ("requirements.txt", "requirements.txt"),
            ("app.py", "app.py"),
            ("README_HF.md", "README.md"),
        ],
    },
]


def deploy(space: dict) -> str:
    repo_id = space["repo_id"]
    try:
        api.create_repo(
            repo_id=repo_id,
            repo_type="space",
            space_sdk="docker",
            private=False,
            exist_ok=True,
        )
    except Exception as e:
        err = str(e)
        if "402" in err or "PRO" in err:
            print(
                "HF Docker Spaces need PRO (or eligible free ZeroGPU later).\n"
                "Subscribe: https://huggingface.co/pro\n"
                "Then re-run: HF_TOKEN=... python3 scripts/deploy_hf_spaces.py"
            )
        print(f"CREATE FAIL {repo_id}: {e}")
        raise
    folder = space["folder"]
    for src_name, dest_name in space["files"]:
        path = folder / src_name
        if not path.exists():
            raise FileNotFoundError(path)
        api.upload_file(
            path_or_fileobj=str(path),
            path_in_repo=dest_name,
            repo_id=repo_id,
            repo_type="space",
            token=TOKEN,
        )
        print(f"  uploaded {dest_name}")
    return f"https://huggingface.co/spaces/{repo_id}"


def main() -> None:
    urls = []
    for space in SPACES:
        print(f"==> {space['repo_id']}")
        urls.append(deploy(space))
    print("\nDone:")
    for u in urls:
        print(" ", u)
    print("\nAPI bases (after build):")
    print(f"  https://{me['name']}-fixly-service-discovery.hf.space")
    print(f"  https://{me['name']}-fixly-identity-verification.hf.space")


if __name__ == "__main__":
    main()
