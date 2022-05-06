# Instalação do Zabbix no Ubuntu

Automatiza a instalação do Zabbix no sistema Ubuntu.

O script detecta automaticamente qual versão o sistema operacional está rodando e instala o Zabbix correto, atualmente suporta as versões 18.04 e 20.04 do Ubuntu.



## Como Usar?

1. Acesse o usuário root

```bash
sudo su
```



2. Execute o comando abaixo para efetuar a instalação:

```bash
wget https://raw.githubusercontent.com/jordane-lv/zabbix/main/install.sh && chmod u+x install.sh && ./install.sh && rm -rf install.sh
```

> Ao iniciar o script irá solicitar que selecione a versão e a senha para ser configurada no banco de dados do zabbix.



Agora é só aguardar a instalação finalizar e ser feliz 🎉



## Opcional

### SSH

Se quiser acessar a máquina via SSH, execute os comandos abaixo:

> Estes comandos vão habilitar a porta de acesso 2225 e dar permissão de login com o usuário root.

```bash
$ sed -i 's/^#Port\s[0-9]\+$/Port 2225/g' /etc/ssh/sshd_config
$ sed -i 's/^#PermitRootLogin\sprohibit-password$/PermitRootLogin yes/g' /etc/ssh/sshd_config
$ service sshd restart
```



Para reverter essas configurações:

```bash
$ sed -i 's/^Port\s[0-9]\+$/#Port 22/g' /etc/ssh/sshd_config
$ sed -i 's/^PermitRootLogin\syes$/#PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
```



### Logs

Verifique os logs caso ocorra algum erro:

```bash
$ tail -f /var/log/zabbix/zabbix_server.log
```



## Iniciar zabbix

http://IPDOSERVIDOR/zabbix



Login e senha padrão (lembre-se de alterar):

**Usuário:** Admin
**Senha:** zabbix



## Autor

<img style="border-radius: 50%;" src="https://avatars.githubusercontent.com/jordane-chaves" width="100px;" alt=""/>
<br />

Feito com 💜 por Jordane Chaves
