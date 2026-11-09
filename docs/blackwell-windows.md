# Blackwell tensor integration and Windows validation

This is an integration and validation branch of CPPminer, based on upstream
`5b68506af5e6433ee5c25aa9e6fbb00b537590aa`. The accelerated kernels are the work of
**MIKHAIL SERGEEV (`danifest751`)**. The upstream MIT license and copyright
notice remain in [LICENSE](../LICENSE). The upstream 1% developer fee is retained.

## Source provenance

The following upstream PR stack was applied without conflicts:

- [#12](https://github.com/1640675651/CPPminer/pull/12): tensor-op fused CUDA.
- [#23](https://github.com/1640675651/CPPminer/pull/23): Ampere multistage kernel.
- [#24](https://github.com/1640675651/CPPminer/pull/24): threadblock/milestone tuning.
- [#33](https://github.com/1640675651/CPPminer/pull/33): packed operands, including sm_12x.

Original stack base: `3abf3017c6791813cc6fef22ca822229433695ed`.
Original stack head: `99ce785a4826ffb52ac17e3cc9b846949c88b624`.
All 14 commits are by MIKHAIL SERGEEV. The integration commit retains that author
and lists every original commit ID in its message:

```text
313325c38018010dbd39a57c871a4aed4e6dfa1e
1c60a37460de4ec1f8fd162abe277442a566f76c
6c8d1e68f8fcb5ce932c8fb38e0d6a9ad77d1aeb
6076d85801b537cc268b5d3fffbc95798d1585af
26b495258a25a8e5b8d19a8e64d2156a3328aee5
049df158c605855a3f99883c36f7530756a0e290
878dc895cea61df0a1ef7f5aca588db56bb87eac
294fcaea931c8b0259e24e1b528d9b80068ef1e2
e1b5ecbeb2cbdad0ef142a8f10bec08055fd7635
34ee4af0aeca542ca3cfb402ae7b8f5e2507e268
eec928611789fdc1c55bc647086acc4edb15a960
00520a8a94ac963e1420def1b9691a9e6feb8e26
7397679f54625a4463d4cfb2d3816576872e47ea
99ce785a4826ffb52ac17e3cc9b846949c88b624
```

The integration changes 24 files (+2811/-92 lines). The only subsequent local
build-code change adds Cargo `--locked` to use the committed Rust lockfile.
This branch does not claim authorship of the imported optimizations.

## Build recipe

Validated on Windows x64 with Visual Studio 2022 Build Tools (MSVC 19.44),
CUDA Toolkit 13.0.2, CMake, Ninja and Rust/Cargo. The GPU was an RTX 5070 Ti
16 GB (sm_120), driver 621.01, alongside a Ryzen 7 5800X3D and 64 GB RAM.

In a VS x64 developer PowerShell with CUDA, Ninja and Cargo on PATH, run from
the repository root:

```powershell
$env:CARGO_BUILD_JOBS = '2'
$env:CMAKE_BUILD_PARALLEL_LEVEL = '2'
$env:RAYON_NUM_THREADS = '2'
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release `
  -DCP_ENABLE_CPU=OFF -DCP_ENABLE_CUDA=ON -DCP_ENABLE_OPENCL=ON `
  -DCP_ENABLE_ONEDNN=OFF -DCP_ENABLE_WGPU=OFF -DCP_ENABLE_INTEL_NPU=OFF `
  -DCP_ENABLE_CUBLAS=OFF -DCP_CUDA_ARCH=120 -DCMAKE_CUDA_ARCHITECTURES=120 `
  "-DCMAKE_CUDA_COMPILER=$env:CUDA_PATH\bin\nvcc.exe" `
  "-DCUDAToolkit_ROOT=$env:CUDA_PATH" -DBUILD_TESTING=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

Keep the generated `kernels` directory beside the executable and make the
CUDA runtime DLL available. Upstream CMake obtains its source dependencies;
the local validation reused those dependencies and a Rust cache from an
earlier upstream build. A clean-room rebuild and bit-for-bit binary
reproducibility have not been demonstrated.

Alignment and offline proof checks (GPU-intensive):

```powershell
.\build\cppminer.exe --algo pearl --backend cuda --cutlass-fused `
  --cuda-mma auto --batch-size 256 --row-period-batch 16 `
  --devices 0 --m 16 --n 16 --align-test-prod
.\build\cppminer.exe --algo pearl --backend cuda --cutlass-fused `
  --cuda-mma auto --batch-size 256 --row-period-batch 16 `
  --devices 0 --m 16 --n 16 --mock --mock-diff 36
```

Example pool command, substituting your own public payout address and endpoint:

```powershell
.\build\cppminer.exe --algo pearl --backend cuda --cutlass-fused `
  --cuda-mma auto --batch-size 256 --row-period-batch 16 --devices 0 `
  --wallet YOUR_PRL_ADDRESS --worker blackwell `
  --pool stratum+tcp://YOUR_POOL:PORT --verify
```

These are direct miner commands. They do not install or implement the local
Windows idle controller, Stop shortcut, workload gates or power-limit helper
used during the validation below.

## Validation on 2026-11-09

- Upstream CTest: `cp_pool_protocol`, `cp_tcp`, `cp_cli` passed.
- Runtime selected `tensorop80` and the packed sm_12x scan kernel.
- Production alignment at m=n=16384, k=4096: eight variants matched the CPU
  prefix GEMM at all 32 milestones; seven tensor hash-policy checks passed.
- Tensor variants matched the SIMT reference across 65536 words; all 2048
  packed hash-tile transcripts matched.
- Offline certificate-V3 proof generation and verification passed.
- A 180-second AlphaPool EU trial completed with the following measurements:

| Measurement | Result |
| --- | ---: |
| Average miner API rate | 136.36 TH/s |
| Final 60-second rate | 137.71 TH/s |
| Accepted / rejected user shares | 107 / 0 |
| Average / peak sampled GPU draw | 243.82 / 250.33 W |
| Peak GPU temperature | 66.33 C |
| Minimum free VRAM | 8816 MiB |

The GPU power limit was 250 W; no clock offsets or memory-clock locks were
applied. The previous 350 W limit was restored afterward. Separate controller
Stop and desktop-unlock checks terminated mining in approximately one second.

The original scalar OpenCL build measured about 6 TH/s on the same card.
The tensor result is approximately 22.7 times faster in these short trials.
This is one system and a short validation, not a long-duration earnings test.
API rate includes total computation; accepted-share counts are for the user
wallet, not the developer-fee wallet. Pool luck and fees affect credited coins.

Validated local executable SHA-256:
`9305D4331E5D0226AF8B03E0ED68AD7B249A43C30E6525ABD71AC5EFF89AD153`.
This hash identifies the tested local build, not a downloadable release.

## Local antivirus event

Defender quarantined the compiled executable as `Trojan:Win32/Bearfoos.A!ml`.
After explicit user approval, the local copy was restored and its hash matched.
This records the event; the source checks and accepted shares are not a malware
audit. No antivirus configuration changes are part of this repository.
