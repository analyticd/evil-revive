# README

See comments in evil-revive.el for a full description of configuration
and use. This package depends on revive.el. If you wish to use my copy
of HIROSE Yuuji's excellent revive.el and window.el packages, together
which comprise revive, then you may get it here: https://github.com/analyticd/revive

Here is an example use-package config:

```elisp

;;; revive-config.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; Per-package configurations.

(use-package revive
  :load-path (lambda () (expand-file-name "revive" lisp-dir))
  :bind (:map ctl-x-map (("S" . revive:save-current-configuration)
                         ("F" . revive:resume)
                         ("K" . revive:wipe))))

(use-package windows
  ;; Use this with revive so that window splits are recallable too. windows.el
  ;; will require revive.el if Emacs is modern enough.
  :load-path (lambda () (expand-file-name "revive" lisp-dir))
  :config
  ;; TODO Is this necessary, seems like it would just slow down Emacs load time.
  (win:startup-with-window)
  (when (fboundp 'w3m)
    (setq revive:major-mode-command-alist-private
          '(("*w3m*"	. w3m)))))

(provide 'revive-config)

;;; revive-config.el ends here
```
