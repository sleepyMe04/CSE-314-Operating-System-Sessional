# Assignment 1 — Shell Scripting: Automated Submission Grader

## Overview

A Bash script that automates the full grading pipeline for a programming assignment. Given a directory of student `.zip` submissions, the script:

1. **Organizes** each submission into language-specific folders (`C`, `C++`, `Python`, `Java`)
2. **Analyzes** each source file for code metrics (line count, comment count, function count)
3. **Executes** each program against a test suite and compares outputs to answer keys
4. **Reports** all results in a structured `result.csv`

---

## Usage

```bash
bash organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [OPTIONS]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `submissions_dir` | Directory containing student `.zip` files |
| `target_dir` | Output directory where organized files and results go |
| `tests_dir` | Directory with `test1.txt`, `test2.txt`, … input files |
| `answers_dir` | Directory with `ans1.txt`, `ans2.txt`, … expected outputs |

### Options

| Flag | Effect |
|------|--------|
| `-v` | Verbose mode — prints progress messages |
| `-noexecute` | Skip compilation and execution; only organize and analyze |
| `-nolc` | Omit line count from CSV |
| `-nocc` | Omit comment count from CSV |
| `-nofc` | Omit function count from CSV |

### Example

```bash
bash organize.sh Workspace/submissions/ targets/ Workspace/tests/ Workspace/answers/ -v
```

---

## How It Works

### Task A — Organize Submissions

- Parses the expected filename format: `StudentName_ID_submission_<student_id>.zip`
- Extracts each zip to a temp directory and detects the source language by file extension (`.c`, `.cpp`, `.py`, `.java`)
- Java submissions are additionally validated for the presence of a `Main` class
- Places the source file under `target_dir/<Language>/<student_id>/main.<ext>`
- Invalid, corrupt, or unrecognized submissions are silently skipped

### Task B — Code Analysis

For each organized source file, the `analyze_code()` function computes:

| Metric | C / C++ / Java | Python |
|--------|---------------|--------|
| Line count | `wc -l` | `wc -l` |
| Comment count | `grep -c '//'` | `grep -c '#'` |
| Function count | regex on `name(params) {` | regex on `def name(params):` |

### Task C — Execution & CSV Report

- **C/C++:** compiled with `gcc`/`g++`, then run per test
- **Java:** compiled with `javac`, run with `java Main`
- **Python:** run directly with `python3`
- Each student's output is compared to the answer key using `diff`
- Final `result.csv` columns: `student_id, student_name, language, matched, not_matched, line_count, comment_count, function_count` (columns omitted based on flags)

---

## Output

```
target_dir/
├── C/
│   └── <student_id>/
│       ├── main.c
│       ├── main.out        # compiled binary
│       └── out1.txt ... outN.txt
├── C++/ ...
├── Python/ ...
├── Java/ ...
└── result.csv
```

### Sample `result.csv`

```
student_id,student_name,language,matched,not_matched,line_count,comment_count,function_count
2105221,"Carol Danvers",C,4,1,45,3,2
2105222,"Peter Parker",C++,5,0,62,5,4
```

---

