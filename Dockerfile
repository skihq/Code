FROM ubuntu:bionic

RUN apt-get update \
 && apt-get install -y \
    curl \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    cron \
    git \
    wget \
    procps \
    sudo \
    ssh \
    aria2 \
    speedtest-cli \
    python \
    httpie \
    python-pip \
    python3 \
    python3-pip \
    screen \
    wget \
    zip \
    unzip \
    openssl \
    pkg-config \
    apt-utils \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

#Locale Installation
# https://wiki.debian.org/Locale#Manually
RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8

RUN chsh -s /bin/bash
ENV SHELL=/bin/bash

RUN adduser --gecos '' --disabled-password coder && \
  echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

RUN cd /tmp && \
  curl -L --silent \
  `curl --silent "https://api.github.com/repos/cdr/code-server/releases/latest" \
    | grep '"browser_download_url":' \
    | grep "linux-amd64" \
    |  sed -E 's/.*"([^"]+)".*/\1/' \
  `| tar -xzf - && \
  mv code-server* /usr/local/lib/code-server && \
  ln -s /usr/local/lib/code-server/bin/code-server /usr/local/bin/code-server && \
  rm /usr/local/lib/code-server/lib/vscode/product.json && \
  wget https://vsext.netlify.app/config-files/product.json && \
  mv product.json /usr/local/lib/code-server/lib/vscode/

USER coder
WORKDIR /home/coder

# Running Direct Installers 
#For Heroku CLI
RUN curl https://cli-assets.heroku.com/install.sh | sudo sh && \
    #For Fly.io
    curl -L https://fly.io/install.sh | sh && \
    # For Deta.sh
    curl -fsSL https://get.deta.dev/cli.sh | sh && \
    #For Railway
    sudo sh -c "$(curl -sSL https://raw.githubusercontent.com/railwayapp/cli/master/install.sh)"

#Using Direct Installers
#Install Starship
RUN wget -q https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz && \
    tar -zxvf starship*.tar.gz && \
    sudo cp starship /usr/bin/ && \
    rm starship-x86_64-unknown-linux-gnu.tar.gz starship && \
    #Install ffsend
    curl -s https://api.github.com/repos/timvisee/ffsend/releases/latest \
    | grep "browser_download_url.*linux-x64-static" \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    mv ffsend-* ffsend && chmod a+x ffsend && \
    sudo mv ffsend /usr/bin/ && \
    #Install Github (GH) CLI
    curl -s https://api.github.com/repos/cli/cli/releases/latest \
    | grep "browser_download_url.*amd64.deb" \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    sudo apt install ./gh_*_linux_amd64.deb && rm gh_*_linux_amd64.deb && \
    #For MongoSH
    curl -s https://api.github.com/repos/mongodb-js/mongosh/releases/latest \
    | grep "browser_download_url.*amd64.deb" \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    sudo dpkg -i mongodb*amd64.deb && rm mongodb*amd64.deb && \
    #For Cloudlfared
    curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest \
    | grep "browser_download_url.*linux-amd64" \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    mv cloudflared-linux-amd64 cloudflared && chmod a+x cloudflared && \
    sudo mv cloudflared /usr/bin/ && \
    #For Planetsclae
    curl -s https://api.github.com/repos/planetscale/cli/releases/latest \
    | grep "browser_download_url.*amd64.deb" \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    sudo dpkg -i pscale*amd64.deb && rm pscale*amd64.deb

#Setting Up Node
#Installing Node (LTS) & NPM (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_15.x | sudo -E bash - && sudo apt-get install -y nodejs && \
    #Install Appliactions Using NPM
    sudo npm install -g spt-cli \
                        flipacoin \
                        netlify-cli \
                        vercel \
                        npm

#Installing Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    sudo apt-get update && sudo apt-get install -y yarn


#Configuration Files
RUN pwd && sudo git clone https://abhay-ranawat:69d5b2d59459556aa514e1313316de60e6da3aab@github.com/abhay-ranawat/config-files && \
    cd config-files && sudo cp .fly .deta .local .netlify .gitconfig .netrc .config gitcdr/.bashrc gitcdr/.bash_aliases .git-credentials .cloudflared /home/coder/ -r && \
    sudo wget -q https://vsext.netlify.app/cs/csgit.zip && sudo unzip -q csgit.zip && sudo rm csgit.zip && sudo mv code-server /home/coder/.local/share/ && \
    sudo mkdir /home/coder/cdr && cd .. && sudo rm -rf config-files

#Install Extensions
RUN sudo code-server --force --install-extension eamodio.gitlens && \
    sudo code-server --force --install-extension github.github-vscode-theme && \
    sudo code-server --force --install-extension esbenp.prettier-vscode && \
    sudo code-server --force --install-extension miguelsolorio.fluent-icons && \
    sudo code-server --force --install-extension pkief.material-icon-theme

COPY run.sh /run.sh
ENTRYPOINT ["/run.sh"]
