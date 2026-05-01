CALVER=$(date -d "@$(($(date +%s) + 8 * 3600))" "+%Y.%-m.%-d")

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --progress plain \
  --push \
  -t "chiskat/docker-logrotate:$CALVER" \
  .

docker run --rm \
  -e PUSHRM_TARGET="docker.io/chiskat/docker-logrotate" \
  -e PUSHRM_SHORT="Sidecar logrotate with Docker CLI." \
  -e DOCKER_USER="chiskat" \
  -e DOCKER_PASS="$DOCKER_PASS" \
  -e PUSHRM_FILE="/repo/README.md" \
  -v "./README.md:/repo/README.md" \
  chko/docker-pushrm:1
