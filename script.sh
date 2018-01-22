#!/bin/bash

#Primera parte
#Variable para indicar número minimo MB libres
MAX=450
bucle='start'

echo Cuando quieras puedes estresar la maquina contenedor1
#Recogemos la memoria RAM con el comando free
while [ $bucle != 'stop' ]; do
	FREE=`lxc-info -n contenedor1 | grep 'Memory use' | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1`
	if [ $FREE -gt $MAX ];
	then
#Sentencia para desmontar volumen
		echo Desmontando volumen de contenedor1...
		lxc-attach -n contenedor1 -- umount /dev/mapper/vgsistema-discolxc1
		echo Volumen desmontado.
#Sentencia para quitar el disco adicional de mv1
		echo Quitando volumen de contenedor1...
		lxc-device -n contenedor1 del /dev/mapper/vgsistema-discolxc1
		echo Volumen quitado.
#Sentencia para añadir a contenedor2 el disco adicional
		echo Añadiendo volumen a contenedor2...
		lxc-device -n contenedor2 add /dev/mapper/vgsistema-discolxc1
		echo Volumen añadido.
#Sentencia para montar el volumen a contenedor2
		echo Montando el volumen a contenedor2...
		lxc-attach -n contenedor2 -- mount /dev/mapper/vgsistema-discolxc1 /var/www/html
		lxc-attach -n contenedor2 -- systemctl restart apache2
		echo Volumen montado.
#Quitar regla de iptable para redireccionar el purto 80 a contenedor1
		echo Quitando regla de iptable...
		iptables -t nat -D PREROUTING 1
		echo Regla de iptable quitada.
#Añadir regla de iptable para redireccionar el puerto 80 a contenedor22
		echo Añadiendo regla iptble...
		iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.3.107:80
		echo Regla de iptable añadida
		bucle='stop'
	fi
done
#Segunda parte
echo Cuando quieras puedes estresar la maquina contenedor2
#Variable para indicar número minimo MB libres
MAX2=900
bucle2='start'
#Recogemos la memoria RAM con el comando free
while [ $bucle2 != 'stop' ]; do
        FREE2=`lxc-info -n contenedor2 | grep 'Memory use' | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1`
        if [ $FREE2 -gt $MAX2 ];
        then
#Redimensionando memoria RAM
                echo Ampliando memoria RAM...
		lxc-cgroup -n contenedor2 memory.limit_in_bytes 2G
                bucle2='stop'
        fi
done
echo Memoria RAM ampliada.
