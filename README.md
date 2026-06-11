# CSE314 — Operating Systems Sessional



This repository contains lab assignments for the CSE314 Operating Systems Sessional course. Each assignment targets a core OS concept, progressing from shell-level automation to kernel internals to concurrent programming.

---

## Assignments

| # | Topic | Language | Key Concepts |
|---|-------|----------|--------------|
| [1](./Assignment%201-Shell%20Scripting/) | Shell Scripting | Bash | File organization, code analysis, automated grading |
| [2](./Assignment%202-XV6/) | xv6 OS Modifications | C (kernel) | Scheduling, syscalls, process management |
| [3](./Assignment%203-IPC/) | Inter-Process Communication | C (POSIX) | Threads, semaphores, mutexes, readers-writers |

---

## Structure

```
CSE314/
├── Assignment 1-Shell Scripting/
│   ├── organize.sh                  # Main script
│   └── Shell-Scripting-Assignment-Files/
│       └── Workspace/               # Test inputs, sample submissions, answers
├── Assignment 2-XV6/
│   ├── 2105114.patch                # Kernel patch (apply to base xv6)
│   └── Jan25_CSE314_Assignment2_Spec.pdf
└── Assignment 3-IPC/
    ├── 2105114.c                    # IPC simulation
    └── CSE314_Jan_25_IPC_Offline.pdf
```

