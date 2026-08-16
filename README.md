# Claude Code ガードレール研修

Skills / Subagent / Hooks がガードレールとしてどう効くのかを、
**ある状態と無い状態を並べて**体感する。その上で自分で作れるようになるのがゴール。

Claude Code を日常的に使っている前提で進める。基本操作の説明はしない。

---

## ディレクトリ

| | |
| --------------- | ---------------------------------------------------------------------------- |
| `demo/`         | 実演用のリポジトリ。 |
| `guardrails/`   | ガードレールの実体。`demo/` の外に置いてある |
| `guardrails.sh` | ガードレールを1枚ずつ着脱する |
| `templates/`    | 持ち帰り用のひな形（Skill / Subagent / Hook / settings） |
| `tdd-demo/`     | 締めのデモ。全部揃った状態でTDDを1周する → [tdd-demo/README.md](tdd-demo/README.md) |

`guardrails/` が `demo/` の外にあるのは意図的。
中に置くと、ガードレールOFFのときでも Claude がソースを読んで自主的に従ってしまい、
**「無い状態」が再現できなくなる**。

## 自分で動かす

準備:

```bash
./setup.sh
```

いま何が有効かを見る。着脱できるレイヤーの一覧もここに出る:

```bash
./guardrails.sh status
```

全部外す（＝素の Claude Code）:

```bash
./guardrails.sh off
```

指定したものだけ有効にする:

```bash
./guardrails.sh only skill
```

切り替えたら Claude Code を起動し直す。設定はセッション開始時に読まれるので、
起動中に切り替えても反映されない。

起動は必ず `demo/` をカレントにする:

```bash
cd demo && claude
```
