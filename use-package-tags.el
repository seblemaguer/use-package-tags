;;; use-package-tags.el ---   -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C)  2019 Sébastien Le Maguer
;;

;; Author: Sébastien Le Maguer <lemagues@tcd.ie>
;; Maintainer: Sébastien Le Maguer <lemagues@tcd.ie>
;; Created: 03 Mar 2019
;; Modified: 03 Mar 2019
;; Version: 1.0
;; Package-Requires: ((use-package "2.4") (dash "2.15.0") (seq "2.2"))
;; Keywords: dotemacs startup package tags
;; URL: https://github.com/jwiegley/use-package

;; use-package-tags is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; use-package-tags is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with use-package-tags.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;;

;;; Code:

(require 'use-package-core)
(require 'dash)
(require 'seq)

(defconst use-package-tags-all-tag "ALL"
  "Joker tag to indicate that the host is going to install everything!")

(defconst use-package-tags-not-symbol "!"
  "Symbol to indicate that the host have to not install the dedicate tag")

(defconst use-package-tags-default-host "DEFAULT"
  "Default hostname to define baseline tags")

(defvar use-package-tags-default-tag-list '()
  "Default list of tags to apply")

;; Define some machine name identifiers
(defvar use-package-tags-enabled '()
  "Association list to associate a list of tags (strings) to a
  hostname (string). If the hostname of the current machine is
  not in the association list, any tags is considered valid; this
  is also the case if the list of tags associated to the hostname
  of the current machine is nil. Else the package will be
  installed if the intersection between the list of tags of the
  package and the list of tags associated the hostname of the
  current machine is not empty.")

;; 0. Define some helper
(defun use-package-tags-validate-tags (tags)
  "Helper to see if the given TAGS may lead to an
 installation. Returns t if TAGS is nil or the list of tags
 associated to the current machine hostname is nil. Else, it
 returns the intersection between the two lists of tags."
  (let* ((list-tags-cur-host (alist-get (system-name) use-package-tags-enabled
                                        (alist-get use-package-tags-default-host
                                                   use-package-tags-enabled
                                                   nil nil 'string=)
                                        nil 'string=))
	     (rejected-tags (seq-map (lambda (elt)
                                   (substring elt 1))
				                 (seq-filter (lambda (elt)
                                               (string-prefix-p use-package-tags-not-symbol elt))
					                         list-tags-cur-host)))
	     (accepted-tags (seq-filter (lambda (elt)
                                      (not (string-prefix-p use-package-tags-not-symbol elt)))
				                    list-tags-cur-host)))

    ;; Add the default tag list
    (when use-package-tags-default-tag-list
      (setq rejected-tags (append rejected-tags
                                  (seq-map (lambda (elt)
                                             (substring elt 1))
				                           (seq-filter (lambda (elt)
                                                         (string-prefix-p use-package-tags-not-symbol elt))
					                                   use-package-tags-default-tag-list))))

      (setq accepted-tags (append accepted-tags
                                  (seq-filter (lambda (elt)
                                                (not (string-prefix-p use-package-tags-not-symbol elt)))
				                              use-package-tags-default-tag-list))))

    (if (null list-tags-cur-host)
	    t
      (if (-intersection rejected-tags tags)
          nil
        (cond
         ((member use-package-tags-all-tag accepted-tags) t)
         ((null accepted-tags) t)
         (t (-intersection accepted-tags tags)))))))

;; 1. add keyword (first position as it needs to be before ensuring of the package)
(push :tags use-package-keywords)

;; 2. Define normalizer
;;;###autoload
(defalias 'use-package-normalize/:tags 'use-package-normalize-test)

;; 3. define hangler
;;;###autoload
(defun use-package-handler/:tags (name _keyword arg rest state)
  "Execute the handler for `:tags' keyword in `use-package'."
  (let ((body (use-package-process-keywords name rest state)))
    `((when (use-package-tags-validate-tags ,arg) ,@body))))

(provide 'use-package-tags)

;;; use-package-tags.el ends here
