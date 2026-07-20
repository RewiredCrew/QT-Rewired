topLevel=$(git rev-parse --show-toplevel)
cd "$topLevel" || exit

if [[ -n "$NUMBER_OF_PROCESSORS" ]]; then
    THREADS="$NUMBER_OF_PROCESSORS"
elif command -v nproc &> /dev/null; then
    THREADS=$(nproc)
else
    THREADS=8
fi

MISSING=()
command -v node >/dev/null 2>&1 || MISSING+=("Node.JS (JSON Formatter)")
command -v haxelib >/dev/null 2>&1 || MISSING+=("Haxelib (Haxe Formatter)")
command -v oxipng >/dev/null 2>&1 || MISSING+=("Oxipng")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Formatter can't start! You are currently missing:"
    for item in "${MISSING[@]}"; do
			echo " - $item";
		done
		echo ""
		echo "Please install the programs above and restart the terminal to run the formatter."

    exit 1
fi

MODE=$1

if [[ "$MODE" == "--help" ]]; then
	echo "./runFormatter.sh [--help | --staged | --commit]"
	echo ""
	echo "--help: Displays this message"
	echo "--staged: Formats staged files (Checked files on Git)"
	echo "--commit: Formats and edits the last commit"
	exit 0
fi

haxe_files=()
json_files=()
png_files=()

while IFS= read -r -d '' f; do
    [[ ! -f "$f" ]] && continue

    if [[ "$f" == *.hxc ]]; then
        haxe_files+=("$f")
    elif [[ "$f" == *.json ]]; then
        json_files+=("$f")
    elif [[ "$f" == *.png ]]; then
        png_files+=("$f")
    fi
done < <(
  if [[ "$MODE" == "--staged" ]]; then
    git diff --cached -z --name-only --diff-filter=AM
  elif [[ "$MODE" == "--commit" ]]; then
    git show --pretty="" -z --name-only --diff-filter=AM
  else
		git ls-files -z
  fi
)

for f in "${files[@]}"; do
    [[ ! -f "$f" ]] && continue

    [[ "$f" == *.hxc ]] && haxe_files+=("$f")
    [[ "$f" == *.json ]] && json_files+=("$f")
    [[ "$f" == *.png  ]] && png_files+=("$f")
done

if [ ${#haxe_files[@]} -gt 0 ]; then
	format_haxe()
	{
    local file="$1"
		echo "Formatting ${file}..."

    if haxelib run formatter --stdin -s "." < "$file" | head -c -1 > "$file.tmp"; then
        mv "$file.tmp" "$file"
    else
        rm -f "$file.tmp"
        echo "Error formatting: $file"
    fi
	}
	export -f format_haxe

  echo "--------- HAXE FORMATTER ---------"
  printf "%s\n" "${haxe_files[@]}" | xargs -I {} -P "$THREADS" bash -c 'format_haxe "$@"' _ {}
fi

if [ ${#json_files[@]} -gt 0 ]; then
    echo "--------- JSON FORMATTER ---------"
  printf "%s\0" "${json_files[@]}" | MSYS_NO_PATHCONV=1 xargs -0 -n 50 npx prettier --write --config ".prettierrc.json"
fi

if [ ${#png_files[@]} -gt 0 ]; then
    echo "--------- OXIPNG ---------"
    printf "%s\0" "${png_files[@]}" | xargs -0 -n 50 oxipng -o 6 --strip safe --alpha
fi

if [[ "$MODE" == "--staged" || "$MODE" == "--commit" ]]; then
    git add --update

    if [[ "$MODE" == "--commit" ]]; then
      git commit --amend --no-edit
    fi
fi