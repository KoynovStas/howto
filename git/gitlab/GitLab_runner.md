
# Установка

1. Добавление репозитория:

```bash
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
```


2. Установка нужной версии:

```bash
# install git
sudo apt install git git-lfs tig

# check time zone
timedatectl
sudo timedatectl set-timezone Europe/Samara

# install gitlab-runner
apt-cache madison gitlab-runner
sudo apt install gitlab-runner=17.2.0-1
```


3. Обновление

```bash
sudo apt update
sudo apt install gitlab-runner

# Можно указать нужную версию
sudo apt install gitlab-runner=18.2.0
```



# Регистрация

1. Добавление раннера через [GitLab UI](https://docs.gitlab.com/ee/ci/runners/runners_scope.html#project-runners)

2. Регистрация на стороне [GitLab Runner](https://docs.gitlab.com/runner/register/):

```bash
# console variant of reg
# it will create config.toml file
# for sudo see: /etc/gitlab-runner/config.toml
# for user see: /home/xxx/.gitlab-runner/config.toml

sudo gitlab-runner register \
  --non-interactive \
  --url "http://10.0.0.6/" \
  --token "$RUNNER_TOKEN" \
  --executor "shell" \
  --description "Linux_ARM_gcc_runner"

  #--tag-list "docker,aws" \
```

Где:
 - `url` - адрес GitLab.
 - `token` - токен, полученный через [GitLab UI](https://docs.gitlab.com/ee/ci/runners/runners_scope.html#project-runners) в разделе Settings->CI/CD: Runners
 - `description` - описание Runner-а, которое будет показываться в интерфейсе Gitlab-а
 - `tags` - через запятую введите тэги для Runner-а. Их можно изменить позднее, через интерфейс самого GitLab-а. 
 Тэги можно использовать для того, чтобы определённые задачи выполнялись на определённых Runner-ах.

[Список параметров](https://docs.gitlab.com/runner/commands/#configuration-file)

По сути, можно сразу самим создать конфиг файл напрямую.


# Конфигурация

Добавление пользователя `gitlab-runner` в группу `xxx`
```bash
sudo usermod -a -G xxx gitlab-runner
```

Далее я устанавливаю тулчейн для ARM:

```bash
sudo apt install cmake ninja xz-utils

scp arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz xxx@10.0.2.255:/tmp/

tar -xpJf arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz -C /home/xxx/bin/

# Python (use for calc CRC of bin)
sudo apt install python-is-python3 python3-pip
sudo pip3 install --prefix /usr crc==6.0.0
```

Чтобы Runner, мог находить тулчейн, редактируем `.profile` файл пользователя `gitlab-runner`. 

```bash
# Нужно править от самого пользователя:
sudo su - gitlab-runner

nano .profile
```


```bash
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "${BASH-}" ]; then
    [ -f $HOME/.bashrc ] && . $HOME/.bashrc
fi


# set my PATH
PATH="$PATH:/home/xxx/bin"
PATH="$PATH:/home/xxx/bin/arm-gnu-toolchain-14.2.rel1/bin"
```

> Особенность: `.bashrc` и другие не должны содержать log_out -иначе `gitlab-runner` будет выходить из консоли и терять связь с системой!


Вариант конфиг файла:

```toml
concurrent = 2
check_interval = 10
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "Linux_ARM_gcc_runner"
  url = "http://10.0.0.6"
  id = 33
  token = "Some_Token"
  token_obtained_at = 2025-01-28T15:56:08Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  builds_dir = "/tmp/runner"
  [runners.custom_build_dir]
    enabled = true
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
```

 - `builds_dir` - директория сборки, (требует `runners.custom_build_dir`)


Полное описание [config файла](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)



Установка и запуск службы:

```bash
# install service
sudo gitlab-runner install --user gitlab-runner

# del service
sudo gitlab-runner uninstall

# status
sudo gitlab-runner list
sudo gitlab-runner status
sudo gitlab-runner start
sudo gitlab-runner stop
```

Если не использовать `sudo`, то можно запускать ранеры от своего пользователя, тогда конфиг будет у вас: `/home/xxx/.gitlab-runner/config.toml`
