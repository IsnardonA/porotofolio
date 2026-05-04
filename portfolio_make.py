import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ENV_FILE = ROOT / ".env"


def load_env() -> None:
    if not ENV_FILE.exists():
        return
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        name, value = line.split("=", 1)
        os.environ[name.strip()] = value.strip()


def run_command(command: list[str], cwd: Path = ROOT) -> int:
    return subprocess.run(command, cwd=cwd, check=False).returncode


def ensure_data_dir() -> None:
    data_dir = ROOT / "data"
    data_dir.mkdir(parents=True, exist_ok=True)


def task_up() -> int:
    ensure_data_dir()
    load_env()
    return run_command(["docker", "compose", "up", "--build"], cwd=ROOT)


def task_terraform_init() -> int:
    return run_command(["terraform", "init", "-backend=false"], cwd=ROOT / "infra" / "terraform")


def task_terraform_apply() -> int:
    return run_command(["terraform", "apply", "-var=gcp_project_id=YOUR_PROJECT_ID"], cwd=ROOT / "infra" / "terraform")


def task_lint() -> int:
    return run_command([sys.executable, "-m", "flake8", "src/dlt_pipelines"], cwd=ROOT)


def main() -> int:
    parser = argparse.ArgumentParser(prog="make")
    parser.add_argument("target", nargs="?", default="up", choices=["up", "terraform-init", "terraform-apply", "lint"])
    args = parser.parse_args()

    if args.target == "up":
        return task_up()
    if args.target == "terraform-init":
        return task_terraform_init()
    if args.target == "terraform-apply":
        return task_terraform_apply()
    if args.target == "lint":
        return task_lint()

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
