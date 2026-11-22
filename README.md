# CPPminer cluster image

Overlay for building [1640675651/CPPminer](https://github.com/1640675651/CPPminer) (MIT) into
`ghcr.io/tanguille/cppminer` for an RTX 2070 (sm_75). The workflow runs daily, takes the newest
upstream `vX.Y` tag, disables the developer fee (`cp_fee_init(..., 0, ...)` in `main.cpp`) and
pushes `<version>` (upstream sha in the `org.opencontainers.image.revision` label) if that tag is not already in ghcr. No upstream code is
stored here. Upstream's MIT license ships in the image at `/usr/share/doc/cppminer/LICENSE`.
