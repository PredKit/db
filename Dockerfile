# Build stage - contains all build tools and dependencies
FROM postgres:17-bookworm AS builder

# Install build dependencies and tools
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    postgresql-server-dev-17 \
    postgresql-plpython3-17 \
    python3-dev \
    python3-pip \
    curl \
    ca-certificates \
    wget \
    pkg-config \
    rustc \
    cargo \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (required for pgrx-based extensions)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install pgrx
RUN cargo install --locked cargo-pgrx --version 0.15.0
RUN cargo pgrx init --pg17=/usr/lib/postgresql/17/bin/pg_config

# Install pg_search extension from ParadeDB
RUN git clone https://github.com/paradedb/paradedb.git /tmp/paradedb \
    && cd /tmp/paradedb \
    && git submodule update --init --recursive \
    && cd pg_search \
    && cargo pgrx install --release \
    && cd / \
    && rm -rf /tmp/paradedb

# Install pgvector (required dependency for pgai)
RUN set -e \
    && echo "Installing pgvector..." \
    && git clone --depth 1 --branch v0.8.1 https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && cd /tmp/pgvector \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgvector \
    && echo "pgvector installation completed"

# Install pgai extension (latest version v0.12.0)
RUN set -e \
    && echo "Cloning pgai repository..." \
    && git clone --depth 1 --branch pgai-v0.12.0 https://github.com/timescale/pgai.git /tmp/pgai \
    && cd /tmp/pgai/projects/extension \
    && echo "Building and installing pgai extension..." \
    && python3 build.py build-install \
    && echo "Cleaning up..." \
    && cd / \
    && rm -rf /tmp/pgai \
    && echo "pgai installation completed"

# Runtime stage - clean PostgreSQL with only the extensions
FROM postgres:17-bookworm AS runtime

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y \
    postgresql-plpython3-17 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled extensions from builder stage
COPY --from=builder /usr/lib/postgresql/17/lib/ /usr/lib/postgresql/17/lib/
COPY --from=builder /usr/share/postgresql/17/extension/ /usr/share/postgresql/17/extension/
COPY --from=builder /usr/local/lib/pgai/ /usr/local/lib/pgai/

# Copy initialization scripts
COPY ./init-scripts/ /docker-entrypoint-initdb.d/

# Environment variables will be set by docker-compose or at runtime

# Expose PostgreSQL port
EXPOSE 5432

# Use the default postgres entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
