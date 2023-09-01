#!/bin/bash

version=1.1

  ###########################################################
  #                                                         #
  #     ▄   ▄███▄   ███     ▄   ███     ▄   ▄█ █     ██▄    #
  #      █  █▀   ▀  █  █     █  █  █     █  ██ █     █  █   #
  #  ██   █ ██▄▄    █ ▀ ▄ █   █ █ ▀ ▄ █   █ ██ █     █   █  #
  #  █ █  █ █▄   ▄▀ █  ▄▀ █   █ █  ▄▀ █   █ ▐█ ███▄  █  █   #
  #  █  █ █ ▀███▀   ███   █▄ ▄█ ███   █▄ ▄█  ▐     ▀ ███▀   #
  #  █   ██                ▀▀▀         ▀▀▀                  #
  #                                                         #
  ###########################################################
    #               A Bash compiler script.               #           
    #######################################################
files=(
    "main.sh"
)
log_file="lunabuild_log.txt"
buildversions_folder="./.lunabuild/buildversions"
# Everything after this, can be untouched.
# Get the operating system name
os=$(uname -s)

# Convert the OS name to a number
if [[ "$os" == "Linux" ]]; then
  os_number=1
elif [[ "$os" == "Darwin" ]]; then
  os_number=2
elif [[ "$os" == "FreeBSD" ]]; then
  os_number=3
else
  os_number=0  # Default value if the OS is not recognized or supported
  os="Unknown"
fi
logs=(
    "Build ID: lb_build_id:ver-$version;$(date +"%Y%m%d_%H%M%S");$os_number:$os;project_name:($(basename "$(pwd)"))"
    ">LOG<"
)
add_entry() {
  local array_name="$1"
  local new_entry="$2"
  eval "${array_name}[\${#${array_name}[@]}]=\"${new_entry}\""
}
function log() {
    add_entry "logs" "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}
log " Finding .lunabuild folder..."
if [ -e "./.lunabuild" ]; then 
  log " Found .lunabuild!"
else
  wrn " The folder '.lunabuild (./.lunabuild)' was not found, making it now."
  mkdir ./.lunabuild
fi
getdeps() {
  depsdir=./.lunabuild/deps
  getitdir="$depsdir"/getit
  getit="$getitdir"
  log " Checking for Dependencies..."
  mkdir -p "$depsdir"
  if [ ! -f "$getitdir" ]; then
    curl -L -o "$getitdir" https://github.com/LunaWave/getit/releases/download/beta-release/getit
    chmod +x "$getitdir"
  fi
}
listdeps() {
  echo "These are the dependencies that LunaBuild uses."
  echo
  echo "LunaBuild uses 'getit' as a command finder and installer! It is used to install deps"
  echo "Here is the version of the installed dependency:"
  echo 
  sudo "$getit" ""
  echo 
  echo "LunaBuild uses 'curl' to gather online links. You can't even install LunaBuild without it."
  echo "Here is the version of the installed dependency:"
  echo 
  curl -V
  echo 
}
getdeps

if curl -Is https://www.google.com | head -n 1 | grep -q 200; then
  internet=true
else
  internet=false
fi
askrun=false
justrun=false
cleanprebuild=true
ifargs=false

getonlinedata() {
  log " Getting online data..."
  onlinerepo="https://raw.githubusercontent.com/LunaWave/lunabuild/resources/"
  welcome=$(curl -H "Cache-Control: no-cache" -s "$onlinerepo"welcome || "Hello and welcome to LunaWave! (Couldn't receive the online welcome message. :'(")
  newestversion=$(curl -H "Cache-Control: no-cache" "$onlinerepo"version || "Unable to receive the newest version.")
  if [ "$internet" = true ]; then
      rm -r ./.lunabuild/help.txt
      curl -H "Cache-Control: no-cache" "$onlinerepo"help"$version" >> ./.lunabuild/help.txt   
  else
      log "No internet connection so online data not gathered."
  fi
  echo $newestversion > ./.lunabuild/newestversion.txt
  echo $welcome > ./.lunabuild/welcome.txt
}
print() {
    local text="$1"
    local color="${2:-default}"
    local background="${3:-default}"
    local formatting="${4:-default}"

    # ANSI escape codes for text color
    case "$color" in
        "default") color_code="39";;
        "black") color_code="30";;
        "red") color_code="31";;
        "green") color_code="32";;
        "yellow") color_code="33";;
        "blue") color_code="34";;
        "magenta") color_code="35";;
        "cyan") color_code="36";;
        "white") color_code="37";;
        "orange") color_code="38;5;208";; #
        *) color_code="39";; # Default to default color
    esac

    # ANSI escape codes for background color
    case "$background" in
        "default") background_code="49";;
        "black") background_code="40";;
        "red") background_code="41";;
        "green") background_code="42";;
        "yellow") background_code="43";;
        "blue") background_code="44";;
        "magenta") background_code="45";;
        "cyan") background_code="46";;
        "white") background_code="47";;
        "gray") background_code="100";;   # Grayscale 1 (Lightest)
        *) background_code="49";;           # Default to default background
    esac


    # ANSI escape codes for text formatting
    case "$formatting" in
        "default") formatting_code="0";;
        "bold") formatting_code="1";;
        "underline") formatting_code="4";;
        "blink") formatting_code="5";;
        *) formatting_code="0";; # Default to default formatting
    esac

