---
title: fail2ban timezone
date: 2019-08-02 14:05:31
tags: 
    - system
    - fail2ban
    - timezone
    - ssh
---
## Contexte
J'ai récemment réinitialisé mon Raspberry pour changer la vieille carte SD de 16Go qu'il y avait dessus et la remplacer par une de 128Go.

Pourquoi ? Plus de place, possibilité d'utiliser docker tranquilement (les images bouffent rapidement les 16Go) et surtout isntaller un dualboot pour avoir une [recalbox](https://www.recalbox.com/fr/)

Pour info mon Raspberry me servait essentiellement de serveur Upnp pour regarder mes films et séries sur la Freebox.

Aprés avoir mis en place le dual boot (merci à ce [tuto](https://github.com/recalbox/recalbox-os/wiki/Cr%C3%A9er-un-dualboot-raspbian-recalbox)), un des premiers step à faire est de sécuriser un minimum l'accès (notamment en ssh) au Raspberry. Bon si vous ne l'exposez pas à l'extérieur c'est moins critique mais j'ai personnellement choisi de forward le port ssh de ma box sur le raspberry pour pouvoir bidouiller dessus à distance.

Dès le boot on remarque rapidement des bots qui scannent un peu toutes les ip et tentent d'accéder en SSH au serveur (notamment en root) : 
```
Jul 17 21:38:47 [server] sshd[4456]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=106.13.83.150  user=root
Jul 17 21:39:37 [server] sshd[4527]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=179.189.84.195  user=root
Jul 17 21:39:52 [server] sshd[4533]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=205.178.24.203  user=root
Jul 17 21:40:20 [server] sshd[4602]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=125.212.207.205  user=root

```
Un des premier truc à faire donc : installer fail2ban
Je vous passe l'étape de configuration de fail2ban, il y a de nombreux tuto là-dessus

## Problème
Donc on active la jail ssh, on démarre le service :
```
sudo service fail2ban start
```
On regarde les logs et là il ne se passe rien : 
```
2019-07-18 13:27:08,015 fail2ban.database       [30438]: INFO    Connected to fail2ban persistent database '/var/lib/fail2ban/fail2ban.sqlite3'
2019-07-18 13:27:08,033 fail2ban.jail           [30438]: INFO    Creating new jail 'sshd'
2019-07-18 13:27:08,096 fail2ban.jail           [30438]: INFO    Jail 'sshd' uses poller {}
2019-07-18 13:27:08,256 fail2ban.jail           [30438]: INFO    Initiated 'polling' backend
2019-07-18 13:27:08,267 fail2ban.filter         [30438]: INFO    Set maxRetry = 3
2019-07-18 13:27:08,279 fail2ban.filter         [30438]: INFO    Added logfile = /var/log/auth.log
2019-07-18 13:27:08,289 fail2ban.filter         [30438]: INFO    Set findtime = 600
2019-07-18 13:27:08,291 fail2ban.filter         [30438]: INFO    Set jail log file encoding to UTF-8
2019-07-18 13:27:08,303 fail2ban.actions        [30438]: INFO    Set banTime = 600
2019-07-18 13:27:08,309 fail2ban.filter         [30438]: INFO    Set maxlines = 10
2019-07-18 13:27:09,143 fail2ban.server         [30438]: INFO    Jail sshd is not a JournalFilter instance
2019-07-18 13:27:09,281 fail2ban.jail           [30438]: INFO    Jail 'sshd' started
...
```

La config est bien là : 
```
[sshd]

enabled = true
port    = ssh,sftp
filter  = sshd
logpath  = /var/log/auth.log
maxretry = 3
```

## Solution
Après plusieurs heures de recherche sur Google (#noob) la solution vient d'[ici](https://bobcares.com/blog/fail2ban-not-banning/) section 4
En effet si on regarde les logs au même moment du fichier `/var/log/auh.log` : 
```
Jul 18 11:27:27 ns359884 sshd[30458]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=206.189.222.181
Jul 18 11:27:31 ns359884 sshd[30465]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=189.3.152.194
Jul 18 11:27:36 ns359884 sshd[30467]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=188.226.182.209
Jul 18 11:27:37 ns359884 sshd[30470]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=211.75.194.80
```

On remarque que l'heure utilisée dans le fichier auth.log (UTC) n'est pas la même que l'heure utilisée par fail2ban (UTC+2)
Le problème c'est que fail2ban considère que les tentatives de login qui arrive sont trop anciennes et ne doivent dont pas être traitées.

Un petit coup de 
```
sudo service rsyslog restart
```

Le service ssh log à la bonne heure et tout rentre en place: 
```
2019-07-18 19:17:38,514 fail2ban.server         [27077]: INFO    Jail sshd is not a JournalFilter instance
2019-07-18 19:17:38,570 fail2ban.jail           [27077]: INFO    Jail 'sshd' started
2019-07-18 19:17:58,622 fail2ban.filter         [27077]: INFO    [sshd] Found 129.213.153.229
2019-07-18 19:17:58,632 fail2ban.filter         [27077]: INFO    [sshd] Found 129.213.153.229
2019-07-18 19:18:00,638 fail2ban.filter         [27077]: INFO    [sshd] Found 129.213.153.229
2019-07-18 19:18:01,025 fail2ban.actions        [27077]: NOTICE  [sshd] Ban 129.213.153.229
```

