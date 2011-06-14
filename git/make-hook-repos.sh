#!/bin/bash

LOCAL_REPO='local'
REMOTE_REPO='remote.git'
REMOTE_WORK='remote-www'
REMOTE_TEMP='remote-tmp'
CWD=`pwd`

git_ini_set() {
    # echo "*** Setting $1.$2 to $3 in Git config."
    git --git-dir=$4 config $1.$2 $3
}

echo '*** Setting up repos for CFWDUG1107'
if [ -d "${LOCAL_REPO}" ] ; then
    echo '*** Removing old local repo'
    rm -Rf "${LOCAL_REPO}"
fi
if [ -d "${REMOTE_REPO}" ] ; then
    echo '*** Removing old remote repo'
    rm -Rf "${REMOTE_REPO}"
fi
mkdir -p "${REMOTE_WORK}"
mkdir -p "${REMOTE_TEMP}"

echo "*** Making remote repo as: ${REMOTE_REPO}"
git init -q --bare "${REMOTE_REPO}"
git_ini_set core bare false "${REMOTE_REPO}"
git_ini_set core worktree "${CWD}/${REMOTE_WORK}" "${REMOTE_REPO}"
git_ini_set receive denycurrentbranch ignore "${REMOTE_REPO}"
cat > "${REMOTE_REPO}/hooks/update" <<HOOK_UPDATE
#!/bin/sh
echo "Remote: update '\$1' '\$2' '\$3'"
exit 0
HOOK_UPDATE
chmod u+x "${REMOTE_REPO}/hooks/update"
cat > "${REMOTE_REPO}/hooks/post-update" <<HOOK_POSTUPDATE
#!/bin/sh
echo "Remote: post-update '\$1'"
# Only deploy the master branch
if [ ! "\$1" = "refs/heads/master" ] ; then
    exit 0
fi
GIT_REPO="${CWD}/${REMOTE_REPO}"
PUBLIC_WWW="${CWD}/${REMOTE_WORK}"
WWW_TMP="${CWD}/${REMOTE_TEMP}"

rm -Rf "\$WWW_TMP"
mkdir -p "\$WWW_TMP"
cd "\$GIT_REPO"
git checkout -q -f master
cp -R "\$WWW_TMP/*" "\$PUBLIC_WWW/" 2> nul
cp -R "\$WWW_TMP/.[a-zA-Z0-9]*" "\$PUBLIC_WWW/" 2> nul
# chown -R git:git "\$PUBLIC_WWW"
chmod -R a-x+X+r,g-w,o-w,u+w "\$PUBLIC_WWW"
rm -Rf "\$WWW_TMP"
echo 'Remote: Deployed to ${REMOTE_WORK}'
exit 0
HOOK_POSTUPDATE
chmod u+x "${REMOTE_REPO}/hooks/post-update"
cat > "${REMOTE_REPO}/hooks/pre-receive" <<HOOK_PRERECEIVE
#!/bin/sh
echo "Remote: pre-receive"
LINE="-"
while [ ! -z "\$LINE" ] ; do
    read LINE
    if [ ! -z "\$LINE" ] ; then
        echo " stdin: \${LINE}"
    fi
done
exit 0
HOOK_PRERECEIVE
chmod u+x "${REMOTE_REPO}/hooks/pre-receive"
cat > "${REMOTE_REPO}/hooks/post-receive" <<HOOK_POSTRECEIVE
#!/bin/sh
echo "Remote: post-receive"
LINE="-"
while [ ! -z "\$LINE" ] ; do
    read LINE
    if [ ! -z "\$LINE" ] ; then
        echo " stdin: \${LINE}"
    fi
done
exit 0
HOOK_POSTRECEIVE
chmod u+x "${REMOTE_REPO}/hooks/post-receive"