# Printing the message with the specified colors and formatting
echo -e "\033[${formatting_code};${color_code};${background_code}m${text}\033[0m"

}
function wrn() {
    local text="$1"
    print "Wrn: $1" "orange" "black" "underline"
    log "Wrn: $1"
}
function err() {
    local text="$1"
    print "\aErr: $1" "white" "red" "bold"
    log "Err: $1"
    errors=true
}
resetproject() {
  wrn "Resetting project."f
            
  [ -d ./build ] && rm -r ./build
  [ -d "$buildversions_folder" ] && rm -r "$buildversions_folder"
  [ -d ./temp ] && rm -r ./temp
  [ -d ./"$logfile" ] && rm -r ./"$log_file"
  [ -d ./src ] && rm -r ./src
  [ -d ./.lunabuild ] && rm -r ./.lunabuild
  mkdir ./build
  mkdir ./src
  echo "Run './build.sh -h' if you don't know what you're doing." >> ./build/firstrun.txt
  echo "# You don't need to add a shebang, the build script auto-adds it. Though having it doesn't effect the script." >> ./src/main.sh
  echo "# Have fun using LunaBuild. " >> ./src/main.sh
  echo "Run LunaBuild to receive logs." >> ./"$log_file"
  bootload
}
bootload() {
  echo "#!/bin/bash" >> ./bootloader.sh
  echo "sleep 0.25" >> ./bootloader.sh
  echo "./build.sh" >> ./bootloader.sh
  echo "sleep 0.25" >> ./bootloader.sh
  echo "./build.sh -w" >> ./bootloader.sh
  echo 'rm "$0"' >> ./bootloader.sh
  chmod +x ./bootloader.sh
  ./bootloader.sh
  exit
}
forcereset() {
  print "Force rebuilding LunaBuild due to required files missing." "red" "white" "bold"
  sleep 1
  resetproject
  sleep 1
  bootload
}

if [ ! -d ./src ]; then
  forcereset
fi

log " Making temp folder..."
mkdir -p ./temp
cp ./"$log_file" ./temp/"$log_file"
log " Making temp log to be cloned later..."
rm ./"$log_file"
touch ./"$log_file"

if [ -e "./.lunabuild/rundata.txt" ]; then
  log " Run before."
  if [ "$(<./.lunabuild/rundata.txt)" -lt "$(($(date +%s) - 300))" ]; then
      getonlinedata
      echo "$(date +%s)" > ./.lunabuild/rundata.txt
  fi
else
  getonlinedata
  print "$welcome"
  echo "$(date +%s)" >> ./.lunabuild/rundata.txt
  exit
fi

