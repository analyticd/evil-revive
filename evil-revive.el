;;; evil-revive.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; Author: @analyticd
;; Date: Jan 2, 2020
;;
;; Description: Provide vim-like :mksession and :source ex-commands that enable
;; saving named window configurations. Built on top of HIROSE Yuuji's excellent
;; revive.el and windows.el libraries. evil-revive offers additional features:
;;
;; - Restore session from list of sessions
;;   :so[urce]list
;;   :solist
;;   :sourcelist
;;
;; - Delete session from list of sessions
;;   :dels[ession]
;;   :dels
;;
;; - Rename session from list of sessions
;;   :ren[ame]session
;;   :rensession
;;
;; Further discussion:
;;
;; evil-revive either saves all window configurations to:
;;
;; 1. If `REVIVE:USE-CENTRALIZED-STORAGE-LOCATION-P' is non-nil, a central
;; location, `REVIVE:STORAGE-DIRECTORY', is where window configurations will be
;; saved. In this case you just provide a name. Note that you do NOT need to
;; put the name in quotes, e.g., :mksession foo or :mks foo.
;;
;; or
;;
;; 2. [this is the way that vim behaves by default] If
;; `REVIVE:USE-CENTRALIZED-STORAGE-LOCATION-P' is nil,
;; and
;;   a) Either you provide no name, in which case evil-revive will use the
;; filename 'Session.el' in the current working directory, or,
;;   b) you provide the full path to the file.
;;
;; Note, it is not necessary to provide a file suffix as part of the path.
;;
;; As a convenience, you can use M-x
;; `REVIVE:TOGGLE-USE-CENTRALIZED-STORAGE-LOCATION' to switch between
;; centralized or ad-hoc session storage location at any time as desired. The
;; value you set using this method will persist to your customization file.
;;
;; Please note that you can still use revive (see revive.el's comments) at the
;; same time as evil-revive. evil-revive does not change revive's normal
;; functionality of saving to ~/.revive.el your collection of numbered (rather
;; than named) configurations.
;;
;; Dependencies:
;;
;; Make sure these are in your load path:
;;
;; - revive.el  by HIROSE Yuuji, may be obtained here: https://www.emacswiki.org/emacs/WindowsMode
;; - windows.el by HIROSE Yuuji, may be obtained here: https://www.emacswiki.org/emacs/WindowsMode
;; - evil package

;;; Code:

(defgroup revive nil
  "Save and restore window configurations."
  :group  'text
  :tag    "Revive"
  :prefix "revive:"
  :link   '(url-link :tag "GitHub" "https://github.com/analyticd/evil-revive"))

(defcustom revive:use-centralized-storage-location-p t
  "Non-nil means that you want all your window configurations to be stored in `REVIVE:STORAGE-DIRECTORY.'"
  :group 'revive
  :type 'boolean)

(defcustom revive:default-filename "Session.el"
  "Default filename to use when none is provided."
  :group 'revive
  :type 'string)

;;;###autoload
(defun revive:toggle-use-centralized-storage-location ()
  "Flip current boolean value of `REVIVE:USE-CENTRALIZED-STORAGE-LOCATION-P.'
Useful for if, say, you are currently using the centralized location, but now
would like to save your configs to an arbitrary location, e.g., one in each
development project root directory."
  (interactive)
  (custom-set-variables '(revive:use-centralized-storage-location-p
                          (not revive:use-centralized-storage-location-p))))

(defcustom revive:storage-directory (expand-file-name "~/.revive")
  "Directory in which to save named configurations."
  :group 'revive
  :type '(directory))

(defun revive:path-or-default (&optional name-or-path)
  "Return path while taking into account logic with respect to centralized or
non-centralized storage settings."
  (if name-or-path
      (if revive:use-centralized-storage-location-p
          (expand-file-name name-or-path revive:storage-directory)
        name-or-path)
    (if revive:use-centralized-storage-location-p
        (expand-file-name revive:default-filename revive:storage-directory)
      (expand-file-name revive:default-filename))))

(defun revive:maybe-create-storage-directory ()
  "Does revive:storage-directory exist yet? If not, ask to create it."
  (when revive:use-centralized-storage-location-p
    (when (not (file-exists-p (expand-file-name revive:storage-directory)))
      (if (y-or-n-p (format "%s doesn't exist yet. Would you like me to create it?"
                            revive:storage-directory))
          (make-directory (file-name-directory revive:storage-directory) t)
        (error "Exiting. Please set the value of revive:storage-directory then try
again, or, do M-x revive:toggle-use-centralized-storage-location if you
wish.")))))

(defun revive:save-named-configuration (name-or-path)
  "Save named window configuration."
  (revive:maybe-create-storage-directory)
  ;; Save the named configuration
  (let ((path (revive:path-or-default name-or-path)))
    (message "Path: %s" path)
    (if (file-exists-p path)
        (if (y-or-n-p (format "%s exists. Do you want to overwrite it?" path))
            (with-temp-file path
              (insert (prin1-to-string (current-window-configuration-printable))))
          (message "Try again with a different name (or path if using ad-hoc storage location)."))
      (with-temp-file path
        (insert (prin1-to-string (current-window-configuration-printable)))))))

(defun revive:read-named-configuration-from-file (path)
  "Load lisp data, i.e., sexps, from file with PATH."
  (when (file-exists-p path)
    (with-temp-buffer
      (insert-file-contents path)
      (read (current-buffer)))))

(defun revive:restore-named-configuration (name-or-path)
  "Restore named window configuration."
  (let ((path (revive:path-or-default name-or-path)))
    (if (file-exists-p (expand-file-name path))
        (progn
          (restore-window-configuration (revive:read-named-configuration-from-file path))
          (message "Path: %s" path))
      (message "Sorry, window configuration named %s does not exist."))))

(defun revive:directory-files (directory)
  "Like `DIRECTORY-FILES', but excluding \".\" and \"..\"."
  (let* ((files (cons nil (directory-files directory)))
         (parent files)
         (current (cdr files))
         (exclude (list "." ".."))
         (file nil))
    (while (and current exclude)
      (setq file (car current))
      (if (not (member file exclude))
          (setq parent current)
        (setcdr parent (cdr current))
        (setq exclude (delete file exclude)))
      (setq current (cdr current)))
    (cdr files)))

(defun revive:ls ()
  "Return a list of window configurations."
  (revive:directory-files revive:storage-directory))

(defun revive:completing-read-fn ()
  "Prefer ivy-read to ido-completing-read to completing-read."
  (cond ((fboundp 'ivy-read)
         'ivy-read)
        ((fboundp 'ido-completing-read)
         'ido-completing-read)
        (t 'completing-read)))

(defun revive:restore-from-list ()
  "Let user choose which config to restore."
  (let ((path (revive:path-or-default
               (funcall (revive:completing-read-fn)
                        "Choose the configuration you want to restore: "
                        (revive:ls)))))
    (if (file-exists-p (expand-file-name path))
        (progn
          (restore-window-configuration (revive:read-named-configuration-from-file path))
          (message "Path: %s" path))
      (message "Sorry, window configuration named %s does not exist." path))))

(defun revive:delete-from-list ()
  "Let user choose which config to delete."
  (let ((path (revive:path-or-default
               (funcall (revive:completing-read-fn)
                        "Choose the configuration you want to delete: "
                        (revive:ls)))))
    (if (file-exists-p (expand-file-name path))
        (progn
          (delete-file (expand-file-name path))
          (message "Deleted path: %s" path))
      (message "Sorry, window configuration named %s does not exist." path))))

(defun revive:rename-session-from-list ()
  "Let user choose which config to rename."
  (let ((path (revive:path-or-default
               (funcall (revive:completing-read-fn)
                        "Choose the configuration you want to rename: "
                        (revive:ls)))))
    (if (file-exists-p (expand-file-name path))
        (progn
          (let ((newname (read-string "New name: ")))
            (setq newname (revive:path-or-default newname))
            (rename-file path newname)
            (message "Path %s renamed to path: %s"
                     path newname)))
      (message "Sorry, window configuration named %s does not exist." path))))

(evil-define-command mksession-cmd (&optional name-or-path)
  (interactive "<a>")
  (revive:save-named-configuration name-or-path))

(evil-define-command source-cmd (&optional name-or-path)
  (interactive "<a>")
  (revive:restore-named-configuration name-or-path))

(evil-define-command source-ls-cmd ()
  (interactive)
  (revive:restore-from-list))

(evil-define-command delete-session-cmd ()
  (interactive)
  (revive:delete-from-list))

(evil-define-command rename-session-cmd ()
  (interactive)
  (revive:rename-session-from-list))

(evil-ex-define-cmd "mks[ession]" 'mksession-cmd)

(evil-ex-define-cmd "so[urce]" 'source-cmd)

(evil-ex-define-cmd "so[urce]list" 'source-ls-cmd)

(evil-ex-define-cmd "dels[ession]" 'delete-session-cmd)

(evil-ex-define-cmd "ren[ame]session" 'rename-session-cmd)

(provide 'evil-revive)

;;; evil-revive.el ends here
