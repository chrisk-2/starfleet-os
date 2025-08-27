
# Starfleet OS Deployer

Turn-key GitHub-driven installs for your **Server**, **Control**, and **Drone** nodes.

## What you get

- **Two paths**:
  - **A) Custom ISO (CI-built):** Boot and it auto-clones this repo and runs the right role installer.
  - **B) Stock Arch ISO + one-liner:** From a vanilla Arch live ISO, run one command to clone and go.

- **Roles**: `server`, `control`, `drone` with isolated setup scripts and shared modules.
- **First-boot** systemd units finalize provisioning and pull updates from this repo.
- **Idempotent**: Safe to re-run; scripts check state before changing anything.

## Quick start (Path B: Stock ISO + one-liner)

Boot any **Arch Linux** live ISO, get online, then:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GH_USER/starfleet-os-deployer/main/scripts/bootstrap.sh) drone
```

Replace `drone` with `server` or `control`.

## Quick start (Path A: Custom ISO)

- Push to `main`. GitHub Actions builds a custom Arch ISO and uploads it as a Release named **Starfleet-OS-ISO**.
- Download the ISO from the release page, write it to USB, boot, and pick your role at boot menu or let it auto-run `drone`.

## Repo layout

```
archiso/                 # Custom ArchISO profile
archinstall/             # Unattended archinstall configs (optional path)
roles/                   # Role installers
scripts/                 # Shared helpers and bootstrap
system/                  # systemd units and first-boot
.github/workflows/       # CI builds the ISO and publishes release
```

---

**Pro-tip**: Keep secrets out of the repo. Use environment variables, CI secrets, or fetch from your secure store at runtime.
