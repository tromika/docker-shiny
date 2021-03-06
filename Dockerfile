FROM r-base:3.2.5

MAINTAINER "Tamas Szuromi" tamas@metricbrew.com

RUN apt-get update && apt-get install -y \
    sudo \
    cmake \
    checkinstall \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libmysqlclient-dev \
    libxml2-dev \
    libssl-dev \
    curl \
    wget \
    git



RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 0.10.45

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
	&& curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --verify SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
	&& tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc


RUN git config --global http.sslVerify false

WORKDIR /tmp


# Download and install shiny server


RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb




#Install packages

RUN R -e "install.packages(c('shiny', 'shinydashboard', 'data.table', 'dplyr', 'lubridate', 'ggvis', 'reshape2', 'rmarkdown', 'devtools', 'scales', 'RMySQL', 'htmlwidgets', 'shinyjs', 'DT', 'zoo', 'data.tree'), repos='http://cran.rstudio.com/')"
RUN R -e "devtools::install_github('tromika/rCharts', build_vignettes = FALSE)"
RUN R -e "devtools::install_github('smartinsightsfromdata/rpivotTable', build_vignettes = FALSE)"
RUN R -e "devtools::install_github('hadley/lazyeval', build_vignettes = FALSE)"
RUN R -e "devtools::install_github('ropensci/plotly', build_vignettes = FALSE)"
RUN R -e "devtools::install_github('aoles/shinyURL', build_vignettes = FALSE)"
RUN R -e "devtools::install_github('hadley/purrr', ref= 'v0.2.2',build_vignettes = FALSE)"
RUN R -e "devtools::install_github('jbkunst/highcharter', ref='v0.3.1',build_vignettes = FALSE)"

EXPOSE 3838



# Create log, config, and application directories
RUN  mkdir -p /var/log/shiny-server
RUN  mkdir -p /srv/shiny-server
RUN  mkdir -p /var/lib/shiny-server
RUN chmod 777 /var/log/shiny-server
RUN mkdir -p /etc/shiny-server

RUN wget\
  https://raw.githubusercontent.com/rstudio/shiny-server/master/config/default.config\
  -O /etc/shiny-server/shiny-server.conf

COPY shiny-server.sh  /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