log " - > - > DEBUG MESSAGES < - < - "
for arg in "$@"; do
    if [ "$arg" = "-ar" ]; then
        askrun=true
        log "Asking to run after successful build... (Due to args)"
    elif [ "$arg" = "-r" ]; then
        justrun=true
        log "Running after successful build... (Due to args)"
    elif [ "$arg" = "-c" ]; then
        cleanprebuild=false
        log "Not Cleaning Up Build Files... (Due to args)"
    elif [ "$arg" = "-d" ]; then
        set -x
        log "Debug mode enabled... (Due to args)"
    elif [ "$arg" = "-h" ]; [ "$arg" = "--help" ]; then
        print "$(cat ./.lunabuild/help.txt)" "green" "" "bold"
        rm -r ./temp
        exit
    elif [ "$arg" = "-w" ]; then
        rm -r ./temp
        clear
        print "\t\t~LunaBuild~" "magenta" "blue" "bold"
        print "\t     Powered by Bash ♥     " "cyan" "*" "blink"
        echo 
        print "$(cat ./.lunabuild/welcome.txt)" "" "" "bold"
        echo 
        print "$(cat ./.lunabuild/help.txt)" "green" "" "bold"
        echo 
        listdeps
        exit
    elif [ "$arg" = "-vd" ]; then
        listdeps
        exit
    elif [ "$arg" = "-reset" ]; then
        clear
        print "You have just requested a project reset! Are you sure?" "red" "white" "bold"
        print "This will reset your LunaBuild project to default!!" "red" "" "blink"
        print "Answer: (y/n)" "white" "red" "underline"
        read run
        run_lower=$(echo "$run" | tr '[:upper:]' '[:lower:]')
        if [ "$run_lower" = "y" ] || [ "$run_lower" = "yes" ]; then
            resetproject
            exit
        elif [ "$run_lower" = "n" ] || [ "$run_lower" = "no" ]; then
            echo "Cancelling."
        else
            echo "Invalid response. Please enter 'y', 'yes', 'n', or 'no'."
            echo "$run_lower"
        fi
      elif [ "$arg" = "-v" ]; then
        echo
        print "\t\t~LunaBuild~" "magenta" "blue" "bold"
        print "\t     Powered by Bash ♥     " "cyan" "*" "blink"
        divd
        print "       Version -=> $version      " "green" "black" "bold"
        print "Newest Version -=> $newestversion      " "green" "black" "bold"
        exit
    fi
    ifargs=true
done

# Check if the loop has executed at least once and perform the "once done" action
if [ "$ifargs" = true ]; then
    sleep 1.6
else
    log "No args provided for the script. 'Once done' action is not required."
fi
errors=false
function run {
    print "\t\t (Script below) " "green" "black" "bold"
    divd
    echo
    ./build/main
    echo
    divd
}
build() {
    local filename="$1"
    local file="./prebuild/$filename"
    local output="./build/${filename%???}"
    if [ "${filename: -3}" != ".sh" ]; then
        wrn "This is a bash Compiler script and only compiles .sh source code files, therefore '$filename ($file)' has been skipped. "
    else
        print " --> […] Build  | $filename" "green" "black" "bold"
        if [ -e "$file" ]; then
            shc -f "$file" -o ./build/"${filename%???}"
            if [ -e "$output" ]; then
                print " --> [✓] Built  | $filename" "green" "black" "bold"
                chmod +x ./build/"${filename%???}"
                log "No Issues Building File... ($filename @ $file)"
            else
                err "[☓] Failed | $filename"
                err "[☓] There was no file output for '$filename', check that the file exists or check that you are building the right one."
            fi
        else
            err "[☓] Failed | $filename"
            err "[☓] Failed | The source code '$filename' does not exist at '$file'."
            log "Attempted to build a file that doesn't exist... ($filename @ $file)"
        fi
    fi
}
function check_response() {
    local response="$1"
    response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [ "$response_lower" = "y" ] || [ "$response_lower" = "yes" ]; then
        run
    elif [ "$response_lower" = "n" ] || [ "$response_lower" = "no" ]; then
        echo ""
    else
        echo "Invalid response. Please enter 'y', 'yes', 'n', or 'no'."
    fi
}
function divd {
    print " > ------------------------------------ < " "black" "" "bold"
}

