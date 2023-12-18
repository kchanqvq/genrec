(asdf:defsystem genrec
  :defsystem-depends-on ("literate-lisp")
  :depends-on (:serapeum
               :metabang-bind
               :trivia
               :alexandria
               :lparallel
               :vom
               :luckless
               :random-state
               #-aws-lambda :carrier
               :jonathan)
  :components ((:org "genrec")
               (:org "experiments" :depends-on ("genrec"))))
#+(and sbcl swank)
(in-package #:swank/source-path-parser)
#+(and sbcl swank)
(progn
  (when (sb-int:encapsulated-p 'guess-reader-state :literate-lisp)
    (sb-int:unencapsulate 'guess-reader-state :literate-lisp))
  (sb-int:encapsulate 'guess-reader-state :literate-lisp
                      (lambda (orig-func stream)
                        (multiple-value-bind (readtable package)
                            (funcall orig-func stream)
                          (let ((point (file-position stream)))
                            (file-position stream 0)
                            (let ((line (read-line stream nil nil)))
                              (file-position stream point)
                              (when (and line (starts-with-p line "# "))
                                (setq readtable (copy-readtable readtable))
                                (let ((*readtable* readtable))
                                  (literate-lisp:install-globally))))
                            (values readtable package)))))
  (when (sb-int:encapsulated-p 'source-path-file-position :literate-lisp)
    (sb-int:unencapsulate 'source-path-file-position :literate-lisp))
  (sb-int:encapsulate 'source-path-file-position :literate-lisp
                      (lambda (orig-func path filename)
                        (if (string-equal (string-downcase (pathname-type filename))
                                          "org")
                            (let ((*readtable* (copy-readtable *readtable*)))
                              (literate-lisp:install-globally)
                              (funcall orig-func path filename))
                            (funcall orig-func path filename)))))
(asdf:defsystem genrec/aws-lambda
  :defsystem-depends-on ("cl-aws-lambda/asdf")
  :class :lambda-system
  :depends-on (:genrec))
