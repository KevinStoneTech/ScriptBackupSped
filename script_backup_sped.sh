#!/bin/bash
# Por Kevin Stone
# Em Dez/2019

#cria o diretório onde vai ficar armazenado o backup atual
cd /var/bkp_sped
mkdir -p sped_$(date +%Y%m%d)
echo "Operações de backup iniciado em" `date +%d/%m/%Y`" às" `date +%H:%M:%S` >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
echo "---------------------------------------------------------------------------------------------------" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log

##### Inicio Processo 1 ###########
######## Fazendo backup do banco de dados do SPED 64 bits###################
echo "Aguardando 10 segundos antes de inicar o processo de backup, para cancelar precione CTRL + C"
sleep 10
echo "Iniciando backup do banco de dados do SPED-2.9.00-08 64 bits"
sleep 2
service tomcat7 stop
sleep 2

cd /tmp

#su postgres -c "pg_dump -E UTF8 spedDB > backup_SPED_$(date +%Y%m%d).sql"
su postgres -c "pg_dump -E UTF8 -v spedDB > backup_SPED_$(date +%Y%m%d).sql"

mv backup_SPED_$(date +%Y%m%d).sql /var/bkp_sped

echo "Sucesso!!! - backup banco de dados sped-2.9.00-08 64 bits"
sleep 2
service tomcat7 start
###### Fim Processo 1 ###


##### Inicio Processo 2 ###
########## Fazendo backup da base LDAP do SPED-2.9.00-08 64 bits #################
echo "Iniciando backup da base LDAP do SPED-2.9.00-08 64 bits"
sleep 3
service slapd stop
cd /var/bkp_sped/
slapcat -l backup_ldap_$(date +%Y%m%d).ldif
service slapd start
sleep 3
cd /
echo "Sucesso! - backup banco do LDAP"
sleep 2
#### Fim processo 2 ###########


####Inicio Processo 3 ####
############ Fazendo backup da aplicação SPED 64 bits ##############
echo "Iniciando backup da aplicação WEB SPED-2.9.00-08 64 bits"
sleep 2
sudo cp /var/lib/tomcat7/webapps/sped.war /var/bkp_sped/backup-sped-2.9.00-08_$(date +%Y%m%d).war
sleep 2

#essa parte junta todos os arquivos que foram realizados o backup e coloca na pasta criada com a data do dia que foi realizado o backup
cd /var/bkp_sped
mv backup_SPED_$(date +%Y%m%d).sql backup_ldap_$(date +%Y%m%d).ldif backup-sped-2.9.00-08_$(date +%Y%m%d).war sped_$(date +%Y%m%d)/
echo "backup conluído com sucesso"
### Fim processo 3 ###########

####Inicio Processo 4 ####
echo "Verificando a integridade do backup da aplicação com hash md5"
sleep 5
echo "Aplicacao Web sped_$(date +%Y%m%d)" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
sudo md5sum /var/bkp_sped/sped_$(date +%Y%m%d)/backup-sped-2.9.00-08_$(date +%Y%m%d).war >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
sleep 3
echo "---------------------------------------------------------------------------------------------------" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
echo "Aplicacao Web SPED.war" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
sudo md5sum /var/lib/tomcat7/webapps/sped.war >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
sleep 5
echo "Se os valores hash md5 apresentados forem iguais, o backup está ok, caso contrário, faça o backup novamente"
sleep 3
echo "---------------------------------------------------------------------------------------------------" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
echo "Seu backup encontra-se no diretorio /var/bkp_sped/sped_$(date +%Y%m%d)"
echo "Operacoes de backup terminadas em" `date +%d/%m/%Y`" às" `date +%H:%M:%S` >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log

echo "---------------------------------------------------------------------------------------------------" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
echo "Transferindo o backup do SPED para o servidor `date +%d/%m/%Y`" às" `date +%H:%M:%S`" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
scp -r /var/bkp_sped/sped_$(date +%Y%m%d) root@10.78.32.25:/home/samba/backup_geral/SPED/

# Faz a exclusão de arquivos com mais de 5 dias.
# Para não super lotar o armazenamento do disco.

echo "---------------------------------------------------------------------------------------------------" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log
sleep 1h
echo "Deletando os arquivos de backup anteriores a dois dias" >> /var/bkp_sped/sped_$(date +%Y%m%d)/log_backup.log

find /var/bkp_sped/sped* -mtime +5 -exec rm -r {} \;

