;;; ob-rust.el --- org-babel functions for rust evaluation

;; Copyright (C) 2017 Mican Zhang

;; Author: Mican Zhang
;; Maintainer: Mican Zhang
;; Created: 19 June 2017
;; Keywords: rust, languages, org, babel
;; Package-Version: 20170619.224
;; Homepage: http://orgmode.org
;; Version: 0.0.1

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Org-Babel support for evaluating rust code.
;;
;; Much of this is modeled after `ob-C'.  Just like the `ob-C', you can specify
;; :flags headers when compiling with the "rust run" command.  Unlike `ob-C', you
;; can also specify :args which can be a list of arguments to pass to the
;; binary.  If you quote the value passed into the list, it will use `ob-ref'
;; to find the reference data.
;;
;; If you do not include a main function or a package name, `ob-rust' will
;; provide it for you and it's the only way to properly use
;;
;; very limited implementation:
;; - currently only support :results output.

;;; Requirements:

;; - You must have rust and cargo installed and the rust and cargo should be in your `exec-path'
;;   rust command.
;;
;; - `rust-mode' is also recommended for syntax highlighting and
;;   formatting.  Not this particularly needs it, it just assumes you
;;   have it.

;;; TODO:

;;; Code:
(require 'org)
(require 'ob)
(require 'ob-eval)
(require 'ob-ref)


;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("rust" . "rs"))

(defvar org-babel-default-header-args:rust '())

(defun org-babel-execute:rust (body params)
  "Execute a block of Template code with org-babel.
This function is called by `org-babel-execute-src-block'."
  (message "executing Rust source code block")
  (let* ((tmp-src-file (org-babel-temp-file "rust-src-" ".rs"))
         (processed-params (org-babel-process-params params))
         (flags (cdr (assoc :flags processed-params)))
         (args (cdr (assoc :args processed-params)))
         (coding-system-for-read 'utf-8) ;; use utf-8 with subprocesses
         (coding-system-for-write 'utf-8))
    (with-temp-file tmp-src-file (insert body))
    (if-let ((results
	      (org-babel-eval
	       (format "cargo script %s" tmp-src-file)
               "")))
	(org-babel-reassemble-table
	 (if (or (member "table" (cdr (assoc :result-params processed-params)))
		 (member "vector" (cdr (assoc :result-params processed-params))))
	     (let ((tmp-file (org-babel-temp-file "rust-")))
	       (with-temp-file tmp-file (insert (org-babel-trim results)))
	       (org-babel-import-elisp-from-file tmp-file))
	   (org-babel-read (org-babel-trim results) t))
	 (org-babel-pick-name
	  (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
	 (org-babel-pick-name
	  (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params)))))))

;; This function should be used to assign any variables in params in
;; the context of the session environment.
(defun org-babel-prep-session:rust (session params)
  "This function does nothing as Rust is a compiled language with no
support for sessions."
  (error "Rust is a compiled languages -- no support for sessions"))

(defun org-babel-rust-rustfmt (body)
  "Run rustfmt over the body. Why not?"
  (with-temp-buffer
    (let ((outbuf (current-buffer))
          (coding-system-for-read 'utf-8) ;; use utf-8 with subprocesses
          (coding-system-for-write 'utf-8))
      (with-temp-buffer
        (insert body)
        (shell-command-on-region (point-min) (point-max) "rustfmt"
                                 outbuf nil nil)))
    (buffer-string)))

(provide 'ob-rust)
;;; ob-rust.el ends here
