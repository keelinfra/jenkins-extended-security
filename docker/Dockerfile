# Unofficial. The official Jenkins 2.541.3 image (JDK 17) with the patched WAR from
# a GitHub Release of this repository. Nothing else in the image changes.
# The base is pinned by digest; .github/workflows/image.yml passes the WAR in.
FROM jenkins/jenkins:2.541.3-jdk17@sha256:cce1eeb79902722f3cf7a8831c41e95c39f4a42b9a2981959630cc66539b3c2d

ARG VERSION
ARG WAR_SHA256
ARG REVISION

# Same path the official image uses. The update center serves 2.541.3-kN the same
# plugin versions as 2.541.3, so jenkins-plugin-cli and the plugin manager pick
# plugins that work on 2.541.3.
COPY jenkins.war /usr/share/jenkins/jenkins.war
ENV JENKINS_SHA=${WAR_SHA256}

LABEL org.opencontainers.image.title="Extended Security for Jenkins 2.541.x" \
      org.opencontainers.image.description="Unofficial. Jenkins 2.541.3 with backported core security fixes. Not affiliated with or supported by the Jenkins project." \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/keelinfra/jenkins-extended-security" \
      org.opencontainers.image.licenses="MIT AND BSD-2-Clause" \
      org.opencontainers.image.base.name="docker.io/jenkins/jenkins:2.541.3-jdk17"
