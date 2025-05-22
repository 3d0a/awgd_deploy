## Описание Роли deploy_awg_dashboard
Данная роль необходима для того, чтобы склонировать репозиторий с дащбордом AWG и запустить его в виде контейнера на хосте.
Важное замечание.
Контейнер запущенный на хосте, будет иметь один сетевой неймспейс с хостом. Это необходимо, чтобы отрабатывал amnezia kernel model, который позволяет запускать больше 50 одновременных тоннелей на хосте.

### Описание tasks
- clone_repo.yml - клонирует репозиторий с дашбордом и помещает в него шаблоны Dockerfile и docker-compose файлов
- docker.yml     - устанавливает все необходимые пакеты для запуска докер контейнеров
- deploy.yml     - запускает docker-compose и проверяет работу сервиса дашбордов. Сначала делается docker-compose down, потом происходит пересборка образа и перезапуск контейнера чере docker-compose up. 
```
Вообще лучше будет убрать docker.yml и переместить ее в отдельную роль
```

### Переменные
---
#### Repo config
app_repo_url        - ссылка на репозиторий
app_repo_version    - имя ветки
app_install_dir:    - путь на хосте, куда будет сохранены файлы проекта

#### docker-compose build new image
compose_file           - Имя compose-файла
compose_build          - Собирать образы (булева переменная)
compose_pull: false    - Обновлять базовые образы (булева переменная)
compose_force_recreate - Пересоздавать контейнеры (булева переменная)

#### docker-compose configuration
compose_project_name   -  Имя проекта в компоуз файле
compose_restart_policy -  Правила перезапуска контенера
awg_dashboard_port     -  Порт на котором работает web gui дашборда

#### where to get roles
use_repo_dockerfile    - Нужно ли брать темплей Dockerfile (булева переменная)
use_repo_compose       - Нужно ли брать docker-compos из templates (булева переменная)

#### install packages
docker_packages        - Пакеты докера, которые нужно поставить
