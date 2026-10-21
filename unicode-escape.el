;;; unicode-escape.el --- Escape/Unescape unicode notations -*- lexical-binding: t; -*-

;; Copyright (C) 2016 KOBAYASHI Shigeru

;; Author: KOBAYASHI Shigeru (kosh) <shigeru.kb@gmail.com>
;; URL: https://github.com/kosh04/unicode-escape.el
;; Original-URL: https://gist.github.com/kosh04/568800
;; Version: 1.2
;; Package-Requires: ((emacs "28.1"))
;; Keywords: i18n, unicode
;; Created: 2016/06/09
;; License: MIT License

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Escape and unescape unicode notations. "\uNNNN" <-> "\\uNNNN"
;;
;; Non-BMP characters are converted to 16-bit code of pairs
;; called surrogate-pair (optional).

;;; Change Log:

;; 2010-09-08 ver 0.1  prototype
;; 2016-06-09 ver 1.0  initial release
;; 2016-06-10 ver 1.1  surrogate pair conversion enabled by default
;; 2026-10-22 ver 1.2  be free from package names, and dash.el

;;; Code:

(eval-when-compile
  (require 'rx)
  (require 'cl-lib))
(require 'seq)

(defconst unicode-escape--re-unicode
  (rx (1+ (not ascii)))
  "Regex matches non-ascii characters.")

(defconst unicode-escape--re-escaped
  (rx (or (1+ "\\u" (= 4 xdigit))
          (1+ "\\U" (= 8 xdigit))))
  "Regex matches unicode notations (\\uNNNN or \\UNNNNNNNN).")

;; Surrogate-pair

(defsubst unicode-escape--unicode-to-pair (char)
  "Translate code point CHAR to surrogate pair [high low]."
  (cl-check-type char (integer #x10000 #x10FFFF))
  (let ((code (- char #x10000)))
    (vector (logior #xD800 (ash code -10))
            (logior #xDC00 (logand code #x03FF)))))

(defsubst unicode-escape--pair-to-unicode (pair)
  "Translate surrogate pair PAIR to original code point."
  (pcase-let ((`[,hi ,lo] pair))
    (cl-check-type hi (integer #xD800 #xDBFF))
    (cl-check-type lo (integer #xDC00 #xDFFF))
    (+ (ash (logand hi #x03FF) 10)
       (ash (logand lo #x03FF)  0)
       #x10000)))

;; Escape

(defsubst unicode-escape--escape-char (char &optional surrogate)
  (let ((non-BMP (<= #x10000 char #x10FFFF)))
    (cond ((and non-BMP surrogate)
           (pcase-let ((`[,hi ,lo] (unicode-escape--unicode-to-pair char)))
             (format "\\u%04X\\u%04X" hi lo)))
          (non-BMP
           (format "\\U%08X" char))
          (t
           (format "\\u%04X" char)))))

(defsubst unicode-escape--escape (sequence &optional surrogate)
  (mapconcat #'(lambda (c)
		 (unicode-escape--escape-char c surrogate))
	     sequence ""))

(cl-defun unicode-escape--escape-object (obj &optional (surrogate t))
  "Escape unicode characters to \\uNNNN notation in OBJ (character or string).
If SURROGATE is non-nil, non-BMP characters (U+10000..U+10FFFF)
convert to surrogate pairs."
  (cl-check-type obj (satisfies char-or-string-p))
  (if (characterp obj)
      (unicode-escape--escape-char obj surrogate)
    (let ((case-fold-search nil))
      (replace-regexp-in-string unicode-escape--re-unicode
                                #'(lambda (s)
                                    (unicode-escape--escape s surrogate))
                                obj t t))))

(defun unicode-escape--escape-object* (obj)
  "Escape unicode characters disable surrogate pair in OBJ.
non-BMP characters is escaped \\UNNNNNNNN."
  (unicode-escape--escape-object obj nil))

;; Unescape

(defsubst unicode-escape--parse-escaped-string (s)
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

(defsubst unicode-escape--unescape (notations &optional surrogate)
  ;; e.g. "\\u2603\\uD83C\\uDF63" => "\u2603\U0001F363" (surrogate=t)
  (concat (seq-reduce
           #'(lambda (acc char)
               (let ((hi (car (last acc)))
                     (lo char))
                 (cond ((and hi surrogate
                             (<= #xD800 hi #xDBFF)
                             (<= #xDC00 lo #xDFFF))
                        (setf (car (last acc)) (unicode-escape--pair-to-unicode (vector hi lo)))
                        acc)
                       (t `(,@acc ,char)))))
           (unicode-escape--parse-escaped-string notations)
           nil)))

(cl-defun unicode-escape--unescape-string (string &optional (surrogate t))
  "Unescape unicode notations \\uNNNN and \\UNNNNNNNN in STRING.
If SURROGATE is non-nil, surrogate pairs convert to original code point."
  (let ((case-fold-search nil))
    (replace-regexp-in-string unicode-escape--re-escaped
                              #'(lambda (s)
                                  (unicode-escape--unescape s surrogate))
                              string t t)))

(defun unicode-escape--unescape-string* (string)
  "Unescape unicode notations disable surrogate pair."
  (unicode-escape--unescape-string string nil))

;; Command

(defun unicode-escape--escape-region (start end &optional no-surroage)
  "Escape unicode characters from region START to END.
If NO-SURROAGE is non-nil, surrogate pair conversion is disabled.

See also `unicode-escape'."
  (interactive "*r\nP")
  (let ((surrogate (not no-surroage))
        (case-fold-search nil))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward unicode-escape--re-unicode nil t)
          (replace-match (unicode-escape--escape (match-string 0) surrogate) t t))))))

(defun unicode-escape--unescape-region (start end &optional no-surroage)
  "Unescape unicode notations from region START to END.
If NO-SURROAGE is non-nil, surrogate pair conversion is disabled.

See also `unicode-unescape'."
  (interactive "*r\nP")
  (let ((surrogate (not no-surroage))
        (case-fold-search nil))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward unicode-escape--re-escaped nil t)
          (replace-match (unicode-escape--unescape (match-string 0) surrogate) t t))))))

;;;###autoload
(progn
  (defalias 'unicode-escape  #'unicode-escape--escape-object)
  (defalias 'unicode-escape* #'unicode-escape--escape-object*)
  (defalias 'unicode-unescape  #'unicode-escape--unescape-string)
  (defalias 'unicode-unescape* #'unicode-escape--unescape-string*)
  (defalias 'unicode-escape-region   #'unicode-escape--escape-region)
  (defalias 'unicode-unescape-region #'unicode-escape--unescape-region))

(provide 'unicode-escape)

;;; unicode-escape.el ends here
