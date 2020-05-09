set -e

URL=https://raw.githubusercontent.com/jeromedecoster/soulseek/master

log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; }
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; }

CWD=$(pwd)
TEMP=$(mktemp --directory)

info create from merged files
cd $TEMP

for file in xaa xab xac xad xae xaf xag
do
    log download $URL/$file
    if [[ -n $(which curl) ]]
    then
        curl $URL/$file \
            --location \
            --remote-name \
            --progress-bar
    else
        wget $URL/$file \
            --quiet \
            --show-progress
    fi
done

log merge xa* as archive.zip
cat xa* > archive.zip

log md5 check
[[ $(md5sum archive.zip | cut -d ' ' -f 1) != 6bd26482565d1f281b79d21bb85b85bc ]] \
    && { error md5 checksum error; exit; }

log unzip archive.zip
unzip archive.zip

# inline the filenames in the zip
CONTENT=$(unzip -l archive.zip \
    | tail -n +4 \
    | head -n -2 \
    | sed -E 's|^.*:[0-9]*\s*||' \
    | tr '\t' ' ')

# check if $CWD is writable by the user
if [[ -z $(sudo --user $(whoami) --set-home bash -c "[[ -w $CWD ]] && echo 1;") ]]
then
    warn warn sudo access is required
    sudo mv $CONTENT $CWD
else
    mv $CONTENT $CWD
fi

info created $CONTENT

rm --force --recursive $TEMP
