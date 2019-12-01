#!/usr/bin/env bash

#######################################################################################
#
# build for single
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

wrapper_version=3.5.41.1
wrapper_name=wrapper-single-${wrapper_version}.tar.gz
wrapper_url=https://github.com/rancococ/wrapper/archive/single-${wrapper_version}.tar.gz

arch=x86_64

# build without jre
fun_build_without_jre() {
    header "build without jre start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-single

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-single && \

    find ${target_home}/wrapper-single | xargs touch && \
    find ${target_home}/wrapper-single -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-single -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-single/bin/* && \
    chmod 644 ${target_home}/wrapper-single/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-single/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-single/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-single/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-single/conf/*.password && \
    chmod 777 ${target_home}/wrapper-single/logs && \
    chmod 777 ${target_home}/wrapper-single/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-single-${wrapper_version}-all-${arch}.tar.gz wrapper-single

    \rm -rf ${uuid_home}

    success "build without jre success."
    return 0;
}

# build with jre linux
fun_build_with_jre_linux() {
    header "build without jre linux start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-single

    \cp -rf ${base_dir}/assets/${serverjre_linux} ${source_home}/server-jre.tar.gz && \
    tar -zxf ${source_home}/server-jre.tar.gz -C ${source_home} && \
    jrename=$(tar -tf ${source_home}/server-jre.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${jrename}/jre ${target_home}/wrapper-single/jre && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${target_home}/wrapper-single/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${target_home}/wrapper-single/jre/lib/security/java.security" && \

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-single && \

    find ${target_home}/wrapper-single | xargs touch && \
    find ${target_home}/wrapper-single -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-single -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-single/jre/bin/* && \
    chmod 744 ${target_home}/wrapper-single/bin/* && \
    chmod 644 ${target_home}/wrapper-single/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-single/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-single/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-single/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-single/conf/*.password && \
    chmod 777 ${target_home}/wrapper-single/logs && \
    chmod 777 ${target_home}/wrapper-single/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-single-${wrapper_version}-jre-linux-${arch}.tar.gz wrapper-single

    \rm -rf ${uuid_home}

    success "build without jre linux success."
    return 0;
}

# build with jre windows
fun_build_with_jre_windows() {
    header "build without jre windows start..."

    \rm -rf ${uuid_home}

    mkdir -p ${source_home} && \
    mkdir -p ${target_home}/wrapper-single

    \cp -rf ${base_dir}/assets/${serverjre_windows} ${source_home}/server-jre.tar.gz && \
    tar -zxf ${source_home}/server-jre.tar.gz -C ${source_home} && \
    jrename=$(tar -tf ${source_home}/server-jre.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${jrename}/jre ${target_home}/wrapper-single/jre && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${target_home}/wrapper-single/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${target_home}/wrapper-single/jre/lib/security/java.security" && \

    \cp -rf ${base_dir}/assets/${wrapper_name} ${source_home}/wrapper.tar.gz && \
    tar -zxf ${source_home}/wrapper.tar.gz -C ${source_home} && \
    wrappername=$(tar -tf ${source_home}/wrapper.tar.gz | awk -F "/" '{print $1}' | sed -n '1p') && \
    \cp -rf ${source_home}/${wrappername}/. ${target_home}/wrapper-single && \

    find ${target_home}/wrapper-single | xargs touch && \
    find ${target_home}/wrapper-single -type d -print | xargs chmod 755 && \
    find ${target_home}/wrapper-single -type f -print | xargs chmod 644 && \

    chmod 744 ${target_home}/wrapper-single/jre/bin/* && \
    chmod 744 ${target_home}/wrapper-single/bin/* && \
    chmod 644 ${target_home}/wrapper-single/bin/*.bat && \
    chmod 644 ${target_home}/wrapper-single/bin/*.exe && \
    chmod 644 ${target_home}/wrapper-single/bin/*.jar && \
    chmod 644 ${target_home}/wrapper-single/bin/*.cnf && \
    chmod 600 ${target_home}/wrapper-single/conf/*.password && \
    chmod 777 ${target_home}/wrapper-single/logs && \
    chmod 777 ${target_home}/wrapper-single/temp

    mkdir -p ${base_dir}/release
    tar -C ${target_home} -czf ${base_dir}/release/wrapper-single-${wrapper_version}-jre-windows-${arch}.tar.gz wrapper-single

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
