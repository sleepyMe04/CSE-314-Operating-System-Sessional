# Assignment 3 — Inter-Process Communication: Spy Agency Simulation

## Overview

A multithreaded C simulation of a spy agency's document recreation workflow, demonstrating classic synchronization patterns using POSIX threads, semaphores, and mutexes.

**Synchronization problems modeled:**
- **Bounded resource access** — limited typewriting stations (semaphores)
- **Group barrier** — spies within a unit must all finish before the leader proceeds
- **Writers-priority mutual exclusion** — leaders write to the logbook exclusively
- **Readers-writers problem** — multiple intelligence staff can read the logbook concurrently, but not while a leader is writing

---

## Problem Description

- **N** spies are divided into groups of **M** (so N/M groups)
- Each spy is assigned a typewriting station (`TS1`–`TS4`) based on their ID
- After completing document recreation, all members of a group must synchronize before the group leader can make a logbook entry
- **2 intelligence staff** threads continuously monitor the logbook (readers)
- Arrival and operation times follow a **Poisson distribution** parameterized by `lambda_arrival` and `lambda_operation`

---

## Build & Run

```bash
gcc -o spy_sim 2105114.c -lpthread -lm
```

Provide an `input.txt` in the same directory:

```
<N> <M> <lambda_arrival> <lambda_operation>
```

**Example `input.txt`:**
```
10 2 3.0 2.0
```

```bash
./spy_sim
```

Output is written to `output.txt`.

---

## Input Format

| Parameter | Description |
|-----------|-------------|
| `N` | Total number of spies |
| `M` | Group size (N must be divisible by M) |
| `lambda_arrival` | Mean arrival delay (ms, Poisson) |
| `lambda_operation` | Mean logbook write time (ms, Poisson) |

---

## Synchronization Design

### Typewriting Stations (Bounded Resource)

```
4 stations, each protected by a binary semaphore
Spy → sem_wait(&typewriters[station_id]) → work → sem_post(...)
```

### Group Barrier

```
Each group has: a mutex (group_mutex) + a semaphore (group_semaphores) + a counter
Last member to arrive signals all M members via M sem_post() calls
Every member blocks on sem_wait() until the barrier is released
```

### Logbook — Readers-Writers

```
Writers (group leaders): sem_wait(&logbook) → write → sem_post(&logbook)
Readers (staff):         readers_count tracked with logbook_mutex
                         First reader acquires logbook semaphore
                         Last reader releases it
```

This implements the **readers-writers** pattern where concurrent reads are allowed, but a write is fully exclusive.

### Poisson RNG

Arrival and operation delays are sampled from a Poisson distribution using the standard inversion method:

```c
int get_random_number(double lambda) {
    double L = exp(-lambda);
    int k = 0; double p = 1.0;
    do { k++; p *= (rand() / (double)RAND_MAX); } while (p > L);
    return k - 1;
}
```

---

## Output Format

Timestamped log lines written to `output.txt`, for example:

```
Operative 3 has arrived at typewriting station TS3 at time 12
Operative 3 has started document recreation at TS3 at time 12
Operative 3 has completed document recreation at TS3 at time 15
Unit 2 has completed document recreation at time 18
Leader 4 has started logbook entry at time 18
Intelligence Staff 1 has started reading logbook at time 20. Operations completed = 0
Leader 4 has completed logbook entry at time 21
```

---

## Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `TYPEWRITERS` | 4 | Number of typewriting stations |
| `MAX_STAFF` | 2 | Number of intelligence staff threads |
| `MAX_SPIES` | 100 | Max supported spies |
| `MAX_GROUPS` | 20 | Max supported groups |

---

