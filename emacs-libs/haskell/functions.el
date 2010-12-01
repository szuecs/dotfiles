;; by xsteve

(defun my-insert-date (dayincr)
  "Inserts a date-stamp at point - Format: \"DD-MM-YYYY (wd)\""
  (interactive "p")
  (if (null current-prefix-arg) (setq dayincr 0))
  (let* ((base 65536.0)
         (nowlist (current-time))
         (datenum (+ (*  (nth 0 nowlist) base) (nth 1 nowlist)
                     (* dayincr 60.0 60.0 24.0)))
         (s (current-time-string
             (list (truncate( / datenum base)) (truncate(mod datenum base)))))
         (date))
    (if (equal current-prefix-arg '(4))
        (progn
          (let ((bound (line-beginning-position))
                (datenum)
                (datestring))
            (goto-char (min (point-max) (+ (point) 10)))
            (re-search-backward "[0-9][0-9]\\.[0-9][0-9]\\.[0-9][0-9][0-9][0-9]" bound)
            (setq datestring (buffer-substring (point) (+ (point) 10)))
            (setq datenum (calendar-absolute-from-gregorian
                           (list
                            (string-to-number (substring datestring 3 5))
                            (string-to-number (substring datestring 0 2))
                            (string-to-number (substring datestring 6 10)))))
            (setq dayincr (string-to-number (read-string "Increment by days: " "7")))
            (delete-region (point) (+ 10 (point)))
            (setq date (calendar-gregorian-from-absolute (+ datenum dayincr)) datestring)))
      (setq date (list (length (member (substring s 4 7)
                                       '("Dec" "Nov" "Oct" "Sep" "Aug" "Jul"
                                         "Jun" "May" "Apr" "Mar" "Feb" "Jan")))
                       (string-to-number (substring s 8 10))
                       (string-to-number (substring s 20 24)))))
                       ;;(cdr (assoc (substring s 0 3)
                       ;;            '(("Son" . "So")("Mon" . "Mo")("Tue" . "Di")
                       ;;              ("Wed" . "Mi")("Thu" . "Do")("Fri" . "Fr")
                       ;;              ("Sat" ."Sa")))))))

    (insert (format "%02d.%02d.%04d" (nth 1 date) (nth 0 date) (nth 2 date)))))
    ;(message "%s" date)))

(defun calendar-week-number (date)
  (+ 1 (/ (calendar-day-number date) 7)))

(defun my-remove-trailing-spaces ()
  "Remove trailing spaces in the whole buffer."
  (interactive)
  (save-match-data
    (save-excursion
      (let ((remove-count 0))
        (goto-char (point-min))
        (while (re-search-forward "[ \t]+$" (point-max) t)
          (setq remove-count (+ remove-count 1))
          (replace-match "" nil nil))
        (message (format "%d Trailing spaces removed from buffer." remove-count))))))

(defun my-remove-control-M ()
  "Remove ^M at end of line in the whole buffer."
  (interactive)
  (save-match-data
    (save-excursion
      (let ((remove-count 0))
        (goto-char (point-min))
        (while (re-search-forward "
$" (point-max) t)
          (setq remove-count (+ remove-count 1))
          (replace-match "" nil nil))
        (message (format "%d ^M removed from buffer." remove-count))))))
