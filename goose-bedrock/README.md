# Goose + Amazon Bedrock via LiteLLM

Run [Goose](https://github.com/block/goose) AI agent with Claude models on Amazon Bedrock using LiteLLM as a proxy.

## Why Goose?

Goose is an open source AI agent framework created by Block, and is now part of the [Agentic AI Foundation (AAIF)](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) under the Linux Foundation. The AAIF was founded by Anthropic, Block, and OpenAI to ensure agentic AI evolves transparently and collaboratively through open source governance.

Key projects in the AAIF:
- **[Model Context Protocol (MCP)](https://github.com/modelcontextprotocol)** - Universal standard for connecting AI models to tools and data (Anthropic)
- **[Goose](https://block.github.io/goose)** - Local-first AI agent framework with MCP integration (Block)
- **[AGENTS.md](http://agents.md/)** - Standard for project-specific AI agent guidance (OpenAI)

Using Goose means building on open, vendor-neutral infrastructure backed by the same foundation that stewards Linux, Kubernetes, and other critical open source projects.

## Why This Setup?

- **Amazon Bedrock** - Enterprise-grade Claude access with AWS IAM auth, no API keys to manage
- **LiteLLM** - Lightweight proxy that translates OpenAI-compatible requests to Bedrock
- **Goose** - AI agent with tools for development and computer control

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [mise](https://mise.jdx.dev/) | Tool version manager | `curl https://mise.run \| sh` |
| [uv](https://docs.astral.sh/uv/) | Python package runner | `mise use -g uv` |
| AWS CLI | AWS authentication | `mise use -g awscli` |
| Goose | AI agent | `mise use -g goose` |

## AWS Setup

### 1. Enable Bedrock Model Access

In AWS Console:
1. Go to **Amazon Bedrock** → **Model access**
2. Request access to **Anthropic Claude** models
3. Wait for approval (usually instant for Claude)

### 2. Configure AWS Credentials

```bash
# Option A: SSO (recommended for organizations)
aws configure sso
aws sso login

# Option B: IAM credentials
aws configure
```

## Quick Start

### 1. Start LiteLLM Proxy

```bash
# Claude Sonnet 4.5 (recommended - fast and capable)
uvx --with boto3 litellm[proxy] --model bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0 --alias bedrock

# Or Claude Opus 4.5 (most capable, slower)
uvx --with boto3 litellm[proxy] --model bedrock/global.anthropic.claude-opus-4-5-20251101-v1:0 --alias bedrock

# Or Claude Haiku 4.5 (fastest, cheapest)
uvx --with boto3 litellm[proxy] --model bedrock/global.anthropic.claude-haiku-4-5-20251001-v1:0 --alias bedrock
```

This starts a proxy on `http://localhost:4000` that accepts OpenAI-compatible requests.

### 2. Configure Goose (one-time)

```bash
goose configure provider --provider openai --model bedrock --api-key fake --host http://localhost:4000
```

### 3. Run Goose

```bash
goose session
```

## Available Models (Global Inference Profiles)

These use cross-region inference for better availability:

| Model | Bedrock ID | Best For |
|-------|------------|----------|
| Claude Opus 4.5 | `global.anthropic.claude-opus-4-5-20251101-v1:0` | Complex reasoning, difficult coding |
| Claude Sonnet 4.5 | `global.anthropic.claude-sonnet-4-5-20250929-v1:0` | General use, good balance |
| Claude Haiku 4.5 | `global.anthropic.claude-haiku-4-5-20251001-v1:0` | Quick tasks, cheapest |

Check available models in your account:
```bash
aws bedrock list-inference-profiles --query 'inferenceProfileSummaries[?contains(inferenceProfileId, `claude`)].inferenceProfileId' --output table
```

## Goose Extensions

### Core Extensions (Recommended)

```yaml
extensions:
  - developer           # Shell, file editing, code analysis
  - computercontroller  # Screenshots, automation, web scraping
```

### Developer Extension
- Run shell commands
- Edit files with smart diff/replace
- Analyze code structure
- Screenshot for visual debugging

### Computer Controller Extension
- Take screenshots
- Web scraping (fetch pages, APIs)
- Desktop automation (click, type)
- Process PDFs, Excel, Word docs

## One-Liner Setup

```bash
# Terminal 1: Start proxy (keep running)
uvx --with boto3 litellm[proxy] --model bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0 --alias bedrock

# Terminal 2: Configure goose (first time only)
goose configure provider --provider openai --model bedrock --api-key fake --host http://localhost:4000

# Terminal 2: Run goose
goose session
```

## Justfile Recipes

This repo includes recipes:

```bash
just litellm          # Start LiteLLM proxy (default: Sonnet 4.5)
just litellm MODEL="global.anthropic.claude-opus-4-5-20251101-v1:0"  # Use Opus
just goose-configure  # Configure Goose to use LiteLLM (one-time)
just goose            # Start Goose session
```

## Troubleshooting

### "Could not connect to Bedrock"

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Bedrock access
aws bedrock list-inference-profiles --query 'inferenceProfileSummaries[?contains(inferenceProfileId, `claude`)].inferenceProfileId'
```

### "Model not found"

Ensure you've enabled the model in Bedrock Console → Model access.

### LiteLLM won't start

```bash
# Check if port 4000 is in use
lsof -i :4000

# Try a different port
uvx --with boto3 litellm[proxy] --model bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0 --port 8000
```

### Goose can't connect

```bash
# Test the proxy directly
curl http://localhost:4000/v1/models

# Should return something like:
# {"data":[{"id":"claude","object":"model",...}]}
```

## Cost Estimates

Bedrock pricing (as of 2025):

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Claude Opus 4.5 | $15.00 | $75.00 |
| Claude Sonnet 4.5 | $3.00 | $15.00 |
| Claude Haiku 4.5 | $0.80 | $4.00 |

Typical goose session: ~10-50K tokens = $0.03-0.75 with Sonnet.

## See Also

- [Goose Documentation](https://block.github.io/goose/)
- [LiteLLM Bedrock Docs](https://docs.litellm.ai/docs/providers/bedrock)
- [Amazon Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)