echo "*** Creating local repo as: ${LOCAL_REPO}"
mkdir -p "${LOCAL_REPO}"
cd "${LOCAL_REPO}"
git init -q
git remote add origin "${CWD}/${REMOTE_REPO}"
git remote add remote "${CWD}/${REMOTE_REPO}"
git remote add production "${CWD}/${REMOTE_REPO}"
cat > ".git/hooks/pre-commit" <<HOOK_PRECOMMIT
#!/bin/sh
echo "Local: pre-commit"
# This hook script modified by Rick Osborne from the original
# hook script in the Git distribution.  The licenses from the
# Git distribution apply to this script.

if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# If you want to allow non-ascii filenames set this variable to true.
allownonascii=\$(git config hooks.allownonascii)

if [ "\$allownonascii" != "true" ] &&
	test "\$(git diff --name-only --cached | grep -Eve '^[a-zA-Z0-9 /_.]+\$')"
then
	echo "Error: Attempt to add a non-ascii file name:"
	git diff --name-only --cached | grep -Eve '^[a-zA-Z0-9 /_.]+\$'
	echo
	echo "This can cause problems if you want to work"
	echo "with people on other platforms."
	echo
	echo "You will not be able to commit this file as-is."
	echo "Rename your file to use: a-z, A-Z, 0-9, _, ."
	echo
	exit 1
fi

if test "\$(git diff --name-only --cached | grep -Ee ' [ .]|^ | \$')"
then
	echo "Error: Attempt to add a file with bad spaces"
	git diff --name-only --cached | grep -Ee ' [ .]|^ | \$'
	echo
	echo "This can cause problems if you want to work"
	echo "with people on other platforms."
	echo
	echo "You will not be able to commit this file as-is."
	echo "Rename your file to not use weird spaces"
	echo
	exit 1
fi

exec git diff-index --check --cached \$against --
exit 0
HOOK_PRECOMMIT
chmod u+x ".git/hooks/pre-commit"
cat > ".git/hooks/prepare-commit-msg" <<HOOK_PREPARECOMMITMSG
#!/bin/sh
echo "Local: prepare-commit-msg '\$1' '\$2' '\$3'"
exit 0
HOOK_PREPARECOMMITMSG
chmod u+x ".git/hooks/prepare-commit-msg"
cat > ".git/hooks/commit-msg" <<HOOK_COMMITMSG
#!/bin/sh
echo "Local: commit-msg '\$1'"
COMMIT_MSG=\`cat "\$1"\`
echo "  msg: \${COMMIT_MSG}"
RUBYTALK=\`grep -Eie 'ruby' "\${1}"\`
if [ ! -z "\${RUBYTALK}" ] ; then
    echo "Error: Bad commit message."
    echo "Please don't talk about Ruby in your commit messages."
    exit 1
fi
exit 0
HOOK_COMMITMSG
chmod u+x ".git/hooks/commit-msg"
cat > ".git/hooks/post-commit" <<HOOK_POSTCOMMIT
#!/bin/sh
echo "Local: post-commit"
exit 0
HOOK_POSTCOMMIT
chmod u+x ".git/hooks/post-commit"
cat > ".git/hooks/post-checkout" <<HOOK_POSTCHECKOUT
#!/bin/sh
echo "Local: post-checkout"
exit 0
HOOK_POSTCHECKOUT
chmod u+x ".git/hooks/post-checkout"
cat > ".git/hooks/post-merge" <<HOOK_POSTMERGE
#!/bin/sh
echo "Local: post-merge"
exit 0
HOOK_POSTMERGE
chmod u+x ".git/hooks/post-merge"
cat > index.html <<INDEX_HTML
<!doctype html>
<html>
<head><title>Git Deployment Test</title></head>
<body>
<h1>Frickin' MAGIC</h1>
</body>
</html>
INDEX_HTML
git add .
git commit -qam 'Initial repo setup' 2> /dev/null > /dev/null
git push -q --all origin 2> /dev/null > /dev/null
cd ..
