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

;;; File: node1-nop.lisp
;;; Description: Trivial Rete node whose test always fails.

;;; $Id: node1-nop.lisp,v 1.3 2001/04/23 21:48:58 youngde Exp $

(in-package "LISA")

(defclass node1-nop (node1)
  ()
  (:documentation
   "Trivial Rete node whose test always fails."))

(defmethod call-node-right ((self node1-nop) token)
  (call-next-method self token)
  (values nil))

(defmethod equals ((self node1-nop) (obj node1-nop))
  (values t))

(defun make-node1-nop ()
  (make-instance 'node1-nop))
