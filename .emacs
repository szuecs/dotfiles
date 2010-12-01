; load paths
(add-to-list 'load-path "~/emacs-libs/org-7.3/lisp")

; load modes
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;;;;;;;;;;;;; org mode - ultimate task planer
;; The following lines are always needed.  Choose your own keys.
;(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(global-font-lock-mode 1)                     ; for all buffers
(add-hook 'org-mode-hook 'turn-on-font-lock)  ; Org buffers only

; emacs <= 22.x specific
(transient-mark-mode 1)