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

;;; File: meta.lisp
;;; Description: Meta operations that LISA uses to support the manipulation of
;;; facts and instances.

;;; NB: A note on terminology. We make the distinction here between symbolic
;;; slot names and effective slot names. The former refers to an internal
;;; symbol, created by LISA, used to identify fact slots within rules; the
;;; latter refers to the actual, package-qualified slot name.

;;; $Id: meta.lisp,v 1.33 2002/05/22 21:03:24 youngde Exp $

(in-package "LISA")

(defclass meta-fact ()
  ((symbolic-name :initarg :symbolic-name
                  :reader get-name
                  :documentation
                  "The symbolic name for the fact, as used in rules.")
   (class-name :initarg :class-name
               :reader get-class-name
               :documentation
               "A symbol representing the fully qualified CLOS class name.")
   (slots :initform (make-hash-table)
          :reader get-slots
          :documentation
          "A hash table mapping symbolic slot names to their LISA
          representations, as implemented by class SLOT-NAME.")
   (effective-slots :reader get-effective-slots
                    :initform (make-hash-table)
                    :documentation
                    "A list of symbols representing the names of the slots
                    found in the class representing the fact.")
   (superclasses :initarg :superclasses
                 :initform '()
                 :reader get-superclasses
                 :documentation
                 "A list of symbols representing the ancestors of the class."))
  (:documentation
   "This class represents data about facts. Every LISA fact is backed by a
  CLOS instance that was either defined by the application or internally by
  LISA (via DEFTEMPLATE). META-FACT performs housekeeping chores; mapping
  symbolic fact names to actual class names, slot names to their underlying
  SLOT-NAME representation, etc."))

(defun find-meta-slot (meta-fact slot-name &optional (errorp t))
  "Locates in META-FACT the SLOT-NAME instance bound to the symbolic name
  SLOT-NAME. If ERRORP is non-nil, signals an error if the SLOT-NAME instance
  is not present (the default is T)."
  (let ((slot (gethash slot-name (get-slots meta-fact))))
    (when errorp
      (cl:assert (not (null slot)) nil
        "The class ~S has no meta slot named ~S."
        (get-class-name meta-fact) slot-name))
    slot))

(defun has-meta-slot-p (meta-fact slot-name)
  "Indicates whether or not META-FACT contains a SLOT-NAME instance bound to
  the symbolic name SLOT-NAME."
  (find-meta-slot meta-fact slot-name nil))
  
(defun meta-slot-count (meta-fact)
  "Returns the number of symbolic slots in META-FACT."
  (hash-table-count (get-slots meta-fact)))

(defun meta-slot-list (meta-fact &optional (include-hidden-slotsp nil))
  "Returns a list of all SLOT-NAME instances found in META-FACT. If
  INCLUDE-HIDDEN-SLOTSP is non-NIL, then include in the list any special slots
  (like :OBJECT) LISA has created."
  (let ((slots (list)))
    (maphash #'(lambda (key slot-name)
                 (declare (ignore key))
                 (push slot-name slots))
             (get-slots meta-fact))
    (if include-hidden-slotsp
        slots
      (delete-if #'(lambda (slot)
                     (eq (slot-name-name slot) :object))
                 slots :count 1))))

(defmethod initialize-instance :after ((self meta-fact) 
                                       &key slots effective-slots)
  "Initializes instances of class META-FACT. SLOTS is a list of symbolic slot
  names; EFFECTIVE-SLOTS is a list of actual slot names."
  (let ((slot-table (get-slots self))
        (position -1)
        (effective-slot-table (slot-value self 'effective-slots)))
    (mapc #'(lambda (slot-name)
              (setf (gethash slot-name slot-table)
                (make-slot-name slot-name (incf position))))
          slots)
    (mapc #'(lambda (slot)
              (setf (gethash (intern (symbol-name slot)) 
                             effective-slot-table) slot))
          effective-slots)))

(defun make-meta-fact (name class-name superclasses slots)
  "The constructor for class META-FACT. The symbolic name assigned to the fact
  is represented by NAME; the actual CLOS class name is CLASS-NAME;
  SUPERCLASSES is a list of symbols representing the names of ancestor
  classes; SLOTS is a list of symbolic slot names."
  (make-instance 'meta-fact
    :symbolic-name name
    :class-name class-name
    :superclasses superclasses
    :slots
    (append
     (mapcar #'(lambda (slot)
                 (intern (symbol-name slot))) slots)
     '(:object))
    :effective-slots slots))

(defmethod find-effective-slot ((self meta-fact) (slot-name symbol))
  "Finds the actual CLOS slot name as identified by the symbolic name
  SLOT-NAME."
  (let ((effective-slot (gethash slot-name (get-effective-slots self))))
    (cl:assert (not (null effective-slot)) ()
      "No effective slot for symbol ~S." slot-name)
    effective-slot))

(defmethod find-effective-slot ((self meta-fact) (slot slot-name))
  "Finds the actual CLOS slot name as identified by the symbolic name carried
  in the SLOT-NAME instance SLOT."
  (find-effective-slot self (slot-name-name slot)))

(defparameter *meta-map* (make-hash-table)
  "A hash table mapping a symbolic class name to its associated META-FACT
  instance.")
(defparameter *class-map* (make-hash-table))

(defun register-meta-fact (symbolic-name meta-fact)
  "Binds SYMBOLIC-NAME to a META-FACT instance."
  (setf (gethash symbolic-name *meta-map*) meta-fact))

(defun forget-meta-fact (symbolic-name)
  "Forgets the association between SYMBOLIC-NAME and a META-FACT instance."
  (remhash symbolic-name *meta-map*))

(defun forget-meta-facts ()
  "Forgets all associations in the META-FACT dictionary."
  (clrhash *meta-map*))

(defun has-meta-factp (symbolic-name)
  "See if SYMBOLIC-NAME has an associated META-FACT instance."
  (gethash symbolic-name *meta-map*))
  
(defun find-meta-fact (symbolic-name &optional (errorp t))
  "Locates the META-FACT instance associated with SYMBOLIC-NAME. If ERRORP is
  non-nil, signals an error if no binding is found."
  (let ((meta-fact (gethash symbolic-name *meta-map*)))
    (when errorp
      (cl:assert (not (null meta-fact)) nil
        "This fact name does not have a registered meta class: ~S"
        symbolic-name))
    meta-fact))

(defun register-external-class (symbolic-name class)
  (setf (gethash (class-name class) *class-map*) symbolic-name))

(defun find-symbolic-name (instance)
  (let ((name (gethash (class-name (class-of instance)) *class-map*)))
    (when (null name)
      (environment-error
       "The class of this instance is not known to LISA: ~S." instance))
    (values name)))

(defun generate-internal-methods (class)
  (eval
   `(defmethod mark-instance-as-changed ((self ,(class-name class))
                                         &optional (slot-id nil))
     (map-clos-instances #'mark-clos-instance-as-changed self slot-id)
     (values t))))

(defun import-class (class-name package-symbol use-inheritancep))
  
#+ignore
(defun import-class (symbolic-name class superclasses slot-specs)
  (flet ((validate-superclasses (class-list)
           (mapc #'(lambda (class-name)
                     (unless (has-meta-classp class-name)
                       (environment-error
                        "This class has not been registered: ~S" class-name)))
                 class-list)))
    (let ((meta (make-meta-shadow-fact
                 symbolic-name (class-name class) 
                 (validate-superclasses superclasses) slot-specs)))
      (register-meta-fact symbolic-name meta)
      (register-external-class symbolic-name class)
      (generate-internal-methods class)
      (values meta))))

(defun register-template (name class)
  "Creates and remembers the meta fact instance associated with a class. NAME
  is the symbolic name of the fact as used in rules; CLASS is the CLOS class
  instance associated with the fact."
  (let ((meta-fact
         (make-meta-fact name (class-name class)
                         nil (find-class-slots class))))
    (register-meta-fact name meta-fact)
    meta-fact))

(defparameter *initial-fact* nil
  "A special instance of FACT representing the initial fact.")

(defparameter *clear-fact* nil
  "A special instance of FACT used when clearing or resetting the inference
  engine.")

(defparameter *not-or-test-fact* nil
  "A special instance of FACT used when performing 'not' pattern matching.")

(defmacro make-special-fact (class-name)
  `(progn
     (defclass ,class-name () ())
     (register-meta-fact 
      ',class-name (make-meta-fact ',class-name ',class-name '() '()))
     (make-fact ',class-name '())))
    
(defun make-initial-fact ()
  (when (null *initial-fact*)
    (setf *initial-fact* (make-special-fact initial-fact)))
  *initial-fact*)

(defun make-clear-fact ()
  (when (null *clear-fact*)
    (setf *clear-fact* (make-special-fact clear-fact)))
  *clear-fact*)

(defun make-not-or-test-fact ()
  (when (null *not-or-test-fact*)
    (setf *not-or-test-fact* (make-special-fact not-or-test-fact)))
  *not-or-test-fact*)

(defun find-class-slots (class)
  (reflect:class-slot-list class))
