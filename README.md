unicode-escape.el
-----------------

[![MELPA](http://melpa.org/packages/unicode-escape-badge.svg)](http://melpa.org/#/unicode-escape)
[![MELPA Stable](http://stable.melpa.org/packages/unicode-escape-badge.svg)](http://stable.melpa.org/#/unicode-escape)
[![Build Status](https://travis-ci.org/kosh04/unicode-escape.el.svg?branch=master)](https://travis-ci.org/kosh04/unicode-escape.el)

Escape/Unescape a unicode notations (`\uNNNN`) for Emacs.


## Installation

You can install this package from [MELPA](http://melpa.org/#/getting-started).

`M-x package-install` <kbd>RET</kbd> `unicode-escape` <kbd>RET</kbd>

Then put the following into your setting file (optional):

    (require 'unicode-escape)


## Function

### unicode-escape `(obj &optional (surrogate t))`

Escape `obj` to unicode notation. (character or string)
[surrogate pair](#surrogate-pair) conversion is enabled.

    (unicode-escape "Hello") ;;=> "Hello"
    (unicode-escape ?\u2603) ;;=> "\\u2603"
    (unicode-escape "こんにちは") ;;=> "\\u3053\\u3093\\u306B\\u3061\\u306F"
    (unicode-escape "U+1F363 is 🍣") ;;=> "U+1F363 is \\uD83C\\uDF63"

### unicode-escape* `(obj)`

Similar to `unicode-escape`.
[surrogate pair](#surrogate-pair) conversion is disabled. 
non-BMP characters convert to `\UNNNNNNNN`.

    (unicode-escape* "U+1F363 is 🍣") ;;=> "U+1F363 is \\U0001F363" 

### unicode-unescape `(string &optional (surrogate t))`

Unescape unicode `string`.
[surrogate pair](#surrogate-pair) convert to original code point.

    (unicode-unescape "\\u3053\\u3093\\u306B\\u3061\\u306F") ;;=> "こんにちは"
    (unicode-unescape "\\uD83C\\uDF63") ;;=> "🍣"

### unicode-unescape* `(string)`

Similar to `unicode-unescape`.
[surrogate pair](#surrogate-pair) conversion is disabled.

    (unicode-unescape* "\\uD83C\\uDF63" nil) ;;=> "\uD83C\uDF63"


## Command

Note: Prefix argument (C-u) is given, surrogate pair conversion is disabled.

### unicode-escape-region `(start end &optional no-surrogate)`

Escape unicode characters from region `start` to `end`.

### unicode-unescape-region `(start end &optional no-surrogate)`

Unescape unicode notations from region `start` to `end`.


## Surrogate pair

https://en.wikipedia.org/wiki/Surrogate_pair

By default, non-BMP characters (U+10000..U+10FFFF) are converted to
16-bit code of pairs.

    (unicode-escape "🙈🙉🙊")
    ;;=> "\\uD83D\\uDE48\\uD83D\\uDE49\\uD83D\\uDE4A"

    (unicode-escape "🙈🙉🙊" nil) ; or `unicode-escape*'
    ;;=> "\\U0001F648\\U0001F649\\U0001F64A"


## License

MIT License
