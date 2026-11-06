# fish, w0x7y special

my [fish](https://fishshell.com) config. [rime](https://github.com/w0x7y/rime) colors and only the aliases i actually use

### install

needs eza for `ls` and `lt`, bat for man pages and ripgrep for `rgrep`. made on fish `4.9`

```sh
git clone https://github.com/w0x7y/w0x7y.dots
cp -r w0x7y.dots/fish ~/.config/
```

this replaces your `config.fish`. the prompt stays fish's default, or whatever is already in your `functions/`

### aliases

| alias           | runs                                              |
| --------------- | ------------------------------------------------- |
| `ls`            | eza with hidden files, folders first, no icons    |
| `lt`            | the same, as a tree                               |
| `gs`            | `git status`                                      |
| `gd`            | `git diff`                                        |
| `ga`            | `git add`                                         |
| `gc`            | `git commit -m`                                   |
| `gb`            | `git branch -a`                                   |
| `grep`, `egrep` | colored matches                                   |
| `rgrep`         | ripgrep with rime colors. plain `rg` is untouched |
| `h`             | `eval "$(horse)"`                                 |

### what's in it

~ rime colors from `themes/rime.theme`, rime's fish port\
~ no welcome message\
~ `EDITOR` is vis and `BROWSER` is librewolf\
~ `~/.local/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.dotnet/tools` and the android sdk go on `PATH`. fish skips the ones that don't exist\
~ man pages in color through bat

### layout

```text
config.fish         settings, then aliases
themes/rime.theme   rime's fish colors
```

_license: [mit](../LICENSE)_
