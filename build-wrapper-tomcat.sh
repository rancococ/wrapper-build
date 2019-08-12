#!/usr/bin/env bash

#######################################################################################
#
# build for tomcat
#
#######################################################################################

#set -x
set -e
set -o noglob

#
# font and color 
#
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

#
# header and logging
#
header() { printf "\n${underline}${bold}${blue}> %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}>> %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

#
# trap signal
#
trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

#
# entry base dir
#
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd "${base_dir}"

uuid_name="$(cat /proc/sys/kernel/random/uuid)"
uuid_home=/tmp/${uuid_name}
source_home=/tmp/${uuid_name}/source
target_home=/tmp/${uuid_name}/target

serverjre_linux=server-jre-8u192-linux-x64.tar.gz
serverjre_windows=server-jre-8u192-windows-x64.tar.gz

wrapper_version=3.5.39.2
wrapper_name=wrapper-3.5.39.2.tar.gz
wrapper_url=https://github.com/rancococ/wrapper/archive/v3.5.39.2.tar.gz

jmx_exporter_version=0.12.0
jmx_exporter_url=https://mirrors.huaweicloud.com/repository/maven/io/prometheus/jmx/jmx_prometheus_javaagent/${jmx_exporter_version}/jmx_prometheus_javaagent-${jmx_exporter_version}.jar

tomcat_url=https://mirrors.huaweicloud.com/apache/tomcat/tomcat-8/v8.5.40/bin/apache-tomcat-8.5.40.tar.gz
tomcat_juli_url=https://mirrors.huaweicloud.com/apache/tomcat/tomcat-8/v8.0.53/bin/extras/tomcat-juli.jar
tomcat_juli_adapters_url=https://mirrors.huaweicloud.com/apache/tomcat/tomcat-8/v8.0.53/bin/extras/tomcat-juli-adapters.jar
catalina_jmx_remote_url=https://mirrors.huaweicloud.com/apache/tomcat/tomcat-8/v8.5.40/bin/extras/catalina-jmx-remote.jar
catalina_ws_url=https://mirrors.huaweicloud.com/apache/tomcat/tomcat-8/v8.5.40/bin/extras/catalina-ws.jar
tomcat_extend_url=https://github.com/rancococ/tomcat-ext/releases/download/v1.0.0/tomcat-extend-1.0.0-SNAPSHOT.jar
log4j2_url=https://mirrors.huaweicloud.com/apache/logging/log4j/2.11.1/apache-log4j-2.11.1-bin.tar.gz

tomcat_version=8.5.40.9

arch=x86_64

# build without jre
fun_build_without_jre() {
    header "build without jre start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-tomcat && \
    mkdir -p ${target_home}/wrapper-tomcat/exporter && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps/ROOT

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-tomcat && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-property.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-property.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-additional.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-additional.conf && \
    \rm -rf ${target_home}/wrapper-tomcat/conf/*.temp && \

    wget -c -O ${target_home}/wrapper-tomcat/exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar --no-check-certificate ${jmx_exporter_url} && \
    \cp -rf ${base_dir}/assets/jmx_exporter.yml ${target_home}/wrapper-tomcat/exporter/ && \
    sed -i "/^-server$/i\-javaagent:../exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar=8090:../exporter/jmx_exporter.yml" "${target_home}/wrapper-tomcat/conf/wrapper-additional.conf" && \

    wget -c -O ${source_home}/tomcat.tar.gz --no-check-certificate ${tomcat_url} && \
    tar -zxf ${source_home}/tomcat.tar.gz -C ${source_home} && \
    tomcatname=$(tar -tf ${source_home}/tomcat.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${tomcatname}/conf/catalina.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/logging.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/server.xml && \
    \cp -rf ${source_home}/${tomcatname}/bin/bootstrap.jar ${target_home}/wrapper-tomcat/bin/ && \
    \cp -rf ${source_home}/${tomcatname}/conf/. ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${source_home}/${tomcatname}/lib/. ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${base_dir}/assets/catalina.properties ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/web.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/server.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/log4j2.xml ${target_home}/wrapper-tomcat/lib/ && \

    wget -c -O ${target_home}/wrapper-tomcat/bin/tomcat-juli.jar --no-check-certificate ${tomcat_juli_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-juli-adapters.jar --no-check-certificate ${tomcat_juli_adapters_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-jmx-remote.jar --no-check-certificate ${catalina_jmx_remote_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-ws.jar --no-check-certificate ${catalina_ws_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-extend.jar --no-check-certificate ${tomcat_extend_url} && \

    wget -c -O ${source_home}/log4j2.tar.gz --no-check-certificate ${log4j2_url} && \
    tar -zxf ${source_home}/log4j2.tar.gz -C ${source_home} && \
    log4j2name=$(tar -tf ${source_home}/log4j2.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${log4j2name}/*-javadoc.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-sources.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-tests.jar && \
    \cp -rf ${source_home}/${log4j2name}/log4j-1.2-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-core-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-web-*.jar ${target_home}/wrapper-tomcat/lib/ && \

    find ${target_home}/wrapper-tomcat | xargs touch && \
    find ${target_home}/wrapper-tomcat -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-tomcat -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-tomcat/bin/* && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-tomcat/conf/*.password && \
    chmod 777 ${target_home}/wrapper-tomcat/logs && \
    chmod 777 ${target_home}/wrapper-tomcat/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-${wrapper_version}-tomcat-${tomcat_version}-all-${arch}.tar.gz wrapper-tomcat

    \rm -rf ${uuid_home}

    success "build without jre success."
    return 0;
}


# build with jre linux
fun_build_with_jre_linux() {
    header "build without jre linux start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-tomcat && \
    mkdir -p ${target_home}/wrapper-tomcat/exporter && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps/ROOT

    \cp -rf ${base_dir}/assets/${serverjre_linux} ${source_home}/server-jre.tar.gz && \
    tar -zxf ${source_home}/server-jre.tar.gz -C ${source_home} && \
    jrename=$(tar -tf ${source_home}/server-jre.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${jrename}/jre ${target_home}/wrapper-tomcat/jre && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${target_home}/wrapper-tomcat/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${target_home}/wrapper-tomcat/jre/lib/security/java.security" && \

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-tomcat && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-property.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-property.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-additional.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-additional.conf && \
    \rm -rf ${target_home}/wrapper-tomcat/conf/*.temp && \

    wget -c -O ${target_home}/wrapper-tomcat/exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar --no-check-certificate ${jmx_exporter_url} && \
    \cp -rf ${base_dir}/assets/jmx_exporter.yml ${target_home}/wrapper-tomcat/exporter/ && \
    sed -i "/^-server$/i\-javaagent:../exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar=8090:../exporter/jmx_exporter.yml" "${target_home}/wrapper-tomcat/conf/wrapper-additional.conf" && \

    wget -c -O ${source_home}/tomcat.tar.gz --no-check-certificate ${tomcat_url} && \
    tar -zxf ${source_home}/tomcat.tar.gz -C ${source_home} && \
    tomcatname=$(tar -tf ${source_home}/tomcat.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${tomcatname}/conf/catalina.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/logging.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/server.xml && \
    \cp -rf ${source_home}/${tomcatname}/bin/bootstrap.jar ${target_home}/wrapper-tomcat/bin/ && \
    \cp -rf ${source_home}/${tomcatname}/conf/. ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${source_home}/${tomcatname}/lib/. ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${base_dir}/assets/catalina.properties ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/web.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/server.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/log4j2.xml ${target_home}/wrapper-tomcat/lib/ && \

    wget -c -O ${target_home}/wrapper-tomcat/bin/tomcat-juli.jar --no-check-certificate ${tomcat_juli_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-juli-adapters.jar --no-check-certificate ${tomcat_juli_adapters_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-jmx-remote.jar --no-check-certificate ${catalina_jmx_remote_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-ws.jar --no-check-certificate ${catalina_ws_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-extend.jar --no-check-certificate ${tomcat_extend_url} && \

    wget -c -O ${source_home}/log4j2.tar.gz --no-check-certificate ${log4j2_url} && \
    tar -zxf ${source_home}/log4j2.tar.gz -C ${source_home} && \
    log4j2name=$(tar -tf ${source_home}/log4j2.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${log4j2name}/*-javadoc.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-sources.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-tests.jar && \
    \cp -rf ${source_home}/${log4j2name}/log4j-1.2-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-core-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-web-*.jar ${target_home}/wrapper-tomcat/lib/ && \

    find ${target_home}/wrapper-tomcat | xargs touch && \
    find ${target_home}/wrapper-tomcat -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-tomcat -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-tomcat/jre/bin/* && \
    chmod 744 ${target_home}/wrapper-tomcat/bin/* && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-tomcat/conf/*.password && \
    chmod 777 ${target_home}/wrapper-tomcat/logs && \
    chmod 777 ${target_home}/wrapper-tomcat/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-${wrapper_version}-tomcat-${tomcat_version}-jre-linux-${arch}.tar.gz wrapper-tomcat

    \rm -rf ${uuid_home}

    success "build without jre linux success."
    return 0;
}

# build with jre windows
fun_build_with_jre_windows() {
    header "build without jre windows start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-tomcat && \
    mkdir -p ${target_home}/wrapper-tomcat/exporter && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps && \
    mkdir -p ${target_home}/wrapper-tomcat/webapps/ROOT

    \cp -rf ${base_dir}/assets/${serverjre_windows} ${source_home}/server-jre.tar.gz && \
    tar -zxf ${source_home}/server-jre.tar.gz -C ${source_home} && \
    jrename=$(tar -tf ${source_home}/server-jre.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${jrename}/jre ${target_home}/wrapper-tomcat/jre && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${target_home}/wrapper-tomcat/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${target_home}/wrapper-tomcat/jre/lib/security/java.security" && \

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-tomcat && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-property.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-property.conf && \
    \cp -rf ${target_home}/wrapper-tomcat/conf/wrapper-additional.tomcat.temp ${target_home}/wrapper-tomcat/conf/wrapper-additional.conf && \
    \rm -rf ${target_home}/wrapper-tomcat/conf/*.temp && \

    wget -c -O ${target_home}/wrapper-tomcat/exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar --no-check-certificate ${jmx_exporter_url} && \
    \cp -rf ${base_dir}/assets/jmx_exporter.yml ${target_home}/wrapper-tomcat/exporter/ && \
    sed -i "/^-server$/i\-javaagent:../exporter/jmx_prometheus_javaagent-${jmx_exporter_version}.jar=8090:../exporter/jmx_exporter.yml" "${target_home}/wrapper-tomcat/conf/wrapper-additional.conf" && \

    wget -c -O ${source_home}/tomcat.tar.gz --no-check-certificate ${tomcat_url} && \
    tar -zxf ${source_home}/tomcat.tar.gz -C ${source_home} && \
    tomcatname=$(tar -tf ${source_home}/tomcat.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${tomcatname}/conf/catalina.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/logging.properties && \
    \rm -rf ${source_home}/${tomcatname}/conf/server.xml && \
    \cp -rf ${source_home}/${tomcatname}/bin/bootstrap.jar ${target_home}/wrapper-tomcat/bin/ && \
    \cp -rf ${source_home}/${tomcatname}/conf/. ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${source_home}/${tomcatname}/lib/. ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${base_dir}/assets/catalina.properties ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/web.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/server.xml ${target_home}/wrapper-tomcat/conf/ && \
    \cp -rf ${base_dir}/assets/log4j2.xml ${target_home}/wrapper-tomcat/lib/ && \

    wget -c -O ${target_home}/wrapper-tomcat/bin/tomcat-juli.jar --no-check-certificate ${tomcat_juli_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-juli-adapters.jar --no-check-certificate ${tomcat_juli_adapters_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-jmx-remote.jar --no-check-certificate ${catalina_jmx_remote_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/catalina-ws.jar --no-check-certificate ${catalina_ws_url} && \
    wget -c -O ${target_home}/wrapper-tomcat/lib/tomcat-extend.jar --no-check-certificate ${tomcat_extend_url} && \

    wget -c -O ${source_home}/log4j2.tar.gz --no-check-certificate ${log4j2_url} && \
    tar -zxf ${source_home}/log4j2.tar.gz -C ${source_home} && \
    log4j2name=$(tar -tf ${source_home}/log4j2.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \rm -rf ${source_home}/${log4j2name}/*-javadoc.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-sources.jar && \
    \rm -rf ${source_home}/${log4j2name}/*-tests.jar && \
    \cp -rf ${source_home}/${log4j2name}/log4j-1.2-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-api-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-core-*.jar ${target_home}/wrapper-tomcat/lib/ && \
    \cp -rf ${source_home}/${log4j2name}/log4j-web-*.jar ${target_home}/wrapper-tomcat/lib/ && \

    find ${target_home}/wrapper-tomcat | xargs touch && \
    find ${target_home}/wrapper-tomcat -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-tomcat -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-tomcat/jre/bin/* && \
    chmod 744 ${target_home}/wrapper-tomcat/bin/* && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-tomcat/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-tomcat/conf/*.password && \
    chmod 777 ${target_home}/wrapper-tomcat/logs && \
    chmod 777 ${target_home}/wrapper-tomcat/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-${wrapper_version}-tomcat-${tomcat_version}-jre-windows-${arch}.tar.gz wrapper-tomcat

    \rm -rf ${uuid_home}

    success "build without jre windows success."
    return 0;
}

# entry base dir
cd "${base_dir}"

# build without jre
fun_build_without_jre
# build with jre linux
fun_build_with_jre_linux
# build with jre windows
fun_build_with_jre_windows

cd "${base_dir}"

success "complete."

exit $?
