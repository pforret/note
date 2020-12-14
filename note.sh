#!/usr/bin/env bash
### ==============================================================================
### SO HOW DO YOU PROCEED WITH YOUR SCRIPT?
### 1. define the options/parameters and defaults you need in list_options()
### 2. implement the different actions in main() with helper functions
### 3. implement helper functions you defined in previous step
### 4. add binaries your script need./note
# s (e.g. ffmpeg, jq) to require_binaries
### ==============================================================================

### Created by Peter Forret ( pforret ) on 2020-12-14
script_version="0.0.1"  # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="peter@forret.com"
#readonly script_created="2020-12-14"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root
PFOR_NOTE_DIR=~/.note

list_options() {
echo -n "
#commented lines will be filtered
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
flag|f|force|do not ask for confirmation (always yes)
option|n|note_dir|folder for note files |$PFOR_NOTE_DIR
option|l|log_dir|folder for log files |$PFOR_NOTE_DIR/.log
param|1|action|action to perform: add/edit/find/list/paste
param|?|input|text to add
" | grep -v '^#'
}

#####################################################################
## Put your main script here
#####################################################################

main() {
    log "Program: $script_basename $script_version"
    log "Updated: $script_modified"
    log "Run as : $USER@$HOSTNAME"
    # add programs that need to be installed, like: tar, wget, ffmpeg, rsync, convert, curl, gawk ...
    require_binaries tput uname awk
    log_to_file "[$script_basename] $script_version started"
    time_started=$(date '+%s')

    # shellcheck disable=SC2154
    folder_prep "$note_dir" 3650 # ten years
    folder_prep "$note_dir/$execution_year" 3650 # ten years
    note_file="$note_dir/$execution_year/$execution_day.$script_prefix.md"
    folder_prep "log_dir" 30

    action=$(lower_case "$action")
    case $action in
    add )
    #TIP: use «note add XYZ» to add one line/thought to your note file
    #TIP:> note add "line of text"
        # shellcheck disable=SC2154
        perform_add "$input"
        ;;

    find )
    #TIP: use «note find XYZ» to find a word/phrase in your note files
    #TIP:> note find "DEVL"
        perform_find "$input"
        ;;

    edit )
    #TIP: use «note edit» to open your current note file in your default editor
    #TIP:> note edit
        perform_edit
        ;;

    list )
    #TIP: use «note list» to show a list of all your note files with some stats
    #TIP:> note list
        perform_list
        ;;

    paste )
    #TIP: use «note paste» to paste the clipboard into your note file
    #TIP:> note paste
        perform_paste
        ;;

    *)
        die "action [$action] not recognized"
    esac
    time_ended=$(date '+%s')
    time_elapsed=$((time_ended - time_started))
    log_to_file "[$script_basename] ended after $time_elapsed secs"
}

#####################################################################
## Put your helper scripts here
#####################################################################

perform_show(){
  lines=$(< "$note_file" wc -l | awk '{print $1 - 1}')
  out "📝 $(basename "$note_file")  ($lines lines)"
  tail -4 "$note_file"
}

perform_add(){
   echo "* $1" >> "$note_file"
   perform_show
}

perform_list(){

  find "$note_dir" -type f -name \*.md \
  | while read -r file ; do
    out "$(basename "$file"): $(< "$file" wc -l) lines"
    done
}

perform_edit(){
  if [[ ! -f "$note_file" ]] ; then
    upper_case "# $script_prefix $execution_day" > "$note_file"
  fi
  "$EDITOR" "$note_file"
}

