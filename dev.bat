@echo off
setlocal enabledelayedexpansion

git pull origin dev
git add .
git commit -m "test deploy error rollback"
git push origin dev


echo "Changes successfully pushed to dev branch."
