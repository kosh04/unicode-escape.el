;;; unicode-escape-test.el

(require 'ert)
(require 'f)
(require 'cl-lib)
(require 'unicode-escape)

(defvar unicode-escape-test-strings
  '(("" . "")
    ("\uFEFF" . "\\uFEFF")
    ("\u3053\u3093\u306B\u3061\u306F" . "\\u3053\\u3093\\u306B\\u3061\\u306F")
    ("Hello, World!" . "Hello, World!")
    ("SUSHI,\u5BFF\u53F8,\U0001F363" . "SUSHI,\\u5BFF\\u53F8,\\uD83C\\uDF63") ; surrogate=t
    )
  "List of string pairs (raw . escaped).
Type is (String . String).")

(defvar unicode-escape-test-surrogate-pairs
  '((?\U00010000 . [?\uD800 ?\uDC00])
    (?\U00010001 . [?\uD800 ?\uDC01])
    (?\U00010401 . [?\uD801 ?\uDC01])
    (?\U00010E6D . [?\uD803 ?\uDE6D])
    (?\U0001D11E . [?\uD834 ?\uDD1E])   ; "MUSICAL SYMBOL G CLEF"
    (?\U0001f363 . [?\uD83C ?\uDF63])   ; "SUSHI"
    (?\U0010FFFF . [?\uDBFF ?\uDFFF]))
  "List of set (code-point . surrogate-pair).
Type is (Char . Vector[Char Char]).")

(ert-deftest surrogate-pair ()
  "Test unicode surrogate pair."
  (cl-loop for (char . pair) in unicode-escape-test-surrogate-pairs
           do
           (should (equal      (unicode-escape--unicode-to-pair char) pair))
           (should (char-equal (unicode-escape--pair-to-unicode pair) char))))

(ert-deftest unicode-escape ()
  "Test `unicode-escape' and `unicode-unescape'."
  (cl-loop for (raw . escaped) in unicode-escape-test-strings
           do
           (should (string= (unicode-escape raw) escaped))
           (should (string= (unicode-unescape escaped) raw))))

(ert-deftest unicode-escape* ()
  "Test `unicode-escape*' and `unicode-unescape*'."
  (should (string= (unicode-escape* "\U0001F363") "\\U0001F363"))
  (should (string= (unicode-unescape* "\\uD83C\\uDF63") "\uD83C\uDF63")))

(ert-deftest unicode-escape-hello ()
  "Test escape/unescape using built-in HELLO file."
  (let* ((hello-file (expand-file-name "HELLO" data-directory))
         (hello (f-read hello-file 'iso-2022-7bit)))
    (should (string= (unicode-unescape (unicode-escape hello)) hello))
    (should (string= (unicode-unescape* (unicode-escape* hello)) hello)) ; surrogate=t
    ))

(ert-deftest unicode-escape-region ()
  "Test `unicode-escape-region' command."
  (cl-loop for (raw . escaped) in unicode-escape-test-strings
           do
           (should (string= (with-temp-buffer
                              (insert raw)
                              (unicode-escape-region (point-min) (point-max))
                              (buffer-string))
                            escaped))
           (should (string= (with-temp-buffer
                              (insert escaped)
                              (unicode-unescape-region (point-min) (point-max))
                              (buffer-string))
                            raw))))

;; load and run test
(unless noninteractive
  (ert t))

;;; unicode-escape-test.el ends here.
