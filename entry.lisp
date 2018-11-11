#!/usr/bin/sbcl --script

; i used the .lisp extension so my text editor would do syntax highlighting for
; lisp


; i needed to add this because we won't be invoking sbcl directly so i dont
; think .sbclrc will be sourced

;;; The following lines added by ql:add-to-init-file:
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))






(load "mfd.lisp")
; gives us the mfd package with 2 or 3 symbols exported



(ql:quickload :unix-opts)
;              ^ "opts"

(opts:define-opts
  (:name :help
   :description "help text"
   :short #\h
   :long "help")

  (:name :cookie
   :description "obtain from your browser once you log in"
   :long "cookie"
   :arg-parser #'identity
;   :required t
   :short #\c)

  (:name :folder
   :description "folder id visible in the URL"
   :long "folder"
   :arg-parser #'identity    ; string should be fine
;   :required t
   :short #\f))


;(format t "~A~%" sb-ext:*posix-argv*)
;(format t "~A~%" (length sb-ext:*posix-argv*))


(defun unknown-option (condition)
  (format t "warning: ~s option is unknown!~%" (opts:option condition))
  (invoke-restart 'opts:skip-option))

(defmacro when-option ((options opt) &body body)
  `(let ((it (getf ,options ,opt)))
     (when it
       ,@body)))

(multiple-value-bind (options free-args)
    (handler-case
        (handler-bind ((opts:unknown-option #'unknown-option))
          (opts:get-opts))
      (opts:missing-arg (condition)
        (format t "fatal: option ~s needs an argument!~%"
                (opts:option condition)))
      (opts:arg-parser-failed (condition)
        (format t "fatal: cannot parse ~s as argument of ~s~%"
                (opts:raw-arg condition)
                (opts:option condition)))
      (opts:missing-required-option (con)
        (format t "fatal: ~a~%" con)
        (opts:exit 1)))
  ;; Here all options are checked independently, it's trivial to code any
  ;; logic to process them.
  (when-option (options :help)
    (opts:describe
     :prefix "MangoApps Folder Download utility"
;     :suffix ""
     :usage-of "./entry.lisp"
     :args     "[FREE-ARGS]")
     (opts:exit 1))
  (let ((cookie (getf options :cookie))
        (folder (getf options :folder)))
       (if (and (not (null cookie))
                (not (null folder)))
	   ; got a cookie and a folder so do the recursive download
	   (progn
             (mfd:set_session_key cookie)
             (setf bj (mfd:get_big_json folder))
             (mfd:recurse "/mnt/" bj)) 
	   ; need both a cookie and a folder
           (format t "need a cookie and a folder~%"))))
