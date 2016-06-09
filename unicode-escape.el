;;; unicode-escape.el --- escape/unescape unicode notations -*- lexical-binding: t; -*-

;; Copyright (C) 2016 KOBAYASHI Shigeru

;; Author: KOBAYASHI Shigeru (kosh) <shigeru.kb@gmail.com>
;; URL: https://github.com/kosh04/unicode-escape.el
;; Original-URL: https://gist.github.com/kosh04/568800
;; Version: 1.0
;; Package-Requires: ((emacs "24") (names "0.5"))
;; Keywords: i18n
;; Created: 2016/06/09
;; License: MIT License

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Escape and unescape unicode notations.  "\uNNNN" <-> "\\uNNNN"

;;; Code:

(eval-when-compile
  (require 'names)
  (require 'rx)
  (require 'cl))
(require 'cl-lib)

;;;###autoload
(define-namespace unicode-escape-

(defvar enable-surrogate-pair t
  "Escape non-BMP characters as surrogate pair.")

(defvar -re-unicode
  (rx (not ascii))
  "Regex matches a non-ascii character.")

(defconst -re-escaped
  (rx (or (1+ "\\u" (= 4 xdigit))
          (1+ "\\U" (= 8 xdigit))))
  "Regex matches 1 (or more) unicode \\uNNNN or \\UNNNNNNNN notation.")

(defsubst -unicode-to-pair (char)
  "Translate code point CHAR to surrogate pair [high low]."
  (cl-check-type char (integer #x10000 #x10FFFF))
  (let ((code (- char #x10000)))
    (vector (logior #xD800 (ash code -10))
            (logior #xDC00 (logand code #x03FF)))))

(defsubst -pair-to-unicode (pair)
  "Translate surrogate pair PAIR to original code point."
  (let ((hi (aref pair 0))
        (lo (aref pair 1)))
    (cl-check-type hi (integer #xD800 #xDBFF))
    (cl-check-type lo (integer #xDC00 #xDFFF))
    (+ (ash (logand hi #x03FF) 10)
       (ash (logand lo #x03FF)  0)
       #x10000)))

(defsubst -escape-char (char &optional surrogate)
  (let ((non-BMP (and (<= #x10000 char) (<= char #x10FFFF))))
    (cond ((and non-BMP surrogate)
           (let ((pair (-unicode-to-pair char)))
             (format "\\u%04X\\u%04X" (aref pair 0) (aref pair 1))))
          (non-BMP
           (format "\\U%08X" char))
          (t
           (format "\\u%04X" char)))))

(defsubst -escape (sequence &optional surrogate)
  (cl-labels ((escape (c) (-escape-char c surrogate)))
    (apply #'concat (mapcar #'escape (vconcat sequence)))))

(defsubst -parse-escaped-string (s)
  "Separate unicode notation string S to character set."
  ;; e.g. "\\uXXXX\\uYYYY\\uZZZZ" => (?\uXXXX ?\uYYYY ?\uZZZZ)
  (let ((slen (length s))
        (step (if (eql (aref s 1) ?U)
                  (length "\\UNNNNNNNN")
                  (length "\\uNNNN"))))
    (cl-loop for i from 0 by step
             while (< i slen)
             collect (let ((hex (substring s (+ i 2) (+ i step))))
                       (string-to-number hex 16)))))

(defsubst -unescape (notations &optional surrogate)
  ;; e.g. "\\u2603\\uD83C\\uDF63" => "\u2603\U0001F363" (surrogate=t)
  (concat (cl-reduce
           #'(lambda (acc char)
               (let ((hi (car (last acc)))
                     (lo char))
                 (cond ((and hi surrogate
                             (<= #xD800 hi) (<= hi #xDBFF)
                             (<= #xDC00 lo) (<= lo #xDFFF))
                        (setf (car (last acc)) (-pair-to-unicode (vector hi lo)))
                        acc)
                       (t `(,@acc ,char)))))
           (-parse-escaped-string notations)
           :initial-value nil)))

(defun* -escape-string (string &optional (surrogate unicode-escape-enable-surrogate-pair))
  "Escape unicode characters to \\uNNNN notation in STRING.
non-BMP characters (U+10000..U+10FFFF) is escaped \\UNNNNNNNN.
If SURROGATE is non-nil, non-BMP characters convert to surrogate pairs."
  (let ((case-fold-search nil))
    (replace-regexp-in-string -re-unicode
                              #'(lambda (s)
                                  (-escape s surrogate))
                              string t t)))

(defun* -unescape-string (string &optional (surrogate unicode-escape-enable-surrogate-pair))
  "Unescape unicode notations \\uNNNN and \\UNNNNNNNN in STRING.
If SURROGATE is non-nil, surrogate pairs convert to original code point."
  (let ((case-fold-search nil))
    (replace-regexp-in-string -re-escaped
                              #'(lambda (s)
                                  (-unescape s surrogate))
                              string t t)))

(defun -escape-region (start end)
  "Escape unicode characters from region START to END.

See also `unicode-escape'."
  (interactive "*r\P")
  (let ((surrogate enable-surrogate-pair)
        (case-fold-search nil))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward -re-unicode nil t)
          (replace-match (-escape (match-string 0) surrogate) t t))))))

(defun -unescape-region (start end)
  "Unescape unicode notations from region START to END.

See also `unicode-unescape'."
  (interactive "*r\P")
  (let ((surrogate enable-surrogate-pair)
        (case-fold-search nil))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward -re-escaped nil t)
          (replace-match (-unescape (match-string 0) surrogate) t t))))))

:autoload (defalias 'unicode-escape        #'-escape-string)
:autoload (defalias 'unicode-escape-region #'-escape-region)
:autoload (defalias 'unicode-unescape        #'-unescape-string)
:autoload (defalias 'unicode-unescape-region #'-unescape-region)

) ;; end namespace

(provide 'unicode-escape)

;;; unicode-escape.el ends here
