# Sandbox limitations (PoC)

Running status for the Icarus Docker sandbox. Updated as hardening is verified.

## Phase 5 judge command invocation (decided)

When `/api/judge` is built, the process started **inside** the container will be
invoked as an **argv array** with **no shell**:

- Host side: Node `execFile` / `spawn` with `shell: false` and an args array
  (e.g. `docker`, `run`, …, `hdl-sandbox:poc`, `iverilog`, `-g2012`, `-o`,
  `/tmp/out.vvp`, `/work/harness.v`, `/work/submission.v`).
- Inside the container: that same argv becomes the PID 1 command (or the
  container command) — **not** `sh -c "…"`.
- User Verilog is only written to files and passed as **path strings in argv**,
  never concatenated into a shell command line.

Therefore the presence of `/bin/sh` in the base image is **not** reachable via
judge command construction from submission content. (A submission that abuses
simulator `$system`/similar is a separate open concern.)

## Resolved

| Item | Evidence |
|------|----------|
| Non-root user | `USER sandbox` (uid/gid 1000). `id` → `uid=1000(sandbox)`. |
| `iverilog`/`vvp` as non-root | and-gate harness+reference → `RESULT {"passed":68,"total":68}` as `sandbox`. |
| `--cap-drop=ALL` | `/proc/self/status` shows `CapPrm/CapEff/CapBnd` all zero. |
| `--security-opt=no-new-privileges` | Applied on successful compile/sim and stress runs. |
| Pure argv (no shell) for `iverilog` | `docker run … hdl-sandbox:poc iverilog -g2012 …` exit 0. |
| `--pids-limit` **enforced** | Fork bomb: `fork_failed after 63 children` with `--pids-limit=64` (not unbounded). |

### Pids-limit outcome (exact)

- Command: `docker run … --pids-limit=64 … /stress/fork_bomb`
- Observed: spawned up to 60 logged, then `fork_failed after 63 children`.
- Interpretation: the kernel/cgroup **refused further forks** at the limit.
  Docker does **not** auto-terminate the container merely for hitting the pids
  limit; already-created processes stayed in `pause()` until the **outer**
  `timeout` sent SIGKILL (`exit 137`). That is expected pids-limit behavior:
  deny new PIDs, do not OOM-kill.

## Open / known PoC limitations

| Item | Status |
|------|--------|
| `--memory=256m` enforcement | **Not verifiable in this cloud/dev environment.** `docker run --memory=256m` fails to start: cgroup v2 error `cannot enter cgroupv2 "/sys/fs/cgroup/docker" with domain controllers -- it is in threaded mode`. Root `cgroup.subtree_control` is `cpuset cpu pids` (no `memory`). |
| `--cpus` | Same class of failure (domain controller / threaded docker cgroup). |
| Custom seccomp profile | Not added (Docker default only). |
| AppArmor / SELinux profile | Not customized. |
| User namespaces / rootless | Not configured. |
| Icarus version pin | Apt package on `debian:bookworm-slim` (iverilog 11.0 here), not pinned to an upstream release digest beyond the base image tag. |
| `/bin/sh` in image | Still present from base image; not used by planned judge argv path. Removing it is out of PoC scope. |
| Simulator `$system` / forged `RESULT` | Not mitigated yet. |
| `vvp` `$finish` diagnostics | Extra lines beyond harness `RESULT`; judge must parse carefully. |
| `/api/judge` | Not built yet (Phase 5). |

### Memory-limit environmental note (deploy vs this host)

- **This host:** nested/restricted cgroup v2 setup — Docker cannot *apply*
  `--memory`, so we cannot observe OOM kills here. Control run **without**
  `--memory` allocated well beyond 256 MiB (logged past ~7000 MiB) until outer
  `timeout` killed the container — proving the allocator works and that no
  substitute host limit stopped at 256 MiB during that run.
- **Typical deploy host** (normal Docker/moby on Linux with the memory
  controller delegated to Docker’s cgroup): `--memory=256m` is a real cgroup
  limit and an intentional over-allocator should be **OOM-killed**
  (`OOMKilled=true`). That is a property of **this sandboxed dev environment’s
  cgroup delegation**, not of the Dockerfile flags themselves — **re-verify on
  the actual deploy machine** before trusting memory isolation in production.

## Intended `docker run` flags (Phase 5+)

```text
--network=none
--memory=256m          # must be confirmed on deploy host
--cpus=0.5             # must be confirmed on deploy host
--pids-limit=64        # verified enforced here
--cap-drop=ALL         # verified
--security-opt=no-new-privileges  # applied
--read-only
--tmpfs /tmp:rw,noexec,nosuid,size=…
+ host `timeout` wrapping the entire `docker run`
+ argv-array container command (no `sh -c` + user input)
```
