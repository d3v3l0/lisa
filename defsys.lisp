;;; This file is part of LISA, the Lisp-based Intelligent Software
;;; Agents platform.

;;; Copyright (C) 2000 David E. Young (de.young@computer.org)

;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation; either version 2
;;; of the License, or (at your option) any later version.

;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.

;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

;;; File: defsys.lisp
;;; Description: System definition file for LISA project.
;;;
;;; $Id: defsys.lisp,v 1.6 2000/11/04 02:28:28 youngde Exp $

(in-package "USER")

(defvar *lisa-root-pathname*
  (make-pathname :directory
                 (pathname-directory
                  (merge-pathnames *load-truename*
                                   *default-pathname-defaults*))))

(defvar *lisa-source-pathname*
  (make-pathname :directory
                 (append (pathname-directory *lisa-root-pathname*)
                         '("src"))))

(defvar *lisa-binary-pathname*
  (make-pathname :directory
                 (append (pathname-directory *lisa-root-pathname*)
                         #+Allegro '("lib" "acl")
                         #+LispWorks '("lib" "lispworks")
                         #+CMU '("lib" "cmucl")
                         #-(or Allegro LispWorks CMU) (error "Unsupported implementation."))))

(defun mkdir (path)
  #+CMU
  (unix:unix-mkdir
   (directory-namestring path)
   (logior unix:readown unix:writeown
           unix:execown unix:readgrp unix:execgrp
           unix:readoth unix:execoth))
  #+Allegro
  (excl:make-directory path)
  #+Lispworks
  (system:make-directory path))
  
;; Make sure the binary directory structure exists, creating it if
;; necessary...

(let ((dirlist '("packages" "engine" "utils")))
  (unless (probe-file *lisa-binary-pathname*)
    (mkdir *lisa-binary-pathname*))
  (dolist (dir dirlist)
    (let ((path (make-pathname
                 :directory (append (pathname-directory
                                     *lisa-binary-pathname*)
                                    `(,dir)))))
      (unless (probe-file path)
        (mkdir path)))))

#+ignore
(load (make-pathname :directory
                     (append (pathname-directory *lisa-root-pathname*)
                             '("contrib" "zebu-3.5.5"))
                     :name "defsys"))

(mk:defsystem "lisa"
    :source-pathname *lisa-source-pathname*
    :binary-pathname *lisa-binary-pathname*
    :source-extension "lisp"
    :components ((:module "packages"
                          :source-pathname "packages"
                          :binary-pathname "packages"
                          :components ((:file "pkgdecl")))
                 (:module "utils"
                          :source-pathname "utils"
                          :binary-pathname "utils"
                          :components ((:file "compose")
                                       (:file "utils"))
                          :depends-on (packages))
                 (:module "engine"
                          :source-pathname "engine"
                          :binary-pathname "engine"
                          :components ((:file "macros")
                                       (:file "token")
                                       (:file "node")
                                       (:file "node1"
                                              :depends-on (node))
                                       (:file "node1-tect"
                                              :depends-on (node1))
                                       (:file "node1-teq"
                                              :depends-on (node1))
                                       (:file "node1-rtl"
                                              :depends-on (node1))
                                       (:file "node-test"
                                              :depends-on (node))
                                       (:file "node2"
                                              :depends-on (node-test))
                                       (:file "test1")
                                       (:file "pattern")
                                       (:file "generic-pattern"
                                              :depends-on (test1 pattern))
                                       (:file "factories"
                                              :depends-on (generic-pattern))
                                       (:file "defrule"
                                              :depends-on (factories))
                                       (:file "parser"
                                              :depends-on (defrule macros))
                                       (:file "language"
                                              :depends-on (parser)))
                          :depends-on (packages utils))))