;;; This file is part of LISA, the Lisp-based Intelligent Software
;;; Agents platform.

;;; Copyright (C) 2000 David E. Young (de.young@computer.org)

;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Lesser General Public License
;;; as published by the Free Software Foundation; either version 2.1
;;; of the License, or (at your option) any later version.

;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU Lesser General Public License for more details.

;;; You should have received a copy of the GNU Lesser General Public License
;;; along with this library; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

;;; File: standard-kb-object.lisp
;;; Description: A mixin class used to support reasoning over user-define CLOS
;;; objects.

;;; $Id: standard-kb-object.lisp,v 1.2 2002/11/06 20:16:31 youngde Exp $

(in-package "LISA")

(defclass standard-kb-object ()
  ((symbolic-name :reader symbolic-name)
   (slot-table :reader slot-table
               :initform (make-hash-table))
   (slot-list :reader slot-list
              :initform (list))
   (use-inheritance-p :reader use-inheritance-p
                      :initform nil)
   (superclasses :initform (list)
                 :reader superclasses))
  (:documentation
   "A mixin class used to support reasoning over user-defined CLOS objects."))

(defmethod initialize-instance :after ((self standard-kb-object))
  (import-class self))

(defun import-class (kb-object)
  (labels ((register-slots (slot-pairs)
             (with-slots ((table slot-table) (slot-list slot-list)) kb-object
               (mapc #'(lambda (slot-pair)
                         (let ((slot-name (car slot-pair))
                               (effective-slot-name (cdr slot-pair)))
                           (setf (gethash slot-name table) 
                             effective-slot-name)
                           (push slot-name slot-list))))))
           (import-one-class (class direct-superclasses)
             (let* ((class-name (class-name class))
                    (symbolic-name
                     (intern (symbol-name class-name))))
               (setf (slot-value kb-object 'symbolic-name) symbolic-name)
               (setf (slot-value kb-object 'superclasses) direct-superclasses)
               (register-slots (reflect:class-slot-list class))
               (register-external-class symbolic-name class)))
           (import-classes (class)
             (let ((superclasses
                    (if (use-inheritance-p kb-object)
                        (reflect:find-direct-superclasses class)
                      (list))))
               (import-one-class class superclasses)
               (dolist (super superclasses)
                 (import-classes super)))))
    (import-classes (find-class kb-object))))
