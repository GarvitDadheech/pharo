Class {
	#name : #RBRemoveClassRefactoringTest,
	#superclass : #RBAbstractTransformationTest,
	#category : #'Refactoring2-Transformations-Tests-Test'
}

{ #category : #accessing }
RBRemoveClassRefactoringTest class >> defaultTimeLimit [
	^20 seconds
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testCanRemoveAReferencedClassNotHavingReferenceInTheModel [

	| refactoring package |
	package := RBPackageEnvironment packageName:
		           RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	"here the model only contains classes and there is no reference to RBTransformationDummyRuleTest1 and it is a subclass."
	
	refactoring := RBRemoveClassRefactoring
		               model: model
		               classNames: { RBTransformationDummyRuleTest1 name }.
	"We can use a direct reference here because we want to check in particular that THIS reference is not taken 
	into account by the preconditions (They should not escape the model by directly using Pharo metamodel."
	

	self
		shouldnt: [ refactoring generateChanges ]
		raise: RBRefactoringError.

	self assert:
		(refactoring model classNamed: #RBTransformationDummyRuleTest1) isNil
]

{ #category : #'tests environment' }
RBRemoveClassRefactoringTest >> testCanRemoveUnreferencedClassUsingLimitedEnvironmentButReferencedElsewhere [

	| refactoring package |
	package := RBPackageEnvironment packageName: RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	"here the model only contains classes and there is no reference to RBTransformationDummyRuleTest1 and it is a subclass."
	refactoring := RBRemoveClassRefactoring 
							model: model 
							classNames: { RBTransformationDummyRuleTest1 name }.
	"Pay attention that we need a direct reference outside of the data for testing package."

	self
		shouldnt: [ refactoring generateChanges ]
		raise: RBRefactoringError.

	self assert:
		(refactoring model classNamed: #RBTransformationDummyRuleTest1) isNil
]

{ #category : #'tests environment' }
RBRemoveClassRefactoringTest >> testCanRemoveUnreferencedClassWithFullEnvironment [

	| refactoring |
	model := RBNamespace onEnvironment: RBBrowserEnvironment new .
	refactoring := RBRemoveClassRefactoring
		               model: model
		               classNames: { 'RBUnusedRootClass' asSymbol }.
	"Pay attention that we do not want to create a direct reference."

	self
		shouldnt: [ refactoring generateChanges ]
		raise: RBRefactoringError.

	self assert: (refactoring model classNamed: 'RBUnusedRootClass' asSymbol) isNil
]

{ #category : #'failure tests' }
RBRemoveClassRefactoringTest >> testFailureRaisesRBRefactoringErrorWhenRemovingNonEmptySuperclass [

	| class |
	class := ('RBTransformation' , 'RuleTestData1') asSymbol.
	self shouldFail:
		(RBRemoveClassRefactoring model: model classNames: { class })
]

{ #category : #'failure tests' }
RBRemoveClassRefactoringTest >> testFailureRemoveClassWithBadNameRaisesRBRefactoringError [

	self shouldFail:
		(RBRemoveClassRefactoring model: model classNames: { #NonExistantClassName })
]

{ #category : #'tests preconditions' }
RBRemoveClassRefactoringTest >> testPreconditionHasNoReferencesWithClassesWithReferencesBetweenThem [

	| refact classes |
	classes := RBClassEnvironment classes: { RBSharedPoolForTestData2 . RBRemoveClassRefactoringTest }.
	model := RBNamespace onEnvironment: classes.
	
	refact := RBRemoveClassRefactoring 
					model: model 
					classNames: { #RBSharedPoolForTestData2 . #RBRemoveClassRefactoringTest }.
	"RBSharedPoolForTestData2 refers to RBRemoveClassRefactoringTest and nobody else refers to them!"
	
	self assert: (refact preconditionHasNoReferences: (refact model classNamed: #RBSharedPoolForTestData2)) check.
]

{ #category : #'tests preconditions' }
RBRemoveClassRefactoringTest >> testPreconditionHasNoSymbolUseHandlesCorrectlyRemovedClasses [

	| refact classes |
	classes := RBClassEnvironment classes: { OnlyReferencing . OnlyReferencedByASymbol}.
	"since the model is only these classes, such references are not introducing extra references for the test"
	model := RBNamespace onEnvironment: classes.
	
	refact := RBRemoveClassRefactoring 
					model: model 
					classNames: { #OnlyReferencing . #OnlyReferencedByASymbol }.
		
	self assert: (refact preconditionHasNoUsers: (refact model classNamed: #OnlyReferencedByASymbol)) check.
	"It should be true because uses created by classes to be removed should not be counted."
	
]

{ #category : #'tests preconditions' }
RBRemoveClassRefactoringTest >> testPreconditionHasNoSymbolUseShouldFail [

	| refact classes |
	classes := RBClassEnvironment classes: { OnlyReferencing . OnlyReferencedByASymbol}.
	"since the model is only these classes, such references are not introducing extra references for the test"
	model := RBNamespace onEnvironment: classes.
	
	refact := RBRemoveClassRefactoring 
					model: model 
					classNames: { #OnlyReferencedByASymbol }.
		
	self deny: (refact preconditionHasNoUsers: (refact model classNamed: #OnlyReferencedByASymbol)) check.
	"It should be false because the referencing class is not removed and is part of the model"
	
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testPreconditionNotEmptyClass [

	| refactoring  package |
   package := RBPackageEnvironment packageName: RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	refactoring := RBRemoveClassRefactoring 
							model: model 
							classNames: { ('RBTransformation' , 'RuleTestData1') asSymbol}. 

	self deny: (refactoring preconditionEmptyOrHasNoSubclasses: (refactoring model classNamed: ('RBTransformation' , 'RuleTestData1') asSymbol)) check.
	
	
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testRemoveAClassAndTheirSubclass [

	| aRefactoring package |
	package := RBPackageEnvironment packageName: RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	aRefactoring := RBRemoveClassRefactoring
			 model: model
			 classNames: { #RBSharedPoolForTestData2 . #RBSharedPoolForTestData1 }.

	aRefactoring generateChanges.

	self deny: (model includesClassNamed: #RBSharedPoolForTestData2).
	self deny: (model includesClassNamed: #RBSharedPoolForTestData1)
]

{ #category : #'tests environment' }
RBRemoveClassRefactoringTest >> testRemoveAClassAndTheirSubclass2UsingAlimitedEnvironment [
	"This test verifies that the preconditions do not escape the metamodel."

	| aRefactoring package |
	package := RBPackageEnvironment packageName:
		           RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	
	aRefactoring := RBRemoveClassRefactoring
			 model: model
			 classNames: {RBFooDummyLintRuleTest1 name . RBFooDummyLintRuleTest1 subclasses first name }.

	aRefactoring generateChanges.

	self deny: (model includesClassNamed: RBFooDummyLintRuleTest1 name).
	self deny: (model includesClassNamed: RBFooDummyLintRuleTest1 subclasses first name)
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testRemoveClassesWithReferencesBetweenThem [

	| aRefactoring package |
	package := RBClassEnvironment classes:
		           { RBSharedPoolForTestData1 . RBSharedPoolForTestData2 . RBAbstractTransformationTest . RBRemoveClassRefactoringTest }.
	model := RBNamespace onEnvironment: package.
	aRefactoring := RBRemoveClassRefactoring
			 model: model
			 classNames: { #RBSharedPoolForTestData2 . #RBRemoveClassRefactoringTest }.

	aRefactoring generateChanges.

	self deny: (model includesClassNamed: #RBRemoveClassRefactoringTest).
	self deny: (model includesClassNamed: #RBSharedPoolForTestData2)
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testRemovingAnEmptyNonLeafClassIsAllowed [

	| refactoring  package sup |
   package := RBPackageEnvironment packageName: RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	refactoring := RBRemoveClassRefactoring 
							model: model 
							classNames: { #MyClassNonEmptyLeafUnused}.
	sup := (refactoring model classNamed: #MyClassNonEmptyLeafUnused).
	self assert: sup isNotNil.
	self deny: sup isEmptyClass.
	
	self assert: (refactoring preconditionEmptyOrHasNoSubclasses: sup) check.
	"It is not empty but it is a leaf so this is ok
	"
	self
		shouldnt: [ refactoring generateChanges ]
		raise: RBRefactoringError.

	self deny:
		(refactoring model includesClassNamed: #MyClassNonEmptyLeafUnused) 
]

{ #category : #tests }
RBRemoveClassRefactoringTest >> testRemovingAnEmptyNonLeafClassReparent [

	| refactoring  package class subclasses superRoot |
   package := RBPackageEnvironment packageName: RBFooDummyLintRuleTest1 packageName.
	model := RBNamespace onEnvironment: package.
	refactoring := RBRemoveClassRefactoring 
							model: model 
							classNames: { #MyClassB}.
	class := (refactoring model classNamed: #MyClassB).
	superRoot := class superclass.
	self assert: class isNotNil.
	self assert: class isEmptyClass.
	subclasses := class subclasses.

	self assert: (refactoring preconditionEmptyOrHasNoSubclasses: class) check.
	"It is empty but it has subclasses so this is ok they will be reparented
	"

	self
		shouldnt: [ refactoring generateChanges ]
		raise: RBRefactoringError.

	self deny:
		(refactoring model includesClassNamed: #MyClassB).
		
	subclasses do: [ :each | 
			self assert: (refactoring model includesClassNamed: each name).
			self assert: superRoot equals: each superclass.
		]
]

{ #category : #'failure tests' }
RBRemoveClassRefactoringTest >> testShouldWarnWhenRemovingClassWithReferences [

	self shouldWarn: 
		(RBRemoveClassRefactoring
			 model: model
			 classNames: { #RBBasicLintRuleTestData })
]