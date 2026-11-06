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
~ man pages in color through bat\
~ [autopair.fish](https://github.com/jorgebucaran/autopair.fish) 1.0.4, unedited, closes brackets and quotes as you type. typing the closing one steps over it, and backspace in an empty pair deletes both

### layout

```text
config.fish         settings, then aliases
themes/rime.theme   rime's fish colors
conf.d/             autopair's key bindings
functions/          autopair's functions
autopair.LICENSE    autopair's license
```

_license: [mit](../LICENSE), except autopair, which keeps [its own](autopair.LICENSE)_
