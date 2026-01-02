# Multi-stage build for radsecproxy
# Stage 1: Build stage
FROM alpine:3.23.2 AS builder

# Define radsecproxy version as a build argument
ARG RADSECPROXY_VERSION=1.11.2

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    nettle-dev \
    autoconf \
    automake \
    libtool

# Clone and build radsecproxy
WORKDIR /build
RUN git clone https://github.com/radsecproxy/radsecproxy.git . && \
    git checkout ${RADSECPROXY_VERSION} && \
    autoreconf -fi && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var && \
    make && \
    make DESTDIR=/install install

# Stage 2: Runtime stage
FROM alpine:3.23.2

# Install only runtime dependencies
RUN apk add --no-cache \
    openssl \
    nettle \
    libgcc \
    libstdc++

# Copy the compiled binary and necessary files from builder
COPY --from=builder /install/usr/sbin/radsecproxy /usr/sbin/radsecproxy
COPY --from=builder /install/usr/bin/radsecproxy-* /usr/bin/
COPY --from=builder /install/usr/share/man/man5/radsecproxy.conf.5 /usr/share/man/man5/
COPY --from=builder /install/usr/share/man/man8/radsecproxy* /usr/share/man/man8/

# Create necessary directories
RUN mkdir -p /var/log/radsecproxy

# Create a non-root user for running radsecproxy
RUN addgroup -S radsecproxy && \
    adduser -S -G radsecproxy radsecproxy && \
    chown -R radsecproxy:radsecproxy /var/log/radsecproxy

# Expose RADIUS ports
# 1812/udp - RADIUS authentication
# 1813/udp - RADIUS accounting
# 2083/tcp - RadSec (RADIUS over TLS)
EXPOSE 1812/udp 1813/udp 2083/tcp

# Switch to non-root user
USER radsecproxy

# Default command
CMD ["/usr/sbin/radsecproxy", "-f", "-d", "5"]
