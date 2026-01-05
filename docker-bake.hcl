variable "REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE_OWNER" {
  default = "glimmer-labs"
}

variable "IMAGE_NAME" {
  default = "wolfi-php"
}

variable "WOLFI_DIGEST" {
  default = "latest"
}

variable "PHP_VERSION" {
  default = "none"
}

target default {
  context = "."
  dockerfile = "Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = ["${REGISTRY}/${IMAGE_OWNER}/${IMAGE_NAME}:latest"]
  labels = {
      "dev.chainguard.wolfi.digest" = "${WOLFI_DIGEST}",
      "org.opencontainers.image.authors" = "Haruki1707 https://github.com/Haruki1707",
      "org.opencontainers.image.source" = "https://github.com/${IMAGE_OWNER}/${IMAGE_NAME}",
      "org.opencontainers.image.url" = "https://github.com/${IMAGE_OWNER}/${IMAGE_NAME}/pkgs/container/${IMAGE_NAME}",
      "org.opencontainers.image.vendor" = "Glimmer Labs",
      "org.opencontainers.image.description" = "A Docker image based on Wolfi Linux 'optimized' for Laravel applications. Includes scripts to easily install PHP, Composer, and required PHP extensions.",
  }
}

target versioned {
  inherits = ["default"]
  dockerfile = "Dockerfile.versioned"
  tags = ["${REGISTRY}/${IMAGE_OWNER}/${IMAGE_NAME}:${PHP_VERSION}"]
  args = {
    PHP_VERSION = "${PHP_VERSION}"
  }
}

target versioned-zts {
  inherits = ["default"]
  dockerfile = "Dockerfile.versioned"
  tags = ["${REGISTRY}/${IMAGE_OWNER}/${IMAGE_NAME}:${PHP_VERSION}-zts"]
  args = {
    PHP_VERSION = "${PHP_VERSION} --zts"
  }
}