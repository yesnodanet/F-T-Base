# Workshop reference snapshots

These directories are immutable compatibility references, not Garry's Mod addon
roots. They intentionally live outside `lua/`, so Garry's Mod does not discover
or execute their autorun scripts or original weapon bases. Do not add this
directory to `lua/ft_base/bootstrap.lua`.

Each numeric directory contains:

- the source's original relative paths and payload files;
- `MANIFEST.sha256`, sorted by slash-normalized relative path;
- `SNAPSHOT.json`, recording the Workshop identity, payload size/count, and the
  digest of `MANIFEST.sha256`.

Re-import all six snapshots from a gmpublisher extraction with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\vendor\import_workshop_snapshots.ps1 -SourceRoot 'C:\Users\ameri\AppData\Local\Temp\gmpublisher'
```

The importer fails if any required source is missing. It replaces payload paths
from the source, then deterministically regenerates metadata. Binary assets are
tracked through Git LFS according to the repository `.gitattributes`; Lua, JSON,
and manifests remain normal Git text for inspection.

Verify every payload file against the recorded manifests with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\vendor\verify_workshop_snapshots.ps1
```

See `THIRD_PARTY_NOTICES.md` for inventory, authorship information found in the
supplied material, and the publication statement.
