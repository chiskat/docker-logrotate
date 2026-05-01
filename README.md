# `Chiskat/Docker-Logrotate`

[![](https://img.shields.io/docker/v/chiskat/docker-logrotate?sort=semver)](https://hub.docker.com/r/chiskat/docker-logrotate) ![](https://img.shields.io/docker/image-size/chiskat/docker-logrotate)

[`Chiskat/Docker-Logrotate`](https://hub.docker.com/r/chiskat/docker-logrotate) 是内置了 Linux 工具 [`logrotate`](https://github.com/logrotate/logrotate) 的 Docker 镜像，且额外集成了 Docker CLI；它可作为非 k8s 环境的 “Sidecar” 镜像，对其它服务日志文件进行定时处理；每次处理日志后，还可以通过 Docker CLI 让其它容器重新加载新的日志文件。

## 使用说明

- 镜像启动后，默认使用 Alpine 安装 `logrotate` 后自带的周期任务 `/etc/periodic/daily/logrotate` 进行每日触发，触发时间为每日 `2:00 am`；触发时间可通过环境变量 `LOGROTATE_CRON` 来覆写；
- 镜像启动后，会加载 `/etc/logrotate.d/*` 中的所有文件作为 logrotate 的配置；这个目录初始是空的，开发者需自行挂载配置文件到此；
- 镜像中的 logrotate 使用 alpine 默认的 `/etc/logrotate.conf` 入口配置，开发者如有需求，可以通过挂载替换为自定义的配置文件；
- 将日志文件挂载到 `/logs/` 目录以供容器中的 logrotate 访问，这是推荐的目录；
- 请挂载 `/var/lib/logrotate/` 目录并保证持久化，logrotate 会在此目录下创建文件用来记录执行状态等数据；
- 如果需要使用 Docker 相关命令，则挂载 `/var/run/docker.sock` 到容器内相同路径，这样便可以在容器中通过 `docker` 命令控制宿主机的 Docker；
- 有关 logrotate 的使用配置方法，请查阅 [Linux Logrotate 官方手册](https://linux.die.net/man/8/logrotate)，本文不作介绍。

以上所述的触发时间以及各个目录，几乎都可以通过环境变量来修改定制，可参考下文 “环境变量” 章节。

## docker compose 配置示例

以 “sidecar” 模式运行，处理 Nginx 的日志：

```yml
volumes:
  logrotate-state:

services:
  nginx:
    image: nginx
    volumes:
      - ./logs:/var/log/nginx
    # ...
    # 其它 Nginx 配置此处省略

  logrotate:
    image: chiskat/docker-logrotate:latest
    restart: unless-stopped
    volumes:
      - ./logs/:/logs/
      - ./logrotate.d/:/etc/logrotate.d/
      # ↓ 可选，挂载自定义主配置文件（不挂载时使用默认值）
      # - ./logrotate.conf:/etc/logrotate.conf:ro
      # ↓ 请确保容器内的 /var/lib/logrotate 被持久化
      - logrotate-state:/var/lib/logrotate/
      # ↓ 如果需要用到 docker cli 操作宿主机的其它容器，则添加下方这一行
      - /var/run/docker.sock:/var/run/docker.sock
```

开发者提供的文件 `./logrotate.d/nginx` 内容示例：

```
/logs/access.log
/logs/error.log
{
  daily
  rotate 30
  dateext
  dateformat .%Y-%m-%d.log
  missingok
  create 644 root root
  postrotate
    docker exec nginx nginx -s reopen
  endscript
}
```

注意开头的两行，目录为镜像中的日志存放目录 `/logs/`。

## 环境变量

容器中，配置文件的目录、logrotate 的启动参数等均可通过环境变量进行定制，可参考下表：

| 变量名                  | 说明                                                         | 默认值                                |
| ----------------------- | ------------------------------------------------------------ | ------------------------------------- |
| `LOGROTATE_STATE_FILE`  | `logrotate` 状态文件路径，建议将此文件持久化                 | `/var/lib/logrotate/logrotate.status` |
| `LOGROTATE_INCLUDE_DIR` | `logrotate` 的 `include` 目录路径                            | `/etc/logrotate.d`                    |
| `LOGROTATE_MAIN_CONFIG` | 主配置文件路径；若该路径文件不存在，则回退到镜像内置默认配置 | `/etc/logrotate.conf`                 |
| `LOGROTATE_OPTIONS`     | 传递给 `logrotate` 的统一附加参数，例如可设置为 `"-v -f"`    | `-v`                                  |
| `LOGROTATE_CRON`        | 定时触发 `logrotate` 的 crontab 表达式                       | -                                     |

## 自行构建

如果你对第三方的镜像不放心，也可以自己构建，以下是方法：

1. 打开 [GitHub 仓库](https://github.com/chiskat/docker-logrotate) 克隆此项目
2. 运行 `docker build -t 镜像名 .`，这里的镜像名你可以自己随便取