log " - > - > EXTRA LOGGING INFORMATION < - < -"
log "Built on a $os machine."
log " "
# Main Sequence
log " - > - > MAIN SEQUENCE < - < -"

clear
print "\t\t~LunaBuild~" "magenta" "blue" "bold"
print "\t     Powered by Bash ♥     " "cyan" "*" "blink"
divd
if [ -e "$buildversions_folder/versions" ]; then
    print "       Found Build Versions Folder.       " "green" "black" "bold"
else
    wrn "Build Folder Not Found... Making a new one."
    mkdir "$buildversions_folder"
    print "       Found Build Versions Folder.       " "green" "black" "bold"
fi
divd
highest_number=0
log "Adding old build into versions folder and cloning temp log to versions folder..."
for item in "$buildversions_folder/versions"/*/; do
    item=$(basename "$item")  # Extract the folder name from the full path
    if [[ $item =~ ^[0-9]+$ ]] && (( item > highest_number )); then
        highest_number=$item
    fi
done

# Increment the highest_number by 1 to get the next number
highest_number=$((highest_number + 1))
mkdir -p "$buildversions_folder/recent"
rm -r "$buildversions_folder/recent"
mkdir "$buildversions_folder/recent"
mkdir -p "$buildversions_folder/versions"
cp -r ./build/ "$buildversions_folder/recent/build/"
cp -r ./temp/"$log_file" "$buildversions_folder/recent"
cp -r "$buildversions_folder/recent" "$buildversions_folder/versions/$highest_number/"
print "\t     Saved old Build!     " "green" "black" "bold"
rm -r ./build
mkdir ./build
log "Cleaned build folder."
print "\t    Cleaned old Build!    " "green" "black" "bold"
if [ -e "./prebuild" ]; then
    rm -r ./prebuild
    log "Removing old prebuild folder to prevent unwanted errors."
fi
mkdir ./prebuild
if [ ${#files[@]} -gt 0 ]; then
    for file in "${files[@]}"; do
        echo "#!/bin/bash" > ./prebuild/"$file"
        cat ./src/"$file" >> ./prebuild/"$file"
        log "Adding shebang to file... (./src/"$file" >> ./prebuild/"$file")"
    done
else
    err "You listed no files to build."
fi
print "\t\t Cloned! " "green" "black" "bold"
divd
print "\t\t  Build:  " "yellow" "black" "bold"
print "\t\t Building " "green" "black" "bold"
divd
if [ ${#files[@]} -gt 0 ]; then
    for file in "${files[@]}"; do
        log "Attempting build on file '$file'"
        build "$file"
    done
else
    err "You listed no files to build."
fi
divd
print "\t\t  Built!  " "green" "black" "bold"
log " - > - > POST BUILD NOTICES < - < -"
if [ "$errors" = false ] && [ "$askrun" = true ] && [ "$justrun" = false ]; then
    divd
    print " Would you like to run main? " "white" "black" "bold"
    echo -n "(y/n) /> "
    read run &
    sleep 5
    if [ "$run" ]; then
        check_response "$run"
    else
        echo
        err "You didn't enter anything."
    fi
elif [ "$errors" = false ] && [ "$justrun" = true ]; then
    run
elif [ "$errors" = true ]; then
    print "\t       (With Errors)       " "red" "black" "bold"
    divd
fi
if [ -d ./temp ]; then
    rm -r ./prebuild
    rm -r ./temp
    print "\t\t Cleaned Up! " "green" "black" "bold"
    log "Cleaned build mess. Including prebuild files and temp files."
fi
echo
echo
print " LunaBuild | ~See ya again!~ ☺ " "" "blue" "bold"
set +x


# echo logs
if [ "$errors" = true ]; then
    log " -+=> ERRORS OCCURED <=+-"
fi
log " - > - > END < - < -"
for index in "${!logs[@]}"; do
    echo "${logs[index]}" >> ./"$log_file"
done
