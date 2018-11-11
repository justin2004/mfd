(defpackage "MANGOAPPS-FOLDER-DOWNLOAD"
  (:use "COMMON-LISP" "SB-DEBUG" "SB-EXT" "SB-ALIEN" "SB-GRAY" "SB-PROFILE") ; one of them for gc (i think)
  (:nicknames "MFD")
  (:export "RECURSE" "GET_BIG_JSON" "SET_SESSION_KEY"))

(in-package mangoapps-folder-download)


; notes

; http calls don't check for a good status code

; in general there is little error checking/handling

; i named the functions, variables, etc. while i was experimenting and i haven't gone back and made them more cogent

; i haven't concern myself heavily with indentation conventions
; i don't find indentation conventions as intuitive with lisp as i do for, say, c




; i think we need the following because we are not running sbcl in a way that sources the quicklisp init file(s)

;;; The following lines added by ql:add-to-init-file:
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))



; this might be a library function somewhere
(defun remove_nulls (lis)
   (if (null lis)
     NIL
   (let ((result  
    (reduce
        #'(lambda (sofar next)
            ;(format t "sofar is ~A, next is ~A~%" sofar next)
    	(if (not (listp sofar))
    	    (if (null next)
    	        sofar 
    	        (append (list sofar) (list next)))
    	    (if (null next)
    	        sofar
                    (append sofar (list next)))))
    lis :initial-value '())))
    (if (not (listp result))
      (list result)
      result))))




; can i use require instead of quickload?
(ql:quickload "alexandria")
(ql:quickload "cl-json")
(ql:quickload :drakma) ; symbol or string work


(setf drakma:*text-content-types* nil) ; treat everything as a byte array. when we know a json object is coming and we need to parse it we can convert it to a string


(defun write_to_file (byte_vector filename) 
  (let ((fd (open filename :direction :output :element-type 'unsigned-byte)))
    (mapcar #'(lambda (byte) (write-byte byte fd)) (map 'list #'identity byte_vector))
    (close fd)))



(defun get_big_json (folder)
  ;(let* ((session_key (sb-unix::posix-getenv "mango_session_id"))
  (let* ((cookiej (make-instance 'drakma:cookie-jar :cookies (list (make-instance 'drakma:cookie :name "_felix_session_id" :value session_key :domain "mangoapps.com"))))
	 (url (concatenate 'string "https://mangoapis.mangoapps.com/api/folders/" folder "/files.json?include_folders=1")))
    (json:decode-json
      (make-string-input-stream
        (map 'string #'code-char
	  (multiple-value-bind (body status_code header_alist reply_uri reply_stream close_stream? reason_phrase) 
	    (drakma:http-request url :cookie-jar cookiej) ; hopefully the byte array contents of body can all be converted to chars
	    (if (= 200 status_code)
	      body
	      (bail status_code reason_phrase)))))))) ; maybe unauthorized?


(defun bail (status_code reason_phrase)
  (format t "http status code was ~A (~A)~%" status_code reason_phrase)
  (sb-ext:quit))


(defun get_file_list (folder)
    (json_to_file_list (get_big_json folder)))


; TODO we should be using the multiple-value-bind call and handling errors
(defun get_file (url)
  ;(let* ((session_key (sb-unix::posix-getenv "mango_session_id"))
  (let* ((cookiej (make-instance 'drakma:cookie-jar :cookies (list (make-instance 'drakma:cookie :name "_felix_session_id" :value session_key :domain "mangoapps.com")))))
    ;(multiple-value-bind (a b c d e f g) (drakma:http-request url :cookie-jar cookiej) a)))
    (drakma:http-request url :cookie-jar cookiej)))

    

(defun json_to_file_list (big_json) ; returns a list of assocs (one for each file)  -- big_json should be the return val of json:decode-json
  (cdr (assoc ':files (cdr (assoc ':ms--response big_json)))))
;  (cdr (assoc ':files (cdr (assoc ':ms--response alpha)))))

(defun json_to_dirname (big_json)
  (cdr (assoc ':name (cdr (assoc ':ms--response big_json)))))

(defun get_subdir_ids (file_list)
  (remove_nulls (mapcar #'(lambda (x) (if (cdr (assoc ':is--folder x)) (cdr (assoc ':id x)))) file_list)))

(defun get_nondir_ids (file_list)
  (remove_nulls (mapcar #'(lambda (x) (if (not (cdr (assoc ':is--folder x))) (cdr (assoc ':id x)))) file_list)))

(defun get_nondir_filenames (file_list)
  (remove_nulls (mapcar #'(lambda (x) (if (not (cdr (assoc ':is--folder x))) (cdr (assoc ':filename x)))) file_list)))

(defun get_nondir_urls (file_list)
  (remove_nulls (mapcar #'(lambda (x) (if (not (cdr (assoc ':is--folder x))) (cdr (assoc ':short--url x)))) file_list)))

(defun get_nondir_filenames_urls (file_list)
  (remove_nulls (mapcar #'(lambda (x) (if (not (cdr (assoc ':is--folder x))) (list (cdr (assoc ':filename x))  (cdr (assoc ':short--url x)) ))) file_list)))


(defun set_session_key (key) 
  (setf session_key key)) ; TODO is this setting global enough?
                          ; ... should be top level in the package, right?


; TODO figure out why i needed the gc call so often and maybe try to use tail recursion
(defun recurse (leading_path big_json) ; maybe ensure leading path is relative?    assume trailing / if not null
; create dir, fill with files, cd into each subdir and call again
  (let ((dirname (json_to_dirname big_json))
        (filelist (json_to_file_list big_json)))
    (ensure-directories-exist (concatenate 'string leading_path dirname "/"))
    ;(mapcar #'(lambda (filename_and_url_pair) (write_to_file (get_file (cadr filename_and_url_pair)) (concatenate 'string dirname "/" (car filename_and_url_pair)))) (get_nondir_filenames_urls filelist))))
    (dolist (filename_and_url_pair (get_nondir_filenames_urls filelist))
      (sb-ext:gc)
      (format t "working on ~A~%"  (concatenate 'string leading_path dirname "/" (car filename_and_url_pair))) 
      (if (not (probe-file  (concatenate 'string leading_path dirname "/" (car filename_and_url_pair)))) ; if file does not exist then download and write it
        (write_to_file (get_file (cadr filename_and_url_pair)) (concatenate 'string leading_path dirname "/" (car filename_and_url_pair)))))
    ; all files in this level are done now do all the subdirs
    (dolist (folder_id (get_subdir_ids filelist)) (recurse (concatenate 'string leading_path dirname "/") (get_big_json (write-to-string folder_id))))))



