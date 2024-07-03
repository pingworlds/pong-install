#!/bin/bash
echo 'install pong'
sys_os="unsupported"
sys_arch="unknown"
sys_arm=""

app_name="pong"
# app_ver="0.9.1"
app_service="pong.service"
app_file_ext=".tar.gz"
app_site="https://github.com/pingworlds"

app_bin="$app_name"
# app_path="/usr/local/${app_name}"
app_path="/etc/${app_name}"
app_source="${app_site}/${app_name}"

app_source="${app_site}/pong"
app_release="${app_site}/${app_name}/releases/latest/download"
registered=0
echo "os type:$OSTYPE"
check_sys() {
	unamem="$(uname -m)"
	echo "usname:$unamem"
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

download_file() {
	sudo systemctl stop pong
	app_file_name="${app_name}_${sys_os}_${sys_arch}${sys_arm}"
	dl_url="${app_release}/${app_file_name}${app_file_ext}"

	echo "--------------current os:$sys_os  arch:$sys_arch"
	echo "--------------${app_name} install path:$app_path"

	# echo "--------------pong.service :$app_service"
	echo "--------------pong :$dl_url"

	if ! ls $app_path >/dev/null 2>&1; then
		echo "--------------mk dir :$app_path"
		mkdir $app_path
	fi

	curl -# -sL -O $dl_url
	tar -zxf ${app_file_name}${app_file_ext} -C ${app_path}

        mv  ${app_path}/${app_name}  /usr/bin
	chmod 700  /usr/bin/${app_name} 
	rm -rf ${app_file_name}${app_file_ext}

	 
        if ! ls /etc/${app_name} >/dev/null 2>&1; then
	  mkdir  /etc/${app_name}	 
        fi
	 
}

reg_service() {
	if ! ls /usr/lib/systemd/system/pong.service >/dev/null 2>&1; then
		echo "registering pong service"
		cat <<EOT >>/usr/lib/systemd/system/pong.service
[Unit]
Description=pong service
Documentation=https://github.com/pingworlds/pong
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
StandardError=journal
ExecStart=/usr/bin/pong -d /etc/pong
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOT
	fi

	if ! ls /etc/pong/remote.json >/dev/null 2>&1; then
		cat <<EOT >>/etc/pong/remote.json
{ 
    "listens": [           
        {
            "transport": "h2c",
            "host": ":21984",
            "protocol": "pong",          
            "clients": [
                "d931e571-c9d2-4527-9223-9ef1cdeaf4b2"
            ],            
            "disabled": false
        },
        {
            "transport": "http",
            "host": ":21985",
            "protocol": "pong",          
            "clients": [
                "d931e571-c9d2-4527-9223-9ef1cdeaf4b2"
            ],            
            "disabled": false
        },
        {
            "transport": "ws",
            "host": ":21986",           
            "protocol": "pong",
            "clients": [
                "d931e571-c9d2-4527-9223-9ef1cdeaf4b2"
            ],
            "disabled": false
        },
		{
            "transport": "h2c",
            "host": ":21987",           
            "protocol": "vless",
            "clients": [
                "d931e571-c9d2-4527-9223-9ef1cdeaf4b2"
            ],
            "disabled": false
        },
		{
            "transport": "h2c",
            "host": ":21988",           
            "protocol": "qsocks",          
            "disabled": false
        },
		{
            "transport": "h2c",
            "host": ":21989",           
            "protocol": "ss",          
            "disabled": false
        }
    ]
}
EOT
	fi

	sudo systemctl enable pong
	systemctl daemon-reload

	if ! ls /etc/systemd/system/multi-user.target.wants/${app_service} >/dev/null 2>&1; then
		ln -s /usr/lib/systemd/system/${app_service} /etc/systemd/system/multi-user.target.wants/${app_service}
	fi
	echo "successfully registered pong service."
}

check_sys
download_file
reg_service

echo "done"
