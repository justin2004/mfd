(quicklisp-quickstart:install)

(in-package #:ql-util)
(setf *do-not-prompt* t)

(ql:add-to-init-file)

; do this now during container image build to make running the container faster
; TODO need to link the quicklisp libs actually used so this list will be updated if more libs are used
; in the future
(ql:quickload "alexandria")
(ql:quickload "cl-json")
(ql:quickload :drakma)


