

(define (read-from-string s)
  (read (open-input-string s)))


(define (decide-local-package-filename url)
  (string-append "/tmp/snow2-"
                 (number->string (current-process-id))
                 ".tgz"))


(define (download-file url local-filename)
  (display "downloading: ")
  (display url)
  (display " to ")
  (display local-filename)
  (newline)
  (with-input-from-request
   url #f
   (lambda ()
     (let ((outp (open-output-file local-filename))
           (data (read-string)))
       (write-string data #f outp)
       (close-output-port outp)
       #t))))


(define (get-repository repository-url)
  (with-input-from-request repository-url #f read-repository))


(define (snow2-install repository library-name)
  (let ((package (find-package-with-library repository library-name)))
    (cond ((not package)
           (report-error "didn't find a package with library: ~S\n"
                   library-name))
          (else
           (let* ((libraries (package-libraries package))
                  (urls (gather-depends repository libraries)))

             (for-each
              (lambda (url)
                (display "installing ~A")
                (display url)
                (newline)
                (let ((local-package-filename
                       (decide-local-package-filename url)))
                  (download-file url local-package-filename)
                  (tar-extract local-package-filename)
                  (delete-file local-package-filename)))
              urls))))))



(define (snow2-uninstall repository library-name)
  #f)



(define (usage pargs)
  (display (car pargs))
  (display " ")
  (display "<operation> '(library name)'")
  (newline)
  (display "  <operation> can be \"install\" or \"uninstall\"")
  (newline))


(define (main-program)
  (let* ((repository-url
          "http://snow2.s3-website-us-east-1.amazonaws.com/")
         (repository (get-repository repository-url))
         (pargs (command-line)))
    (cond ((not (= (length pargs) 3))
           (usage pargs))
          (else
           (let ((operation (list-ref pargs 1))
                 (library-name (read-from-string (list-ref pargs 2))))
             (cond ((equal? operation "install")
                    (snow2-install repository library-name))
                   ((equal? operation "uninstall")
                    (snow2-uninstall repository library-name))
                   ))))))
