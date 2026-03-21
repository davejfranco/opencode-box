# Build stage
FROM agent-base AS builder

# 1. Install global modules
RUN npm install -g opencode-ai && \
  echo "Installed Open Code version: $(opencode --version)"

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
COPY --from=builder --chown=agent:agent /home/agent/.npm-global /home/agent/.npm-global

CMD ["opencode"]
