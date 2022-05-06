#!/bin/bash

so_name="$(lsb_release -i -s  | tr '[:upper:]' '[:lower:]')"
so_version=$(lsb_release -r -s)
IS_WSL=false

if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
  IS_WSL=true
fi

if [ "$so_name" != 'ubuntu' ];
then
  echo 'Pode ser instalado somente no Ubuntu.'
  exit 0
fi

get_zbx_version() {
  zbx_versions=('6.0' '5.4')

  echo "Selecione a versão do Zabbix:"

  select selected in "${zbx_versions[@]}";
  do
    case $selected in
      "${zbx_versions[$REPLY - 1]}")
        zbx_version=$selected
        clear
        break
      ;;
      *)
        echo "Opcao Invalida!"
        exit 1
      ;;
    esac
  done
}

create_password() {
  echo "Crie uma senha para o banco de dados:"
  read -s password;

  echo "Digite a senha novamente:"
  read -s compare_pass;

  if [ -z "$password" ];
    then
      echo "🛑 É necessário informar uma senha."
      exit
  fi

  if [ "$password" = "$compare_pass" ];
    then
      pass=$password
    else
      echo "🛑 As senhas não coincidem."

      read -r -p "Deseja tentar novamente? [Y/n] " input
      case $input in
      [yY][eE][sS]|[yY])
        clear
        create_password
      ;;
      [nN][oO]|[nN])
        exit
      ;;
      *)
        echo "Invalid input..."
        exit 1
      ;;
      esac
  fi
}

system_prepare() {
  echo "🛠 Preparando o sistema..."
  apt update
  apt install ca-certificates -y
}

repo_install() {
  file="zabbix-release_${zbx_version}-1+${so_name}${so_version}_all.deb"
  url="https://repo.zabbix.com/zabbix/${zbx_version}/ubuntu/pool/main/z/zabbix-release/${file}"

  if [ -e "$file" ];
    then
      echo "🛠 Instando o repositório do Zabbix..."
      dpkg -i "$file"
      apt update
      rm -rf "$file"
    else
      echo "📥 Baixando o arquivo de instalação do Zabbix..."
      wget "$url"
      repo_install
  fi
}

packages_install() {
  echo "🛠 Instalando pacotes..."
  apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server -y
}

db_configure() {
  echo "🛠 Configurando o Banco de Dados..."
  if [ "$zbx_version" == '6.0' ];
    then
      char="utf8mb4"
    else
      char="utf8"
  fi

  if [ -z "$char" ];
  then
    echo 'Falha ao configurar o banco de dados'
    exit 1
  fi

  service mysql restart
  sleep 2

  mysql -uroot -e "create database zabbix character set ${char} collate ${char}_bin"
  mysql -uroot -e "create user zabbix@localhost identified by '$pass'"
  mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost"

  sleep 2
  if [ "$zbx_version" == '6.0' ];
    then
      zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p$pass zabbix
    else
      zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -uzabbix -p$pass zabbix
  fi
}

zabbix_server_config() {
  if [ -e "/etc/zabbix/zabbix_server.conf" ];
    then
      echo "🛠 Configurando zabbix server"

      pass_configured=$(grep -e "^DBPassword=.*" /etc/zabbix/zabbix_server.conf)
      cache_configured=$(grep -e "^CacheSize=\d+[GM]" /etc/zabbix/zabbix_server.conf)

      if [ -z "$pass_configured" ];
      then
        sed -i "s/^#\sDBPassword=$/# DBPassword=\n\nDBPassword=${pass}/g" /etc/zabbix/zabbix_server.conf
      fi

      if [ -z "$cache_configured" ];
      then
        if $IS_WSL; then
          sed -i 's/^#\sCacheSize=8M$/# CacheSize=8M\n\nCacheSize=100M/g' /etc/zabbix/zabbix_server.conf
        else
          sed -i 's/^#\sCacheSize=8M$/# CacheSize=8M\n\nCacheSize=5G/g' /etc/zabbix/zabbix_server.conf
        fi
      fi
    else
      echo "🛑 O arquivo /etc/zabbix/zabbix_server.conf não foi encontrado."
  fi
}

configure_language() {
  echo "Configurando a linguaguem"

  locale-gen pt_BR.UTF-8
  update-locale "LANG=pt_BR.UTF-8"
  dpkg-reconfigure --frontend noninteractive locales
  service apache2 restart
}

start_services() {
  echo "Iniciando os serviços"

  if $IS_WSL; then
    service zabbix-server restart
    service zabbix-agent restart
    service apache2 restart
  else
    systemctl restart zabbix-server zabbix-agent apache2
    systemctl enable zabbix-server zabbix-agent apache2 mysql
  fi
}

get_zbx_version

echo "Zabbix: $zbx_version"
echo "Sistema Operacional: $so_name $so_version"
echo

if [ "$zbx_version" == '6.0' ];
then
  if [[ "$so_version" == '18.04' || "$so_version" == '16.04' ]];
  then
    echo 'É possível instalar o Zabbix 6.0 somente na versão 20.04 do Ubuntu ou posterior.'
    exit 1
  fi
fi

create_password

if [[ -z "$so_name" || -z "$zbx_version" ]];
then
  echo 'Falha ao detectar as versões.'
  exit 1
elif [ -z "$pass" ]
then
  echo 'Senha não foi informada.'
  exit 1
else
  clear
fi

system_prepare
repo_install
packages_install
db_configure
zabbix_server_config

if [ -e "/etc/zabbix/zabbix_server.conf" ];
then
  configure_language
  start_services
fi
