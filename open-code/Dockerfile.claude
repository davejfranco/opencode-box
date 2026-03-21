# Build stage
FROM agent-base AS builder

# 1. Install global modules
RUN npm install -g opencode-ai && \
  npm install -g @anthropic-ai/claude-code && \
  echo "Installed Open Code version: $(opencode --version)"

# 2. Clone and install the Claude Max Proxy
WORKDIR /home/agent
RUN git clone https://github.com/rynfar/opencode-claude-max-proxy.git && \
  cd opencode-claude-max-proxy && \
  bun install

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
COPY --from=builder --chown=agent:agent /home/agent/.npm-global /home/agent/.npm-global

# Copy the proxy app from builder
COPY --from=builder --chown=agent:agent /home/agent/opencode-claude-max-proxy /home/agent/opencode-claude-max-proxy

# Copy and configure the entrypoint script
COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   OPEN CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && opencode --version && \
  echo "\e[0m" && \
  echo ""

# Route container startup through our script
ENTRYPOINT ["/home/agent/entrypoint.sh"]
CMD ["opencode"]
