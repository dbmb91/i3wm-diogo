#!/bin/bash
# 
# swatquest

declare -rx NOMESCRIPT=${0##*/} # NOMESCRIPT é o nome deste script
declare -rx curl="/usr/bin/curl" # comando curl
declare -rx pv="/usr/bin/pv" # comando pv
declare -rx rankmirrors="/usr/bin/rankmirrors"  # comando rankmirrors

if [ ! -x "$curl" ]; then
 printf "$NOMESCRIPT: O pacote curl não está instalado.\n" >&2
 exit 192
fi

if [ ! -x "$pv" ]; then
 printf "$NOMESCRIPT: O pacote pv não está instalado.\n" >&2
 exit 192
fi

if [ ! -x "$rankmirrors" ]; then
 printf "$NOMESCRIPT: O pacote pacman-contrib não está instalado.\n" >&2
 exit 192
fi

[ "$UID" != 0 ] && SU=sudo

# Pega mirrorlist all do site
curl -s  https://www.archlinux.org/mirrorlist/all/ -o /tmp/all

# Verifica se está conectado
if [[  $? != 0 ]]; then
echo "Não conectado";
exit 0
fi

paises() {
   cat /tmp/all | grep "^##" | sed -r -n '5,$ s/([^*]+).*/\0/p' | sed 's/^## //g'
}

# Monta lista de países
paises | nl -s" "|column 

QTD=`paises | wc -l`;
let "QTD2=$QTD +1"

while read -p "Escolha os países [ padrão=todos ]:" -a PAISES ; do
  for a in ${PAISES[@]}; do
   [[ $a -ge $QTD ]] && break
  done
   [[ $PAISES = [a-z]* ]] && continue
   [[ $a -lt $QTD2 ]] && break
done

# Salvar e alterar IFS 
ANTIGOIFS=$IFS
IFS=$'\n'

CAPTURA=($(for i in "${PAISES[@]}"; do paises | awk "NR == $i {print; exit}";done))

# Restaurar IFS e LANG
IFS=$ANTIGOIFS 

contador=${#CAPTURA[@]}

if [[ ${contador} -eq 0 ]]; then
  cat /tmp/all  > /tmp/all2 
else
  for (( i=0; i<${contador}; i++ )); do  cat /tmp/all  | sed -r -n "/${CAPTURA[$i]}/,/^$/p";done > /tmp/all2 
fi

# Remover arquivo all
rm /tmp/all

# Descomentar mirrors
   echo "Descomentando as mirrors."
   sed '/^#S/ s|#||' -i "/tmp/all2"

# Aplicar rankmirrors
   echo -e "Atenção:\n É recomendável utilizar o rankmirrors, pois ele determina a melhor conexão."
   while read -p "Você quer utilizar o script rankmirrors? [S/n]" RESPRANK ; do
     if [[ $RESPRANK = "" ]]; then
       RESPRANK="S"; break
     elif [[ $RESPRANK = [SsNn] ]]; then
       break
     fi
    done
     if [[ $RESPRANK = [Ss] ]]; then
       while read -p "Qual a quantidade de servidores? [padrão 6, 0 para todos, máximo 999]" RESPQUANT ; do
          if [[ $RESPQUANT = "" ]]; then
              RESPQUANT="6"; break
          elif  [[ $RESPQUANT = [0-9] ]]; then
            break
          elif  [[ $RESPQUANT = [0-9][0-9] ]]; then
            break          
          elif  [[ $RESPQUANT = [0-9][0-9][0-9] ]]; then
            break
           fi
       done
       echo "Executando rankmirrors."
       echo "O processo pode demorar um pouco."
   	 rankmirrors -r community  -n $RESPQUANT "/tmp/all2" | pv -t > /tmp/mirrorlist
         rm /tmp/all2
   	 echo "Rankmirrors finalizado."
     elif [[ $RESPRANK = [Nn] ]]; then
   	 echo "Rankmirrors não executado."
     fi

# Backup e copia do arquivo
   echo "Se for necessário, o comando sudo será utilizado."
   echo "Será feito um backup da mirrorlist em /etc/pacman.d/ com o nome \"mirrolist.bkp\"."
   while read -p "Você quer mover o arquivo para a pasta \"/etc/pacman.d/\"? [S/n]" RESPCOPIAR ; do
     if [[ $RESPCOPIAR = "" ]]; then
       RESPCOPIAR="S"; break
     else  	   
       [[ $RESPCOPIAR = [SsNn] ]] && break
     fi
    done
     if [[ $RESPCOPIAR = [Ss] ]]; then
       echo "Criando backup."
       $SU cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp
        if [[ -f /tmp/all2 ]]; then
	  echo "Definindo permisão para 744."
          chmod 744 /tmp/all2
 		  chmod -x /tmp/all2
	  echo "Modificando nome do dono e do grupo para root." 
          $SU chown root:root /tmp/all2
   	  echo "Movendo arquivo."
   	  $SU mv /tmp/all2 /etc/pacman.d/mirrorlist
	elif [[ -f /tmp/mirrorlist ]]; then
	  echo "Definindo permisão para 744."
          chmod 744 /tmp/mirrorlist
          chmod -x /tmp/mirrorlist
	  echo "Modificando nome do dono e do grupo para root." 
          $SU chown root:root /tmp/mirrorlist 
   	  echo "Movendo arquivo."
   	  $SU mv /tmp/mirrorlist /etc/pacman.d/mirrorlist
	fi
     elif [[ $RESPCOPIAR = [Nn] ]]; then
       echo "Arquivo não copiado."
       echo "Um dos arquivos temporários estão na pasta \""/tmp/"\""
       echo -e "Com rankmirrors: mirrorlist\nSem rankmirrors: all2" 
       exit 0
      fi


# Apagar arquivo
   while read -p "Você quer apagar o arquivo de backup ou restaurar a mirrolist? [A/r]" RESPDELBACKUP ;
   do
     if [[ $RESPDELBACKUP = "" ]]; then
       RESPDELBACKUP="A"; break
     else  	   
       [[ $RESPDELBACKUP = [AaRr] ]] && break
     fi
   done
     if [[ $RESPDELBACKUP = [Aa] ]]; then
       echo "Apagando o arquivo de backup em \"/etc/pacman.d/\"."
       $SU rm /etc/pacman.d/mirrorlist.bkp
     elif [[ $RESPDELBACKUP = [Rr] ]]; then
       echo "Restaurando o arquivo de backup em \"/etc/pacman.d/\"."
       $SU mv /etc/pacman.d/mirrorlist.bkp /etc/pacman.d/mirrorlist
     fi

exit 0