perform_find(){
  (
  # shellcheck disable=SC2164
  cd "$note_dir" || return 0
    grep -r "$1" ./* \
  | while read -r line ; do
      file="$(echo "$line" | cut -d: -f1)"
      text="$(echo "$line" | cut -d: -f2-)"
      out "${col_grn}$(basename "$file" .md)${col_reset}: $text"
    done
  )
}

perform_paste(){
  case $os_name in
  Darwin)
    # MacOS has pbpaste/pbcopy
    pbpaste >> "$note_file"
    ;;
  Linux)
    paste_method=""
    if [[ -n "${DISPLAY:-}" ]] ; then
      # X is running, xsel/xclip might work
      [[ -n $(which xsel) ]] && paste_method="xsel"
      [[ -n $(which xclip) ]] && paste_method="xclip"
    else
      # might be WSL
      [[ -n $(which powershell.exe) ]] && paste_method="powershell"

    fi
    case $paste_method in
      xsel)       xsel --clipboard --output         >> "$note_file" ;;
      xclip)      xclip -selection clipboard -o     >> "$note_file" ;;
      powershell) powershell.exe -command "Get-Clipboard" >> "$note_file" 2> /dev/null ;;
      *)  die "Can't do paste on this machine, need xsel/xclip/WSL"
    esac

  esac
  perform_show
}



#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2120
hash(){
  length=${1:-6}
  # shellcheck disable=SC2230
  if [[ -n $(which md5sum) ]] ; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

force=0
help=0

## ----------- TERMINAL OUTPUT STUFF

verbose=0
#to enable verbose even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1
quiet=0
#to enable quiet even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

[[ -t 1 ]] && piped=0 || piped=1        # detect if output is piped
if [[ $piped -eq 0 ]] ; then
  col_reset="\033[0m" ; col_red="\033[1;31m" ; col_grn="\033[1;32m" ; col_ylw="\033[1;33m"
else
  col_reset="" ; col_red="" ; col_grn="" ; col_ylw=""
fi

[[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
if [[ $unicode -gt 0 ]] ; then
  char_succ="✔" ; char_fail="✖" ; char_alrt="➨" ; char_wait="…"
else
  char_succ="OK " ; char_fail="!! " ; char_alrt="?? " ; char_wait="..."
fi

readonly nbcols=$(tput cols 2>/dev/null || echo 80)
#readonly nbrows=$(tput lines)
readonly wprogress=$((nbcols - 5))

out() { ((quiet)) || printf '%b\n' "$*";  }

progress() {
  ((quiet)) || (
    if is_set ${piped:-0} ; then
      out "$*"
    else
      printf "... %-${wprogress}b\r" "$*                                             ";
    fi
  )
}

die()     { tput bel; out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2; safe_exit; }
fail()    { tput bel; out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2; safe_exit; }

alert()   { out "${col_red}${char_alrt}${col_reset}: $*" >&2 ; }                       # print error and continue

success() { out "${col_grn}${char_succ}${col_reset}  $*" ; }

announce(){ out "${col_grn}${char_wait}${col_reset}  $*"; sleep 1 ; }

log()   { ((verbose)) && out "${col_ylw}# $* ${col_reset}" >&2 ; }

log_to_file(){
  echo "$(date '+%H:%M:%S') | $*" >> "$log_file"
}

lower_case()   { echo "$*" | awk '{print tolower($0)}' ; }
upper_case()   { echo "$*" | awk '{print toupper($0)}' ; }

slugify()     {
    # shellcheck disable=SC2020
  lower_case "$*" \
  | tr \
    'àáâäæãåāçćčèéêëēėęîïííīįìłñńôoöòóœøōõßśšûüùúūÿžźż' \
    'aaaaaaaaccceeeeeeeiiiiiiilnnooooooooosssuuuuuyzzz' \
  | awk '{
    gsub(/[^0-9a-z ]/,"");
    gsub(/^\s+/,"");
    gsub(/^s+$/,"");
    gsub(" ","-");
    print;
    }' \
  | cut -c1-50
  }

confirm() { is_set $force && return 0; read -r -p "$1 [y/N] " -n 1; echo " "; [[ $REPLY =~ ^[Yy]$ ]];}

ask() {
  # $1 = variable name
  # $2 = question
  # $3 = default value
  # not using read -i because that doesn't work on MacOS
  local ANSWER
  read -r -p "$2 ($3) > " ANSWER
  if [[ -z "$ANSWER" ]] ; then
    eval "$1=\"$3\""
  else
    eval "$1=\"$ANSWER\""
  fi
}

error_prefix="${col_red}>${col_reset}"
trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for
# trap 'echo ‘$BASH_COMMAND’ failed with error code $?' ERR
safe_exit() {
  [[ -n "${tmp_file:-}" ]] && [[ -f "$tmp_file" ]] && rm "$tmp_file"
  trap - INT TERM EXIT
  log "$script_basename finished after $SECONDS seconds"
  exit 0
}

is_set()       { [[ "$1" -gt 0 ]]; }
is_empty()     { [[ -z "$1" ]] ; }
is_not_empty() { [[ -n "$1" ]] ; }

is_file() { [[ -f "$1" ]] ; }
is_dir()  { [[ -d "$1" ]] ; }

show_usage() {
  out "Program: ${col_grn}$script_basename $script_version${col_reset} by ${col_ylw}$script_author${col_reset}"
  out "Updated: ${col_grn}$script_modified${col_reset}"

  echo -n "Usage: $script_basename"
   list_options \
  | awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-10s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [optn] %s",$2,$3,"val",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"val",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-10s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     } else if($2 == "?") {
          fulltext = fulltext sprintf("\n    %-10s: [parameters] %s (optional)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     } else {
          fulltext = fulltext sprintf("\n    %-10s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
    END {print oneline; print fulltext}
  '
}

show_tips(){
  < "${BASH_SOURCE[0]}" grep -v '$col' \
  | awk "
  /TIP: / {\$1=\"\"; gsub(/«/,\"$col_grn\"); gsub(/»/,\"$col_reset\"); print \"*\" \$0}
  /TIP:> / {\$1=\"\"; print \" $col_ylw\" \$0 \"$col_reset\"}
  "
}

init_options() {
	local init_command
    init_command=$(list_options \
    | awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    ')
    if [[ -n "$init_command" ]] ; then
        eval "$init_command"
   fi
}

require_binaries(){
  os_name=$(uname -s)
  os_version=$(uname -sprm)
  log "Running: on $os_name ($os_version)"
  list_programs=$(echo "$*" | sort -u |  tr "\n" " ")
  log "Verify : $list_programs"
  for prog in "$@" ; do
    # shellcheck disable=SC2230
    if [[ -z $(which "$prog") ]] ; then
      die "$script_basename needs [$prog] but this program cannot be found on this [$os_name] machine"
    fi
  done
}

folder_prep(){
  if [[ -n "$1" ]] ; then
      local folder="$1"
      local max_days=${2:-365}
      if [[ ! -d "$folder" ]] ; then
          log "Create folder : [$folder]"
          mkdir "$folder"
      else
          log "Cleanup folder: [$folder] - delete files older than $max_days day(s)"
          find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
      fi
  fi
}

expects_single_params(){
  list_options | grep 'param|1|' > /dev/null
  }
expects_optional_params(){
  list_options | grep 'param|?|' > /dev/null
  }
expects_multi_param(){
  list_options | grep 'param|n|' > /dev/null
  }

count_words(){
  wc -w \
  | awk '{ gsub(/ /,""); print}'
}

parse_options() {
    if [[ $# -eq 0 ]] ; then
       show_usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    while true; do
      # flag <flag> is saved as $flag = 0/1
      # option <option> is saved as $option
      if [[ $# -eq 0 ]] ; then
        ## all parameters processed
        break
      fi
      if [[ ! $1 = -?* ]] ; then
        ## all flags/options processed
        break
      fi
	  local save_option
      save_option=$(list_options \
        | awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
        if [[ -n "$save_option" ]] ; then
          if echo "$save_option" | grep shift >> /dev/null ; then
            local save_var
            save_var=$(echo "$save_option" | cut -d= -f1)
            log "Found  : ${save_var}=$2"
          else
            log "Found  : $save_option"
          fi
          eval "$save_option"
        else
            die "cannot interpret option [$1]"
        fi
        shift
    done

    ((help)) && (
      echo "### USAGE"
      show_usage
      echo ""
      echo "### SCRIPT AUTHORING TIPS"
      show_tips
      safe_exit
    )

    ## then run through the given parameters
  if expects_single_params ; then
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    list_singles=$(echo "$single_params" | xargs)
    single_count=$(echo "$single_params" | count_words)
    log "Expect : $single_count single parameter(s): $list_singles"
    [[ $# -eq 0 ]] && die "need the parameter(s) [$list_singles]"

    for param in $single_params ; do
      [[ $# -eq 0 ]] && die "need parameter [$param]"
      [[ -z "$1" ]]  && die "need parameter [$param]"
      log "Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    log "No single params to process"
    single_params=""
    single_count=0
  fi

  if expects_optional_params ; then
    optional_params=$(list_options | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(echo "$optional_params" | count_words)
    log "Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params ; do
      log "Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    log "No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if expects_multi_param ; then
    #log "Process: multi param"
    multi_count=$(list_options | grep -c 'param|n|')
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    log "Expect : $multi_count multi parameter: $multi_param"
    (( multi_count > 1 )) && die "cannot have >1 'multi' parameter: [$multi_param]"
    (( multi_count > 0 )) && [[ $# -eq 0 ]] && die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]] ; then
      log "Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && die "cannot interpret extra parameters"
  fi
}

lookup_script_data(){
  readonly script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  readonly script_basename=$(basename "${BASH_SOURCE[0]}")
  readonly execution_day=$(date "+%Y-%m-%d")
  readonly execution_year=$(date "+%Y")

  # cf https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
  script_install_path="${BASH_SOURCE[0]}"
  script_install_folder="$( cd -P "$( dirname "$script_install_path" )" >/dev/null 2>&1 && pwd )"
  while [ -h "$script_install_path" ]; do
    # resolve symbolic links
    script_install_folder="$( cd -P "$( dirname "$script_install_path" )" >/dev/null 2>&1 && pwd )"
    script_install_path="$(readlink "$script_install_path")"
    [[ "$script_install_path" != /* ]] && script_install_path="$script_install_folder/$script_install_path"
  done

  script_modified="??"
  os_name=$(uname -s)
  [[ "$os_name" = "Linux" ]]  && script_modified=$(stat -c %y    "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_name" = "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null) # for MacOS

  log "Executing : [$script_install_path]"
  log "In folder : [$script_install_folder]"

  # $script_install_folder  = [/Users/<username>/.basher/cellar/packages/pforret/<script>]
  # $script_install_path    = [/Users/<username>/.basher/cellar/packages/pforret/bashew/<script>]
  # $script_basename        = [<script>.sh]
  # $script_prefix          = [<script>]

  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")
}

prep_log_and_temp_dir(){
  tmp_file=""
  log_file=""
  # shellcheck disable=SC2154
  if [[ -n "$log_dir" ]] ; then
    folder_prep "$log_dir" 7
    log_file=$log_dir/$script_prefix.$execution_day.log
    log "log_file: $log_file"
  fi
}

import_env_if_any(){
  if [[ -f "$script_install_folder/.env" ]] ; then
    log "Read config from [$script_install_folder/.env]"
    # shellcheck disable=SC1090
    source "$script_install_folder/.env"
  fi
  }

[[ $run_as_root == 1  ]] && [[ $UID -ne 0 ]] && die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && die "user is $USER, CANNOT be root to run [$script_basename]"

lookup_script_data

# overwrite with .env if any
import_env_if_any

# set default values for flags & options
init_options

# overwrite with specified options if any
parse_options "$@"

# clean up log and temp folder
prep_log_and_temp_dir

# run main program
main

# exit and clean up
safe_exit
