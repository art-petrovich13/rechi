#!/usr/bin/env python3
"""Локальная заглушка SpeechSuper для ручной проверки Mini App.

Не заменяет реальный сервис: возвращает правдоподобные баллы по буквам слова,
чтобы можно было прогнать весь флоу без ключей SpeechSuper.

Запуск (из mini_app):
    python3 tool/fake_speechsuper.py

В backend .env:
    SPEECH_SUPER_KEY=local
    SPEECH_SUPER_SECRET=local
    SPEECH_SUPER_URL=http://host.docker.internal:9000

`host.docker.internal` — для backend в Docker Desktop на macOS.
Для Linux используйте адрес хоста в Docker-сети или запустите заглушку
в той же Docker-сети.
"""

import json
from http.server import BaseHTTPRequestHandler, HTTPServer


def extract_ref_text(body: bytes) -> str:
    """Достаёт refText из multipart-поля text, которое шлёт backend."""

    marker = b'name="text"'
    start = body.find(marker)
    if start == -1:
        return "рыба"

    start = body.find(b"\r\n\r\n", start)
    if start == -1:
        return "рыба"
    start += 4

    end = body.find(b"\r\n--", start)
    raw = body[start : end if end != -1 else None]
    try:
        payload = json.loads(raw.decode("utf-8"))
        return str(payload["start"]["param"]["request"]["refText"]).strip()
    except (KeyError, TypeError, ValueError, UnicodeDecodeError):
        return "рыба"


def build_scores(word: str) -> dict[str, int]:
    """Строит баллы: первый звук проблемный, остальные — хорошие."""

    letters = [char.upper() for char in word if char.isalpha()]
    unique = list(dict.fromkeys(letters))
    if not unique:
        unique = ["Р", "Ы", "Б", "А"]

    return {
        phoneme: 45 if index == 0 else min(98, 82 + (index * 7) % 15)
        for index, phoneme in enumerate(unique)
    }


class Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        word = extract_ref_text(body)
        scores = build_scores(word)
        overall = round(sum(scores.values()) / len(scores))

        payload = {
            "result": {
                "overall": overall,
                "words": [
                    {
                        "phonemes": [
                            {"phoneme": phoneme, "pronunciation": score}
                            for phoneme, score in scores.items()
                        ]
                    }
                ],
            }
        }
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")

        print(f"fake SpeechSuper: word={word!r} scores={scores}", flush=True)
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt: str, *args: object) -> None:
        print("fake SpeechSuper:", fmt % args, flush=True)


if __name__ == "__main__":
    print("fake SpeechSuper listening on http://0.0.0.0:9000", flush=True)
    HTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
