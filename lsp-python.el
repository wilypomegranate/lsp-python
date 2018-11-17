;;; lsp-python.el --- Python support for lsp-mode -*- lexical-binding: t -*-

;; Copyright (C) 2017 Vibhav Pant <vibhavp@gmail.com>

;; Author: Vibhav Pant <vibhavp@gmail.com>
;; Version: 1.0
;; Package-Requires: ((lsp-mode "3.0"))
;; Keywords: python
;; URL: https://github.com/emacs-lsp/lsp-python

;;; Code:
(require 'lsp-mode)
(require 'lsp-common)

(defcustom lsp-python-server-args
  '()
  "Extra arguments for the python-stdio language server"
  :group 'lsp-python
  :risky t
  :type '(repeat string))

(defcustom lsp-python-use-init-for-project-root
  nil
  "Set to t to look for __init__.py files to determine a project's root.

The first directory not containing an __init__.py file (looking
upwards from the directory the open python file is in) is set as
the project root for the lsp server.
"
  :group 'lsp-python
  :type 'boolean)

(defun lsp-python-find-root(pyfile)
  (let ((root-path (locate-dominating-file default-directory pyfile)))
    (when root-path
      (file-name-nondirectory (directory-file-name root-path))
      )))

(defun lsp-python-virtualenv-name()
  (message (lsp-python-find-root "setup.py"))
  (let ((virtualenv (lsp-python-find-root "setup.py" )))
    (if virtualenv
        (pyvenv-workon virtualenv)
      virtualenv
      )
    )
  (lsp-python-find-root "setup.py")
  )

(defun lsp-python-prompt-install()
  "Check if pyls is in virtualenv and install if not.

Automatically call pyvenv-workon after that with the projectile
project's name.
"
  (require 'pyvenv)
  (when projectile-project-name
    (when (member projectile-project-name (pyvenv-virtualenv-list))
      (progn
        (pyvenv-workon projectile-project-name)
        (if (not (eql (call-process-shell-command "pyls -h" nil) 0))
            (progn
              (if (y-or-n-p (format "Install python-language-server in %s?" projectile-project-name))
                  (progn
                    (message "Installing python-language-server[all].")
                    (pyvenv-workon projectile-project-name)
                    (shell-command-to-string "pip install python-language-server\"[all\"]")
                    )
                nil)
              )
          nil
          )
        )
      )
    )
  )

(defun lsp-python--ls-command ()
  "Generate the language server startup command."
  (lsp-python-prompt-install)
  `("pyls" ,@lsp-python-server-args))

(lsp-define-stdio-client lsp-python "python" nil nil
                         :command-fn 'lsp-python--ls-command)

(provide 'lsp-python)
;;; lsp-python.el ends here
