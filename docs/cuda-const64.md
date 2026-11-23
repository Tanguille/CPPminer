# Constant-64 CUDA canary

`CP_CUDA_CONST64=1` opts into uniform signal values of 64 on the packed CUDA
mining path. It commits B and the scanned A rows to that value and regenerates
one additional, unscanned A row per attempt. The extra row is part of the
Merkle commitment and the cert-v3 proof. The target and the scan kernel are
unchanged. Unset the variable or set it to `0` for the zero-B control.

The `sm75-const64-<git sha>` image targets Linux/amd64 and has native Turing
code. It uses upstream wallet/fee handling. The build runs the host CTests;
they do not test a CUDA device.

For a first hardware check, run the following in an available GPU slot, with a
wall-clock deadline. This uses the real CUDA miner and Rust verifier on a fixed
offline job; there is no pool connection. Run once with each input setting.

```sh
CP_CUDA_CONST64=1 cppminer --backend cuda --devices 0 --mock --mock-diff 39 --verify
```

Require the `sm_75` packed `mma.m8n8k16.s8` kernel, `constant-64 job B cached`
and a `verify OK` cert-v3 proof. The control prints `zero-B job B cached`.
For performance, compare both settings with the **same image digest**, normal
pool, clock and batch settings. Match miner work and board-power samples over
the same steady interval; record pool acknowledgments separately.
