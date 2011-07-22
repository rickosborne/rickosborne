#!/bin/sh

REPO_NAME=$1
REPO_WWW=$2
if [ -z "${REPO_WWW}" ] ; then
    REPO_WWW="${REPO_NAME}"
fi
WWW_ROOT=/var/www/${REPO_WWW}
GIT_DIR=/home/git/repositories/${REPO_NAME}.git
PU_TMPL=/home/git/post-update.template
PU_REPO=${GIT_DIR}/hooks/post-update
GIT_CONFIG=${GIT_DIR}/config
TMP_DIR=/home/git/tmp/${REPO_NAME}

show_help() {
    echo $1
    exit
}

if [ -z "${REPO_NAME}" ] ; then
    show_help "Usage: $0 reponame [www-dirname]"
fi

if [ ! -d "${GIT_DIR}" ] ; then
    show_help "Couldn't find ${REPO_NAME} as ${GIT_DIR} directory."
fi

git_own() {
    echo "Fixing ownership to git:git for $1"
    chown -R git:git $1
}

mkdir_loud() {
    if [ -d "$1" ] ; then
        echo "The $1 directory already exists."
    else
        echo "Creating $1 directory."
        mkdir -p $1
    fi
}

make_pu() {
    echo "Building the $1 post-update hook as 32."
    echo "#!/bin/sh" > $3
    echo "REPO_NAME=$1" >> $3
    echo "REPO_WWW=$2" >> $3
    cat $PU_TMPL >> $3
}

git_ini_set() {
    echo "Setting $1.$2 to $3 in Git config."
    git --git-dir=$4 config $1.$2 $3
}

echo "=== Webifying repo ${REPO_NAME} to ${WWW_ROOT}"

mkdir_loud $WWW_ROOT
make_pu $REPO_NAME $REPO_WWW $PU_REPO
chmod -v 0744 $PU_REPO

git_ini_set core bare false $GIT_DIR
git_ini_set core worktree $TMP_DIR $GIT_DIR
git_ini_set receive denycurrentbranch ignore $GIT_DIR

git_own $WWW_ROOT
# git_own $PU_REPO
git_own $GIT_DIR

echo "=== The repository has been webified."
echo "=== Push another commit to start the first checkout."
