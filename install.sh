#!/bin/bash
echo  'install pong'
sys_os="unsupported"
sys_arch="unknown"
sys_arm=""

app_name="pong"
app_ver="0.9.1"
app_service="pong.service"
app_file_ext=".tar.gz"
app_site="https://github.com/pingworlds"

https://github.com/pingworlds/pong/releases/latest/download/package.zip.


app_bin="$app_name"
app_path="/usr/local/${app_name}"
app_source="${app_site}/${app_name}"

app_source="${app_site}/pong-install/release/download"
app_release="${app_site}/${app_name}/releases/download"
# app_release="${app_site}/${app_name}/"
echo  "os type:$OSTYPE" 
check_sys(){ 
    unamem="$(uname -m)"
    echo  "usname:$unamem"    
	if [[ $unamem == *aarch64* ]]; then
		sys_arch="arm64"
	elif [[ $unamem == *x86_64* ]]; then
		sys_arch="amd64"
	elif [[ $unamem == *86* ]]; then
		sys_arch="i386" 
	elif [[ $unamem == *armv5* ]]; then
		sys_arch="arm"
		sys_arm="v5"
	elif [[ $unamem == *armv6l* ]]; then
		sys_arch="arm"
		sys_arm="v6"
	elif [[ $unamem == *armv7l* ]]; then
		sys_arch="arm"
		sys_arm="v7"
	else
		echo "Aborted, no release version for architecture: $unamem."  
        echo "please try compile and install from source code, $app_source"
		exit 1
	fi

     

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ ${unameu} == *DARWIN* ]]; then
		sys_os="darwin"	  
	elif [[ ${unameu} == *LINUX* ]]; then
		sys_os="linux" 
    elif [[ ${unameu} == *FREEBSD* ]]; then
		sys_os="freebsd"
	elif [[ ${unameu} == *OPENBSD* ]]; then
		sys_os="openbsd"
	elif [[ ${unameu} == *WIN* ]]; then	 
		sys_os="windows" 
        app_file_ext=".zip"
        app_bin="${app_name}.exe"
	else
		echo "Aborted, no release version for current os: $unameu."
        echo "please try compile and install from source code, $app_source"
		exit 1
	fi
}

check_sys
 
echo  "current os:$sys_os arch:$sys_arch"
echo  "${app_name} install path:$app_path  bin:${app_bin}  file_ext:$app_file_ext" 

app_file_name="${app_name}_${app_ver}_${sys_os}_${sys_arch}${sys_arm}"
# dl_url="${app_release}/v${app_ver}/${app_file_name}${app_file_ext}"
dl_url="${app_release}/${app_file_name}${app_file_ext}"
# app_release
echo "download from:$dl_url"

if ! ls /usr/local/${app_name} >/dev/null 2>&1; then
    mkdir $app_path
	chmod -x $app_path

	curl -# -sL -O $dl_url   | tar -zxf ${app_file_name}${app_file_ext} -C ${app_path}
fi 
 
curl -# -sL -O $dl_url   | tar -zxf ${app_file_name}${app_file_ext} -C ${app_path}

mv /usr/local/${app_name}/${app_service} /usr/lib/systemd/system
if ! ls /usr/bin/${app_bin} >/dev/null 2>&1; then
  ln -s /usr/local/${app_name}/${app_bin} /usr/bin/${app_bin}
fi

if ! ls /etc/systemd/system/multi-user.target.wants/${app_service} >/dev/null 2>&1; then
  ln -s /usr/lib/systemd/system/${app_service} /etc/systemd/system/multi-user.target.wants/${app_service}
fi
systemctl daemon-reload