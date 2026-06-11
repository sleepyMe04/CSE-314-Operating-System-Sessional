#!/bin/bash

# Check minimum arguments
if [ $# -lt 4 ]; then
    echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [OPTIONS]"
    echo "Options: -v (verbose), -noexecute, -nolc, -nocc, -nofc"
    exit 1
fi

# Store arguments
submissions_dir=$1
target_dir=$2
tests_dir=$3
answers_dir=$4

# Process optional arguments
verbose=false
noexecute=false
nolc=false
nocc=false
nofc=false

for arg in "${@:5}"; do
    case $arg in
        -v) verbose=true ;;
        -noexecute) noexecute=true ;;
        -nolc) nolc=true ;;
        -nocc) nocc=true ;;
        -nofc) nofc=true ;;
    esac
done

#TASK A: Organize Submissions
# ==============================================
# Check if the submissions directory exists

# Create target directories
mkdir -p "$target_dir"/{C,C++,Python,Java} || {
    echo "Error: Failed to create target directories"
    exit 1
}

processed=0
skipped=0

for zipfile in "$submissions_dir"/*.zip; do
    [ ! -f "$zipfile" ] && continue

    # EXTRACT STUDENT ID FROM NEW FILENAME FORMAT
    filename=$(basename "$zipfile")
    if [[ "$filename" =~ _([0-9]{7})\.zip$ ]]; then
        student_id="${BASH_REMATCH[1]}"
        student_name=$(echo "$filename" | cut -d'_' -f1) # Gets "Thor.Odinson"
    else
        #[ "$verbose" = "true" ] && echo "Skipping invalid filename: $filename (expected *_<7-digit-ID>.zip)"
        ((skipped++))
        continue
    fi

    temp_dir=$(mktemp -d) || continue

    # Unzip and handle errors
    if ! unzip -q "$zipfile" -d "$temp_dir" 2>/dev/null; then
       # [ "$verbose" = "true" ] && echo "Skipping corrupt zip: $filename"
        rm -rf "$temp_dir"
        ((skipped++))
        continue
    fi

    # Find the code file recursively
    code_file=$(find "$temp_dir" -type f \( \
        -name "*.c" -o \
        -name "*.cpp" -o \
        -name "*.py" -o \
        -name "*.java" \
    \) -print -quit)

    if [ -z "$code_file" ]; then
       # [ "$verbose" = "true" ] && echo "Skipping $student_id: No code file found"
        rm -rf "$temp_dir"
        ((skipped++))
        continue
    fi

    # Determine language
    extension="${code_file##*.}"
    case "$extension" in
        c) lang="C"; target_file="main.c" ;;
        cpp) lang="C++"; target_file="main.cpp" ;;
        py) lang="Python"; target_file="main.py" ;;
        java)
            lang="Java"
            if ! grep -q "class[[:space:]]\+Main" "$code_file"; then
                #[ "$verbose" = "true" ] && echo "Skipping $student_id: Java file missing 'Main' class"
                rm -rf "$temp_dir"
                ((skipped++))
                continue
            fi
            target_file="Main.java"
            ;;
        *)
           # [ "$verbose" = "true" ] && echo "Skipping $student_id: Unsupported .$extension file"
            rm -rf "$temp_dir"
            ((skipped++))
            continue
            ;;
    esac

    # Organize the file
    student_dir="$target_dir/$lang/$student_id"
    mkdir -p "$student_dir" && \
    cp "$code_file" "$student_dir/$target_file" && \
    [ "$verbose" = "true" ]  && \
    ((processed++)) 

    rm -rf "$temp_dir"
done

# echo "Organization complete:"
# echo "- Successfully processed: $processed"
# echo "- Skipped: $skipped"




# Task B------------>







analyze_code() {
    local file="$1"
    local extension="$2"
    
    # Initialize metrics
    local line_count="NA"
    local comment_count="NA"
    local function_count="NA"

    # Line count (unless -nolc)
    if [ "$nolc" = false ]; then
        line_count=$(wc -l < "$file" || echo 0)
    fi
    # Comment count (unless -nocc)
if [ "$nocc" = false ]; then
    if [ "$extension" = "c" ] || [ "$extension" = "cpp" ] || [ "$extension" = "java" ]; then
        comment_count=$(grep -c '//' "$file")
    elif [ "$extension" = "py" ]; then
        comment_count=$(grep -c '#' "$file")
    else
        comment_count="NA"
    fi
fi

    

    # Function count
    # Function count
if [ "$nofc" = false ]; then
    if [ "$extension" = "c" ] || [ "$extension" = "cpp" ]; then
        # Match typical function definitions, avoid variable declarations
        function_count=$(grep -cE '^[a-zA-Z_][a-zA-Z0-9_ \t\*]*\([^\)]*\)[ \t]*\{' "$file" || echo 0)
    elif [ "$extension" = "java" ]; then
        # Match Java methods (may start with modifiers)
        function_count=$(grep -cE '^[ \t]*(public|private|protected)?[ \t]*(static)?[ \t]*[a-zA-Z_][a-zA-Z0-9_<>]*[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\([^\)]*\)[ \t]*\{' "$file" || echo 0)
    elif [ "$extension" = "py" ]; then
        # Match Python function definitions
        function_count=$(grep -cE '^[ \t]*def[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\([^\)]*\)[ \t]*:' "$file" || echo 0)
    else
        function_count="NA"
    fi
fi


    echo "$line_count,$comment_count,$function_count"
}

#

# Initialize CSV with proper header
# ==============================================
# Task C: Execution & CSV Reporting 
# ==============================================

header="student_id,student_name,language"
[ "$noexecute" = false ] && header="$header,matched,not_matched"
[ "$nolc" = false ] && header="$header,line_count"
[ "$nocc" = false ] && header="$header,comment_count"
[ "$nofc" = false ] && header="$header,function_count"
echo "$header" > "$target_dir/result.csv"

# Process each student
for lang_dir in "$target_dir"/*; do
    if [ -d "$lang_dir" ]; then
        language=$(basename "$lang_dir")
        for student_dir in "$lang_dir"/*; do
            if [ -d "$student_dir" ]; then
                student_id=$(basename "$student_dir")
                zip_match=$(grep -l "$student_id" "$submissions_dir"/*.zip | head -1)
                student_name=$(basename "$zip_match" | awk -F'_' '{print $1}' | sed 's/\./ /g')

                [ "$verbose" = "true" ] && echo "Organizing files of $student_id"

                # Find main file and set extension
                case $language in
                    C) main_file="$student_dir/main.c"; extension="c" ;;
                    C++) main_file="$student_dir/main.cpp"; extension="cpp" ;;
                    Python) main_file="$student_dir/main.py"; extension="py" ;;
                    Java) main_file="$student_dir/Main.java"; extension="java" ;;
                esac

                matched=0
                not_matched=0
                line_count="NA"
                comment_count="NA"
                function_count="NA"

                # Analyze code
                if [ -f "$main_file" ]; then
                    IFS=',' read -r line_count comment_count function_count <<< "$(analyze_code "$main_file" "$extension")"
                fi

                # Execution (if not disabled)
                if [ "$noexecute" = false ] && [ -f "$main_file" ]; then
                    [ "$verbose" = "true" ] && echo "Executing files of $student_id"
                    
                    case $language in
                        C)
                            if gcc "$main_file" -o "$student_dir/main.out" 2>/dev/null; then
                                executable="$student_dir/main.out"
                            else
                                continue
                            fi
                            ;;
                        C++)
                            if g++ "$main_file" -o "$student_dir/main.out" 2>/dev/null; then
                                executable="$student_dir/main.out"
                            else
                                continue
                            fi
                            ;;
                        Java)
                            (
                                cd "$student_dir" && javac Main.java 2> compile_error.txt
                            )
                            if [ $? -eq 0 ]; then
                                executable="(cd \"$student_dir\" && java Main)"
                            else
                                continue
                            fi
                            ;;
                        Python)
                            executable="python3 $main_file"
                            ;;
                    esac

                    # Run tests
                    for test_file in "$tests_dir"/test*.txt; do
                        test_num=$(basename "$test_file" | grep -o '[0-9]\+')
                        output_file="$student_dir/out$test_num.txt"
                        answer_file="$answers_dir/ans$test_num.txt"

                        eval "$executable" < "$test_file" > "$output_file"

                        # Compare
                        if [ -f "$answer_file" ] && diff -q "$output_file" "$answer_file" >/dev/null; then
                            ((matched++))
                        else
                            ((not_matched++))
                        fi
                    done
                fi

                row="$student_id,\"$student_name\",$language"
                [ "$noexecute" = false ] && row="$row,$matched,$not_matched"
                [ "$nolc" = false ] && row="$row,$line_count"
                [ "$nocc" = false ] && row="$row,$comment_count"
                [ "$nofc" = false ] && row="$row,$function_count"
                echo "$row" >> "$target_dir/result.csv"
            fi
        done
    fi
done
[ "$verbose" = "true" ] && echo "All submissions processed succeessfully."

