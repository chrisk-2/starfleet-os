.
├── archiso/
│   ├── base/                      # your base ArchISO profile (templates)
│   │   ├── profiledef.sh
│   │   ├── packages.x86_64
│   │   ├── pacman.conf
│   │   └── airootfs/              # optional base overlay
│   └── profiles/
│       └── starfleet/             # composed output (generated)
├── roles/
│   ├── server/
│   │   ├── packages.txt
│   │   └── overlay/               # airootfs overlay for server
│   ├── control/
│   │   ├── packages.txt
│   │   └── overlay/
│   └── drone/
│       ├── packages.txt
│       └── overlay/
├── scripts/
│   ├── verify_repo.sh
│   ├── merge_role.sh
│   └── build_iso_local.sh
├── system/
│   └── firstboot/
│       ├── starfleet-firstboot.service
│       └── starfleet-firstboot.sh
└── .github/workflows/build-iso.yml
