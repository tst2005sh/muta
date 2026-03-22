#!/bin/sh

if [ -z "$TA_DIR" ] || [ -z "$TA_PROGRESS" ]; then
	exit 123
fi
target="$( shift $(($#-1)); echo "$1" )"
trap 'cd -- "'"$TA_DIR"'" && rm -f -- "'"$target.lock"'"' EXIT
touch "$TA_DIR/$target.lock"
${TA_PROGRESS:-false} && echo >&2 -n '('
(
	unset TA_DIR TA_PROGRESS;
	"$@";
	exit $?
) >"$TA_DIR/$target.log" 2>"$TA_DIR/$target.err"
r=$?
echo "$r" > "$TA_DIR/$target.ret"
${TA_PROGRESS:-false} && echo >&2 -n ')'
exit $r
