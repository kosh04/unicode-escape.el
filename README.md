unicode-escape.el
-----------------

[![Build Status](https://travis-ci.org/kosh04/unicode-escape.el.svg?branch=master)](https://travis-ci.org/kosh04/unicode-escape.el)

Escape/Unescape a unicode notations (`\uNNNN`) for Emacs.


## Installation

    (require 'unicode-escape)


## Function

### unicode-escape `(string &option surrogate)`

Escape `string` to unicode notation.

If `surrogate` is non-nil, non-BMP characters (U+0000..U+10FFFF)
convert a 2-byte sequence such as [surrogate pair][surrogate_pair].

    (unicode-escape "Hello") ;;=> "Hello"
    (unicode-escape "こんにちは") ;;=> "\\u3053\\u3093\\u306B\\u3061\\u306F"
    (unicode-escape "U+1F363 is 🍣")     ;;=> "U+1F363 is \\uD83C\\uDF63" (unicode-escape-enable-surrogate-pair=t)
    (unicode-escape "U+1F363 is 🍣" nil) ;;=> "U+1F363 is \\U0001F363" 

### unicode-unescape `(string &option surrogate)`

Unescape unicode `string`.

If `surrogate` is non-nil, [surrogate pair][surrogate_pair] will be converted to
original code point.

    (unicode-unescape "\\u3053\\u3093\\u306B\\u3061\\u306F") ;;=> "こんにちは"
    (unicode-unescape "\\uD83C\\uDF63")     ;;=> "🍣"
    (unicode-unescape "\\uD83C\\uDF63" nil) ;;=> "\uD83C\uDF63"


## Command

### unicode-escape-region `(start end)`

Escape unicode characters from region `start` to `end`.

### unicode-unescape-region `(start end)`

Unescape unicode notations from region `start` to `end`.


## Variable

### unicode-escape-enable-surrogate-pair

Escape/unescape non-BMP characters as [surrogate pair][surrogate_pair]. (defaut `t`)

This variable affect the unicode-escape functions/commands.

    ELISP> (setq unicode-escape-enable-surrogate-pair t)
    ELISP> (unicode-escape "🙈🙉🙊")
    "\\uD83D\\uDE48\\uD83D\\uDE49\\uD83D\\uDE4A"

    ELISP> (setq unicode-escape-enable-surrogate-pair nil)
    ELISP> (unicode-escape "🙈🙉🙊")
    "\\U0001F648\\U0001F649\\U0001F64A"


## License

MIT License

[surrogate_pair]:https://en.wikipedia.org/wiki/Surrogate_pair
