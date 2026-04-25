import os
from dataclasses import dataclass, field


@dataclass
class Settings:
    ollama_url: str = field(
        default_factory=lambda: os.getenv("KIBRIA_OLLAMA_URL", "http://localhost:11434")
    )
    # 3-tier model ladder
    model_primary: str = field(
        default_factory=lambda: os.getenv("KIBRIA_MODEL_PRIMARY", "qwen3.5:9b-q4_K_M")
    )
    model_middle: str = field(
        default_factory=lambda: os.getenv("KIBRIA_MODEL_MIDDLE", "qwen2.5:14b-instruct-q4_K_M")
    )
    model_heavy: str = field(
        default_factory=lambda: os.getenv("KIBRIA_MODEL_HEAVY", "qwen3.5:27b-q4_K_M")
    )
    port: int = field(
        default_factory=lambda: int(os.getenv("KIBRIA_AGENT_PORT", "8765"))
    )
    system_prompt: str = (
        "You are Ask-Kibria, the built-in AI assistant for KibriaOS — "
        "an AI-powered Ubuntu 24.04-based Linux distribution created by "
        "Dr. ABM Asif Kibria. Help users with Linux administration, "
        "software development, and AI tasks. Be concise and accurate. "
        "Use code blocks for shell commands and code snippets."
    )

    @property
    def default_model(self) -> str:
        return self.model_primary


settings = Settings()
