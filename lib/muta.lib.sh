
unsorted_unique() {
	jq -Rr '
	def unsorted_unique_by(f): to_entries|unique_by(.value|f)|sort_by(.key)|map(.value);
	[.,inputs]|unsorted_unique_by(.)[]
	'
}
muta_help() {
	echo 'Usage: cat file.list | '"$0"' [<options>] [--] <command> ...'
	echo 'Options:'
	echo '  --progress'
	echo '  --no-log'
	echo '  --log'
	echo '  -P <n>|--max-procs <n>'
}

muta() {
	if [ $# -eq 0 ]; then
		set -- --help
	fi
	local maxprocs="${MUTA_MAXPROCS:-}"
	local keeplog="${MUTA_KEEPLOG:-false}"
	local progress="${MUTA_PROGRESS:-false}"
	while [ $# -gt 0 ]; do
		case "$1" in
		(--help)
			muta_help
			exit 0
		;;
		(--) shift;break;;
		(--progress)	progress=true ;;
		(--no-progress)	progress=false ;;
		(--log)		keeplog=true ;;
		(--no-log)	keeplog=false ;;
		(-P|--max-procs) shift;maxprocs="$1" ;;
		(--*)	echo >&2 "ERROR-10: unsupported option '$1'"; exit 10 ;;
		(-*)	echo >&2 "ERROR-11: unsupported option '$1'"; exit 11 ;;
		(*)	break;;
		esac
		shift
	done

	if [ -t 0 ]; then
		echo 'Usage: cat servers.list | '"$0"' [<options>] <command> ...'
		exit 1
	fi

	local resultdir;resultdir="$(mktemp -d "/tmp/$(basename "$0" .sh).$(date +%Y%m%d.%H%M).XXXXXXXX")"

	TA_DIR="$resultdir"
	TA_PROGRESS="$progress"
	export TA_DIR TA_PROGRESS

	# -P 1 (1by1) the default
	# -P 0 (all at the same time)
	grep -v -E '^[[:space:]]*($|#)' |
	sed -E -e 's,^([^[:space:]]+)[[:space:]]*.*,\1,g' |
	unsorted_unique |
	xargs --no-run-if-empty -n 1 -P "${maxprocs:-1}" "${MU_TA:-$BASEDIR/bin/_ta.sh}" "$@"
        if [ "$progress" = true ]; then echo >&2; fi
	unset TA_DIR TA_PROGRESS

	# [H]ook ...
	cat "$resultdir"/*.log

	if cat "$resultdir"/*.err|grep -q ''; then
		grep >&2 -H '' "$resultdir"/*.err
	fi
	if ${keeplog:-true}; then
		echo >&2 "resultdir=$resultdir"
	else
		rm -rf -- "$resultdir"
	fi
}
