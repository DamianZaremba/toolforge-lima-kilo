# shell
alias ll='ls -l --color=auto'
alias la='ls -la --color=auto'
alias vb='vim ~/.bashrc'
alias sb='source ~/.bashrc'
alias cd..='cd ..'

#grep
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# git
alias glo='git log --oneline'
alias gst='git status'
alias gbr='git branch'
alias gfe='git fetch'
alias gmg='git merge'
alias gsw='git switch'

# docker
alias dcu='docker-compose up -d'
alias dcub='docker-compose up -d --build'
alias dcd='docker-compose down'
alias dps='docker ps'

# misc
alias k='kubectl'
alias wget='wget -c'
alias deploy='toolforge_deploy_mr.py'
alias gwcurl='curl --cert /data/project/tf-test/.toolskube/client.crt --key /data/project/tf-test/.toolskube/client.key --insecure'
