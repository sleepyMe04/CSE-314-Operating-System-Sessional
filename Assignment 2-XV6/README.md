# Assignment 2 — xv6 OS: Lottery + MLFQ Scheduling & Syscall History

## Overview

Kernel-level modifications to the [MIT xv6 RISC-V OS](https://github.com/mit-pdos/xv6-riscv), implementing two major features:

1. **Hybrid Scheduler** — a two-queue system combining Lottery Scheduling (Queue 1) and Multi-Level Feedback Queue (MLFQ) (Queue 2)
2. **Syscall History Tracking** — a new `history` syscall and `history` user program that reports per-syscall invocation counts

---

## Applying the Patch

Clone the base xv6-riscv repository, then apply the patch:

```bash
git clone https://github.com/mit-pdos/xv6-riscv.git
cd xv6-riscv
git apply /path/to/2105114.patch
make qemu
```

> Requires: `qemu-system-riscv64`, `riscv64-linux-gnu-gcc` toolchain

---

## Features

### 1. Hybrid Scheduler (Lottery + MLFQ)

Processes are assigned to one of two queues:

| Queue | Algorithm | Promotion / Demotion |
|-------|-----------|----------------------|
| **Queue 1** | Lottery Scheduling | Demoted to Q2 after using all tickets |
| **Queue 2** | MLFQ (Round Robin with aging) | Boosted back to Q1 after a time threshold |

**Lottery Scheduling (Q1):**
- Each process holds a configurable number of tickets
- A random winner is drawn each scheduling round; winner runs for one time slice
- Ticket count decrements each slice; process moves to Q2 at zero

**MLFQ (Q2):**
- Standard round-robin among Q2 processes
- Aging: processes that wait too long are boosted back to Q1 with refreshed tickets

### 2. New System Calls

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `settickets` | `int settickets(int n)` | Set ticket count for the calling process |
| `getpinfo` | `int getpinfo(struct pstat*)` | Fill a `pstat` struct with info for all active processes |
| `history` | `int history(int syscall_num, struct syscall_stat*)` | Get invocation count and total time for a given syscall |

### 3. `pstat` Structure

```c
struct pstat {
    int pid[NPROC];
    int inuse[NPROC];
    int inQ[NPROC];               // current queue (1 or 2)
    int tickets_original[NPROC];
    int tickets_current[NPROC];
    int time_slices[NPROC];       // total time slices consumed
};
```

### 4. User Programs

| Program | Usage | Description |
|---------|-------|-------------|
| `dummyproc` | `dummyproc <tickets>` | Spawns a CPU-bound process with given ticket count |
| `testprocinfo` | `testprocinfo` | Prints current `pstat` table |
| `history` | `history [syscall_num]` | Prints syscall invocation history |

---

## Modified Files

```
kernel/
├── proc.h          — Added queue, ticket, and boost fields to struct proc
├── proc.c          — Scheduler logic (lottery draw, queue management, aging)
├── pstat.h         — New pstat struct definition
├── syscall.h/c     — Registered new syscalls
├── syscall_stat.h  — Syscall statistics struct
├── sysproc.c       — Implementations of settickets, getpinfo, history
├── random.c        — PRNG for lottery draw
├── defs.h          — Added function prototypes
└── main.c          — stats_init() called at boot

user/
├── dummyproc.c
├── testprocinfo.c
├── history.c
├── user.h / usys.pl — Updated with new syscall stubs
└── test.sh          — Shell test script
```

---

## Notes

- `CPUS` is set to `1` in the Makefile for deterministic single-core scheduling behavior
- The random number generator (`random.c`) seeds from the tick counter to avoid deterministic lottery outcomes
- Processes that fail to compile after patching likely indicate a base xv6 version mismatch; use the commit the spec was tested against
