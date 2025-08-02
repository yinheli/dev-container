# dev container

Henry's dev container for his personal vibe coding usage.


## Usage

```bash
alias claudex='docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.claude:/root/.claude \
  -v ~/.claude.json:/root/.claude.json \
  -v ~/.config/gh:/root/.config/gh \
  docker.io/yinheli/dev-container'
```
