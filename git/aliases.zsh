## Fetch prune, pull and clean-up branches except main
alias gg="git fetch --prune && git pull &&  git branch | grep -v main | xargs git branch -D"