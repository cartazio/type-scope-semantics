\documentclass[preprint,10pt]{sigplanconf}

\usepackage{amsmath,amstext,amsthm}
\usepackage{agda} 
\usepackage{upgreek}
\usepackage[english]{babel}
\usepackage{cleveref,hyperref}
\usepackage{catchfilebetweentags}

\setlength\mathindent{0em}

\usepackage{todonotes}
\usepackage{mathpartir}
\include{commands}

\newtheorem{lemma}{Lemma}
\newtheorem{theorem}{Theorem}
\newtheorem{corollary}{Corollary}

\begin{document}

\special{papersize=8.5in,11in}
\setlength{\pdfpageheight}{\paperheight}
\setlength{\pdfpagewidth}{\paperwidth}

\conferenceinfo{CONF 'yy}{Month d--d, 20yy, City, ST, Country}
\copyrightyear{20yy}
\copyrightdata{978-1-nnnn-nnnn-n/yy/mm}
\copyrightdoi{nnnnnnn.nnnnnnn}

\title{Type-and-Scope Safe Programs and their Proofs}
% \subtitle{Subtitle Text, if any}

\authorinfo{Guillaume Allais}
           {gallais@cs.ru.nl}
           {Radboud University Nijmegen}
\authorinfo{James Chapman}
           {james.chapman@strath.ac.uk}
           {University of Strathclyde}
\authorinfo{Conor McBride}
           {conor.mcbride@strath.ac.uk}
           {University of Strathclyde}
\maketitle

\todo{citeyear as much as possible}
\todo{7.2 \& 7.3: edited highlights only}

\begin{abstract}

We abstract the common type-and-scope safe structure from
computations on $λ$-terms that deliver, e.g., renaming, substitution, evaluation,
CPS-transformation, and printing with a name supply. By
exposing this structure, we can prove generic simulation
and fusion lemmas relating operations built this way.

%We introduce a notion of type and scope preserving semantics
%generalising Goguen and McKinna's ``Candidates for Substitution''
%approach to defining one traversal generic enough to be instantiated
%to renaming first and then substitution. Its careful distinction of
%environment and model values as well as its variation on a structure
%typical of a Kripke semantics make it capable of expressing renaming
%and substitution but also various forms of Normalisation by Evaluation
%and, perhaps more surprisingly, monadic computations such
%as a printing function.

%We then demonstrate that expressing these algorithms in a common
%framework yields immediate benefits: we can deploy some logical
%relations generically over these instances and obtain for instance
%the fusion lemmas for renaming, substitution and normalisation by
%evaluation as simple corollaries of the appropriate fundamental
%lemma. All of this work has been formalised in Agda.

\end{abstract}

\section{Introduction}

A programmer implementing an embedded language with bindings has a
wealth of possibilities. However, should she want to be able to inspect
the terms produced by her users in order to optimise or even compile
them, she will have to work with a deep embedding. Which means that she
will have to (re)implement a great number of traversals doing such
mundane things as renaming, substitution, or partial evaluation.
Should she want to get help from the typechecker in order to fend
off common bugs, she can opt for inductive families~\cite{dybjer1991inductive}
to enforce precise invariants. But the traversals now have to be
invariant preserving too!

In an unpublished manuscript, McBride~(\citeyear{mcbride2005type}) spots
the similarities between the types and implementations of renaming
and substitution for the (scoped and typed) simply typed $λ$-calculus
(ST$λ$C) in a dependently typed language. He then carves out a notion
of ``Kit'' abstracting the difference between the two. The
\ARF{Kit.─} uses generalising the traversal are shown (in pink)
in \cref{kit}.

The contribution of the present paper is twofold:
\begin{itemize}
\item{} We generalise the ``Kit'' approach from syntax to semantics
bringing operations like normalisation (cf.~\cref{nbe}) and printing
with a name supply into our framework.

\item{} We take advantage of this newfound uniformity to prove
generic results about simulations between and fusions of semantics
given by a Kit.
\end{itemize}


\begin{figure}[h]
\ExecuteMetaData[motivation.tex]{ren}

\ExecuteMetaData[motivation.tex]{sub}
\caption{Renaming\label{ren} and Substitution\label{sub} for the ST$λ$C}

\ExecuteMetaData[motivation.tex]{kit}
\caption{Kit traversal for the ST$λ$C\label{kit}}

\ExecuteMetaData[motivation.tex]{nbe}
\caption{Normalisation by Evaluation for the ST$λ$C\label{nbe}}
\end{figure}

\paragraph{Outline} We shall start by defining the simple calculus we will use
as a running example. We will then introduce a notion of environments as well
as one well known instance: the preorder of renamings. This will lead
us to defining a generic notion of type and scope-preserving Semantics
together with a generic evaluation function. We will then showcase the
ground covered by these Semantics: from the syntactic ones corresponding
to renaming and substitution to printing with names or some variations on Normalisation
by Evaluation. Finally, we will demonstrate how, the definition of Semantics
being generic enough, we can prove fundamental lemmas about these evaluation
functions: we characterise the semantics which are synchronisable and give an
abstract treatment of composition yielding compaction and reuse of proofs
compared to Benton et al.~(\citeyear{benton2012strongly})

\paragraph{Notations}\todo{revisit} This article is a literate Agda file typeset using the
\LaTeX{} backend with as little post-processing as possible: we simply hide
telescopes of implicit arguments as well as \APT{Set} levels and properly display (super / sub)-scripts
as well as special operators such as \AF{>>=} or \AF{++}. As such, a lot of
the notations have a meaning in Agda: \AIC{green} identifiers are data constructors,
\ARF{pink} names refer to record fields, and \AF{blue} is characteristic of
defined symbols. Underscores have a special status: when defining mixfix
identifiers~\cite{danielsson2011parsing}, they mark positions where arguments
may be inserted; our using the development version of Agda means that we have
access to Haskell-style sections i.e. one may write \AF{\_+} \AN{5} for the partial
application of \AF{\_+\_} corresponding to \AS{λ} \AB{x} \AS{→} \AB{x} \AF{+} \AN{5}
or, to mention something that we will use later on, \AF{Renaming} \AF{⊨⟦\_⟧\_}
for the partial application of \AF{\_⊨⟦\_⟧\_} to \AF{Renaming}.

\paragraph{Formalisation} This whole development\footnote{\url{https://github.com/gallais/type-scope-semantics}}
has been checked by Agda~\cite{norell2009dependently} which guarantees that all
constructions are indeed well typed, and all functions are total. Nonetheless, it
should be noted that the generic model constructions and the various examples of
\AR{Semantics} given here, although not the proofs, can be fully replicated in
Haskell using type families, higher rank polymorphism and generalised algebraic
data types to build singletons~\cite{eisenberg2013dependently} providing the user
with the runtime descriptions of their types or their contexts' shapes.


\AgdaHide{
\begin{code}
{-# OPTIONS --copatterns #-}
module models where

open import Level as L using (Level ; _⊔_)
open import Data.Empty
open import Data.Unit renaming (tt to ⟨⟩)
open import Data.Bool
open import Data.Sum hiding (map ; [_,_])
open import Data.Product hiding (map)
open import Function as F hiding (_∋_ ; _$_)
\end{code}}

\section{The Calculus and its Embedding}

\[\begin{array}{rrl}
σ, τ    & ∷= & \mathtt{1} \quad{}|\quad{} \mathtt{2} \quad{}|\quad{} σ → τ \\

b, t, u & ∷= & x \quad{}|\quad{} t\,u \quad{}|\quad{} λx.\, b \quad{}|\quad{}  ⟨⟩ \\
        & |  & \mathtt{tt} \quad{}|\quad{} \mathtt{ff} \quad{}|\quad{} \mathtt{if}~ b ~\mathtt{then}~ t ~\mathtt{else}~ u
\end{array}\]

We work with the above simply typed $λ$-calculus deeply embedded in Agda.
It comes with \texttt{1} and \texttt{2} as base types and serves as
a minimal example of a system with a record type equipped with an η-rule
and a sum type. We embed each category of the grammar as an inductive family
in Agda, and to each production corresponds a constructor, which we
distinguish with a prefix backtick \AIC{`}.

\AgdaHide{
\begin{code}
infixr 20 _`→_
infixl 10 _∙_
\end{code}}
%<*ty>
\begin{code}
data Ty : Set where
  `1 `2  : Ty       -- Both base types
  _`→_   : Ty → Ty  → Ty
\end{code}
%</ty>

To talk about the types of the variables in scope, we need \emph{contexts}.
We choose to represent them as ``snoc'' lists of types; \AIC{ε} denotes the
empty context and \AB{Γ} \AIC{∙} \AB{σ} the context \AB{Γ} extended with a
fresh variable of type \AB{σ}.

%<*context>
\begin{code}
data Cx : Set where
  ε    : Cx
  _∙_  : Cx → Ty → Cx
\end{code}
%</context>


\todo{Fix [\_]}
\todo{Explain pointwise}
\begin{code}
[_] : {ℓ^A : Level} → (Cx → Set ℓ^A) → Set ℓ^A
[ T ] = ∀ {Γ} → T Γ

_⟶_ : {ℓ^A ℓ^E : Level} → (Cx → Set ℓ^A) → (Cx → Set ℓ^E) → (Cx → Set (ℓ^A ⊔ ℓ^E))
(S ⟶ T) Γ = S Γ → T Γ
\end{code}

The \AF{\_⊢\_} operator mechanizes the mathematical convention of only
mentioning context \emph{extensions} when presenting judgements~\cite{martin1982constructive}.

\begin{code}
_⊢_ : {ℓ^A : Level} → Ty → (Cx → Set ℓ^A) → (Cx → Set ℓ^A)
(σ ⊢ S) Γ = S (Γ ∙ σ)
\end{code}

\AgdaHide{
\begin{code}
infixr 5 _⟶_
infixr 6 _∙⊎_
_∙⊎_ : {ℓ^A ℓ^E : Level} → (Cx → Set ℓ^A) → (Cx → Set ℓ^E) → (Cx → Set (ℓ^A ⊔ ℓ^E))
(S ∙⊎ T) Γ = S Γ ⊎ T Γ

infixr 7 _∙×_
_∙×_ : {ℓ^A ℓ^E : Level} → (Cx → Set ℓ^A) → (Cx → Set ℓ^E) → (Cx → Set (ℓ^A ⊔ ℓ^E))
(S ∙× T) Γ = S Γ × T Γ

infixr 6 _⊢_
\end{code}}

Variables are then positions in such a context represented as typed de
Bruijn~(\citeyear{de1972lambda}) indices. As shown in the comments, this
amounts to an inductive definition of context membership. We use the
combinators defined above to show only local changes to the context.

%<*var>
\begin{code}
data Var (τ : Ty) : Cx → Set where
  ze  :            -- ∀ Γ. Var τ (Γ ∙ τ)
                   [          τ ⊢ Var τ ]
  su  :            -- ∀ Γ σ. Var τ Γ → Var τ (Γ ∙ σ)
       {σ : Ty} →  [ Var τ ⟶  σ ⊢ Var τ ]

\end{code}
%</var>

The syntax for this calculus guarantees that terms are well scoped-and-typed
by construction. This presentation due to
Altenkirch and Reus~(\citeyear{altenkirch1999monadic}) relies heavily on
Dybjer's~(\citeyear{dybjer1991inductive}) inductive families. Rather than
having untyped pre-terms and a typing relation assigning a type to
them, the typing rules are here enforced in the syntax. Notice that
the only use of \AF{\_⊢\_} to extend the context is for the body of
a $λ$.

\AgdaHide{
\begin{code}
open import Data.Nat as ℕ using (ℕ ; _+_)

size : Cx → ℕ
size ε        = 0
size (Γ ∙ _)  = 1 + size Γ

infixl 5 _`$_
\end{code}}
%<*term>
\begin{code}
data Tm : Ty → (Cx → Set) where
  `var     : {σ : Ty} →    [ Var σ ⟶                 Tm σ         ]
  _`$_     : {σ τ : Ty} →  [ Tm (σ `→ τ) ⟶ Tm σ ⟶    Tm τ         ]
  `λ       : {σ τ : Ty} →  [ σ ⊢ Tm τ ⟶              Tm (σ `→ τ)  ]
  `⟨⟩      :               [                         Tm `1        ]
  `tt `ff  :               [                         Tm `2        ]
  `if      : {σ : Ty} →    [ Tm `2 ⟶ Tm σ ⟶ Tm σ ⟶   Tm σ         ]
\end{code}
%</term>
\section{A Generic Notion of Environment}

\todo{Rename Cx -> Ty -> Set}
\todo{$𝓔 -> 𝓥$; $𝓜 -> 𝓒$; -Eval -> -Comp}
\todo{call lemma comp and show its type early}

All the semantics we are interested in defining associate to a term \AB{t}
of type \AB{Γ} \AD{⊢} \AB{σ}, a value of type \AB{𝓜} \AB{Γ} \AB{σ} given
an interpretation \AB{𝓔} \AB{Δ} {τ} for each one of its free variables
\AB{τ} in \AB{Γ}. We call the collection of these interpretations an
\AB{𝓔}-(evaluation) environment. We leave out \AB{𝓔} when it can easily
be inferred from the context.

The content of environments may vary wildly between different semantics:
when defining renaming, the environments will carry variables whilst the
ones used for normalisation by evaluation contain elements of the model.
But their structure stays the same which prompts us to define the notion
generically. Formally, this translates to \AB{𝓔}-environments being the
pointwise lifting of the relation \AB{𝓔} between contexts and types to a
relation between two contexts. Rather than using a datatype to represent
such a lifting, we choose to use a function space. This decision is based
on Jeffrey's observation~(\citeyear{jeffrey2011assoc}) that one can obtain
associativity of append for free by using difference lists. In our case the
interplay between various combinators (e.g. \AF{refl} and \AF{trans})
defined later on is vastly simplified by this rather simple decision.

\AgdaHide{
\begin{code}
infix 5 _-Env
\end{code}}\todo{Fix mangled Levels}
%<*environment>
\begin{code}
Model : (ℓ^A : Level) → Set (L.suc ℓ^A)
Model ℓ^A = Ty → Cx → Set ℓ^A

record RModel {ℓ^E ℓ^M : Level} (𝓔 : Model ℓ^E) (𝓜 : Model ℓ^M) (ℓ^R : Level) : Set (ℓ^E ⊔ ℓ^M ⊔ L.suc ℓ^R) where
  constructor mkRModel
  field rmodel : {σ : Ty} → [ 𝓔 σ ⟶ 𝓜 σ ⟶ const (Set ℓ^R) ]
open RModel public

record _-Env {ℓ^A : Level} (Γ : Cx) (𝓔 : Model ℓ^A) (Δ : Cx) : Set ℓ^A where
  constructor pack
  field lookup : {σ : Ty} → Var σ Γ → 𝓔 σ Δ
open _-Env public

_-Eval : {ℓ^A : Level} → Cx → (𝓒 : Model ℓ^A) → Cx → Set ℓ^A
(Γ -Eval) 𝓒 Δ = {σ : Ty} → Tm σ Γ → 𝓒 σ Δ
\end{code}

\todo{Insert here type of lemma we want to prove}
\todo{Expand the definition of box}
\todo{Move after Thinnable}
\begin{code}
□ : {ℓ^A : Level} → (Cx → Set ℓ^A) → (Cx → Set ℓ^A)
(□ S) Γ = [ (Γ -Env) Var ⟶ S ]
\end{code}
%</environment>

\AgdaHide{
\begin{code}
infixl 10 _`∙_
\end{code}}

For a fixed context \AB{Δ} and relation \AB{𝓔}, these environments can
be built step by step by noticing that the environment corresponding to
an empty context is trivial and that one may extend an already existing
environment provided a proof of the right type. In concrete cases, there
will be no sensible way to infer \AB{𝓔} when using the second combinator
hence our decision to make it possible to tell Agda which relation we are
working with.\todo{explain copatterns}

\begin{code}
`ε : {ℓ^A : Level} {Δ : Cx} {𝓔 : Model ℓ^A} → (ε -Env) 𝓔 Δ
_`∙_ :  {ℓ^A : Level} {Γ : Cx} {𝓔 : Model ℓ^A} {σ : Ty} → [ (Γ -Env) 𝓔 ⟶ 𝓔 σ ⟶ (Γ ∙ σ -Env) 𝓔 ]

lookup `ε ()
lookup (ρ `∙ s) ze    = s
lookup (ρ `∙ s) (su n)  = lookup ρ n
\end{code}

\paragraph{The Preorder of Renamings}\label{preorder}
A key instance of environments playing a predominant role in this paper
is the notion of renaming. The reader may be accustomed to the more
restrictive notion of context inclusions as described by Order Preserving
Embeddings~\cite{altenkirch1995categorical}. Writing non-injective or
non-order preserving renamings would take perverse effort given that we
only implement generic interpretations. In practice, the only combinators
we use do guarantee that all the renamings we generate are context inclusions.
As a consequence, we will use the two expressions interchangeably from now
on.

\todo{Rename context inclusion to thinning}

A context inclusion \AB{Γ} \AF{⊆} \AB{Δ} is an environment pairing each
variable of type \AB{σ} in \AB{Γ} to one of the same type in \AB{Δ}.

\AgdaHide{
\begin{code}

infix 5 _⊆_
\end{code}}
\begin{code}
_⊆_ : (Γ Δ : Cx) → Set
Γ ⊆ Δ = (Γ -Env) Var Δ
\end{code}

Context inclusions allow for the formulation of weakening principles
explaining how to transport properties along inclusions. By a ``weakening
principle'', we mean that if \AB{P} holds of \AB{Γ} and \AB{Γ} \AF{⊆} \AB{Δ}
then \AB{P} holds for \AB{Δ} too.
In the case of variables, weakening merely corresponds to applying the
renaming function in order to obtain a new variable. The environments'
case is also quite simple: being a pointwise lifting of a relation \AB{𝓔}
between contexts and types, they enjoy weakening if \AB{𝓔} does.

\begin{code}
Thinnable : {ℓ^A : Level} → (Cx → Set ℓ^A) → Set ℓ^A
Thinnable S = {Γ Δ : Cx} → Γ ⊆ Δ → (S Γ → S Δ)

wk^∈ : (σ : Ty) → Thinnable (Var σ)
wk^∈ σ inc v = lookup inc v

wk[_] :  {ℓ^A : Level} {𝓔 : Model ℓ^A} → ((σ : Ty) → Thinnable (𝓔 σ)) →
         {Γ : Cx} → Thinnable ((Γ -Env) 𝓔)
lookup (wk[ wk ] inc ρ) = wk _ inc ∘ lookup ρ
\end{code}

These simple observations allow us to prove that context inclusions
form a preorder which, in turn, lets us provide the user with the
constructors Altenkirch, Hofmann and Streicher's ``Category of
(σ : Ty) → Thinnables"~(\cite{altenkirch1995categorical}) is based on.

\todo{Rename trans to select?}
\todo{Expand type step and pop!}

\begin{code}
refl : {Γ : Cx} → Γ ⊆ Γ
refl = pack id

trans : {ℓ^A : Level} {Γ Δ Θ : Cx} {𝓔 : Model ℓ^A} → Γ ⊆ Δ → (Δ -Env) 𝓔 Θ → (Γ -Env) 𝓔 Θ
lookup (trans inc ρ) = lookup ρ ∘ lookup inc

step : {σ : Ty} {Γ : Cx} → [ (Γ ⊆_) ⟶ σ ⊢ (Γ ⊆_) ]
step inc = trans inc (pack su)

pop! : {σ : Ty} {Γ : Cx} → [ (Γ ⊆_) ⟶ σ ⊢ ((Γ ∙ σ) ⊆_) ]
pop! inc = step inc `∙ ze


th^□ : {ℓ^A : Level} {S : Cx → Set ℓ^A} → Thinnable (□ S)
th^□ inc s = s ∘ trans inc
\end{code}

Now that we are equipped with the notion of inclusion, we have all
the pieces necessary to describe the Kripke structure of our models
of the simply typed $λ$-calculus.

\section{Semantics and Generic Evaluation Functions}

The upcoming sections are dedicated to demonstrating that renaming,
substitution, printing with names, and normalisation by evaluation all
share the same structure. We start by abstracting away a notion of
\AR{Semantics} encompassing all these constructions. This approach
will make it possible for us to implement a generic traversal
parametrised by such a \AR{Semantics} once and for all and to focus
on the interesting model constructions instead of repeating the same
pattern over and over again.

A \AR{Semantics} is indexed by two relations \AB{𝓔} and \AB{𝓜}
describing respectively the values in the environment and the ones
in the model. In cases such as substitution or normalisation by
evaluation, \AB{𝓔} and \AB{𝓜} will happen to coincide but keeping
these two relations distinct is precisely what makes it possible
to go beyond these and also model renaming or printing with names.
The record packs the properties of these relations necessary to
define the evaluation function.

\todo{INLINE Applicative}

\begin{code}
Applicative : {ℓ^A : Level} → Model ℓ^A → Set ℓ^A
Applicative 𝓜 = {σ τ : Ty} → [ 𝓜 (σ `→ τ) ⟶ 𝓜 σ ⟶ 𝓜 τ ]

record Semantics {ℓ^E ℓ^M : Level} (𝓔 : Model ℓ^E) (𝓜 : Model ℓ^M) : Set (ℓ^E ⊔ ℓ^M) where
\end{code}
\AgdaHide{
\begin{code}
  infixl 5 _⟦$⟧_
  field
\end{code}}

The first two methods of a \AR{Semantics} are dealing with environment
values. These values need to come with a notion of weakening (\ARF{wk})
so that the traversal may introduce fresh variables when going under a
binder and keep the environment well-scoped. We also need to be able to
manufacture environment values given a variable in scope (\ARF{embed})
in order to be able to craft a diagonal environment to evaluate an open
term.

\begin{code}
    wk      :  (σ : Ty) → Thinnable (𝓔 σ)
    embed   :  {σ : Ty} → [ Var σ ⟶ 𝓔 σ ]
\end{code}

The structure of the model is quite constrained: each constructor
in the language needs a semantic counterpart. We start with the
two most interesting cases: \ARF{⟦var⟧} and \ARF{⟦λ⟧}. The variable
case corresponds to the intuition that the environment attaches
interpretations to the variables in scope: it guarantees that one
can turn a value from the environment into a model one. The traversal
will therefore be able to, when hitting a variable, lookup the
corresponding value in the environment and return it.

\begin{code}
    ⟦var⟧   :  {σ : Ty} → [ 𝓔 σ ⟶ 𝓜 σ ]
\end{code}

The semantic λ-abstraction is notable for two reasons: first, following
Mitchell and Moggi~\cite{mitchell1991kripke}, its structure is typical
of models à la Kripke allowing arbitrary extensions of the context; and
second, instead of being a function in the host language taking values
in the model as arguments, it is a function that takes \emph{environment}
values. Indeed, the body of a λ-abstraction exposes one extra free variable
thus prompting us to extend the evaluation environment with an additional
value. This slight variation in the type of semantic λ-abstraction
guarantees that such an argument will be provided to us.

\AgdaHide{
\begin{code}
  field
\end{code}}
\begin{code}
    ⟦λ⟧     :  {σ τ : Ty} → [ □ (𝓔 σ ⟶ 𝓜 τ) ⟶ 𝓜 (σ `→ τ) ]
\end{code}

The remaining fields' types are a direct translation of the types
of the constructor they correspond to where the type constructor
characterising typing derivations (\AD{\_⊢\_}) has been replaced
with the one corresponding to model values (\AB{𝓜}).

\AgdaHide{
\begin{code}
  field
\end{code}}
\begin{code}
    _⟦$⟧_  :  {σ τ : Ty} →  [ 𝓜 (σ `→ τ) ⟶ 𝓜 σ ⟶   𝓜 τ   ]
    ⟦⟨⟩⟧   :                [                         𝓜 `1  ]
    ⟦tt⟧   :                [                         𝓜 `2  ]
    ⟦ff⟧   :                [                         𝓜 `2  ]
    ⟦if⟧   :  {σ : Ty} →    [ 𝓜 `2 ⟶ 𝓜 σ ⟶ 𝓜 σ ⟶  𝓜 σ   ]
\end{code}

The fundamental lemma of semantics is then proven in a module indexed by
a \AF{Semantics}, which would correspond to using a Section in Coq. It is
defined by structural recursion on the term. Each constructor is replaced
by its semantic counterpart in order to combine the induction hypotheses
for its subterms. In the λ-abstraction case, the type of \ARF{⟦λ⟧} guarantees,
in a fashion reminiscent of Normalisation by Evaluation, that the semantic
argument can be stored in the environment which will have been weakened
beforehand.

\begin{code}
module Eval {ℓ^E ℓ^M : Level} {𝓔 : Model ℓ^E} {𝓜 : Model ℓ^M} (𝓢 : Semantics 𝓔 𝓜) where
  open Semantics 𝓢
\end{code}\vspace{ -2.5em}%ugly but it works!
%<*evaluation>
\begin{code}
  sem : {Γ : Cx} → [ (Γ -Env) 𝓔 ⟶ (Γ -Eval) 𝓜 ]
  sem ρ (`var v)     = ⟦var⟧ (lookup ρ v)
  sem ρ (t `$ u)     = sem ρ t ⟦$⟧ sem ρ u
  sem ρ (`λ b)       = ⟦λ⟧ (λ inc u → sem (wk[ wk ] inc ρ `∙ u) b)
  sem ρ `⟨⟩          = ⟦⟨⟩⟧
  sem ρ `tt          = ⟦tt⟧
  sem ρ `ff          = ⟦ff⟧
  sem ρ (`if b l r)  = ⟦if⟧ (sem ρ b) (sem ρ l) (sem ρ r)
\end{code}
%</evaluation>

We introduce \AF{\_⊨⟦\_⟧\_} as an alternative name for the fundamental
lemma and \AF{\_⊨eval\_} for the special case where we use \ARF{embed}
to generate a diagonal environment of type \AB{Γ} \AF{[} \AB{𝓔} \AF{]}
\AB{Γ}. We open the module \AM{Eval} unapplied thus discharging (λ-lifting)
its members over the \AR{Semantics} parameter. This means that a partial
application of \AF{\_⊨⟦\_⟧\_} will correspond to the specialisation of the
fundamental lemma to a given semantics. \AB{𝓢} \AF{⊨⟦} \AB{t} \AF{⟧} \AB{ρ}
is meant to convey the idea that the semantics \AB{𝓢} is used to evaluate
the term \AB{t} in the environment \AB{ρ}. Similarly, \AB{𝓢} \AF{⊨eval}
\AB{t} is meant to denote the evaluation of the term \AB{t} in the semantics
\AB{𝓢} (using a diagonal environment).

\begin{code}

  lemma′ : {σ : Ty} → [ Tm σ ⟶ 𝓜 σ ]
  lemma′ t = sem (pack embed) t
\end{code}

The diagonal environment generated using \ARF{embed} when defining the
\AF{\_⊨eval\_} function lets us kickstart the evaluation of arbitrary
\emph{open} terms. In the case of printing with names, this corresponds to
picking a naming scheme for free variables whilst in the usual model
construction used to perform normalisation by evaluation, it corresponds
to η-expanding the variables.

\section{Syntax is the Identity Semantics}

As we have explained earlier, this work has been directly influenced by
McBride's manuscript~\cite{mcbride2005type}. It seems appropriate
to start our exploration of \AR{Semantics} with the two operations he
implements as a single traversal. We call these operations syntactic
because the values in the model are actual terms and almost all term
constructors are kept as their own semantic counterpart. As observed by
McBride, it is enough to provide three operations describing the properties
of the values in the environment to get a full-blown \AR{Semantics}. This
fact is witnessed by our simple \AR{Syntactic} record type together with
the \AF{syntactic} function turning its inhabitants into associated
\AR{Semantics}.

%<*syntactic>
\begin{code}
record Syntactic {ℓ^A : Level} (𝓔 : Model ℓ^A) : Set ℓ^A where
  field  embed  : {σ : Ty} → [ Var σ ⟶ 𝓔 σ ]
         wk     : (σ : Ty) → Thinnable (𝓔 σ)
         ⟦var⟧  : {σ : Ty} → [ 𝓔 σ ⟶ Tm σ ]
\end{code}\vspace{ -1.5em}%ugly but it works!
%</syntactic>
\begin{code}
syntactic : {ℓ^A : Level} {𝓔 : Model ℓ^A} (syn : Syntactic 𝓔) → Semantics 𝓔 Tm
syntactic syn = let open Syntactic syn in record
  { wk      = wk; embed   = embed; ⟦var⟧   = ⟦var⟧
  ; ⟦λ⟧     = λ t → `λ (t (step refl) (embed ze))
  ; _⟦$⟧_   = _`$_; ⟦⟨⟩⟧ = `⟨⟩; ⟦tt⟧ = `tt; ⟦ff⟧ = `ff; ⟦if⟧  = `if }
\end{code}

The shape of \ARF{⟦λ⟧} or \ARF{⟦⟨⟩⟧} should not trick the reader
into thinking that this definition performs some sort of η-expansion:
\AF{lemma} indeed only ever uses one of these when the evaluated term's
head constructor is already respectively a \AIC{`λ} or a \AIC{`⟨⟩}.
It is therefore absolutely possible to define renaming or substitution
using this approach. We can now port McBride's definitions to our
framework.

\paragraph{Functoriality, also known as Renaming}
Our first example of a \AR{Syntactic} operation works with variables as
environment values. As a consequence, embedding is trivial; we have already
defined weakening earlier (see Section \ref{preorder}) and we can turn
a variable into a term by using the \AIC{`var} constructor.

\begin{code}
syntacticRenaming : Syntactic Var
syntacticRenaming = record { embed = id; wk = wk^∈; ⟦var⟧ = `var }
\end{code}
\AgdaHide{
\begin{code}
Renaming : Semantics Var Tm; Renaming = syntactic syntacticRenaming
\end{code}}

We obtain a rather involved definition of the identity of type \AB{Γ}
\AD{⊢} \AB{σ} \AS{→} \AB{Γ} \AD{⊢} \AB{σ} as \AF{Renaming} \AF{⊨eval\_}.
But this construction is not at all useless: indeed, the more general
\AF{Renaming} \AF{⊨⟦\_⟧\_} function has type \AB{Γ} \AD{⊢} \AB{σ} \AS{→}
\AB{Γ} \AF{⊆} \AB{Δ} \AS{→} \AB{Δ} \AD{⊢} \AB{σ} which turns out to be
precisely the notion of weakening for terms we need once its arguments
have been flipped.

\begin{code}
wk^⊢ : (σ : Ty) → Thinnable (Tm σ)
wk^⊢ σ ρ t = let open Eval Renaming in sem ρ t
\end{code}

\paragraph{Simultaneous Substitution}
Our second example of a semantics is another spin on the syntactic model:
the environment values are now terms. We can embed variables into environment
values by using the \AIC{`var} constructor and we inherit weakening for terms
from the previous example.

\begin{code}
syntacticSubstitution : Syntactic Tm
syntacticSubstitution = record { embed = `var; wk = wk^⊢; ⟦var⟧ = id }
\end{code}

\AgdaHide{
\begin{code}
Substitution : Semantics Tm Tm; Substitution = syntactic syntacticSubstitution
\end{code}}

Because the diagonal environment used by \AF{Substitution} \AF{⊨eval\_}
is obtained by \ARF{embed}ding membership proofs into terms using the
\AIC{`var} constructor, we get yet another definition of the identity
function on terms. The semantic function \AF{Substitution} \AF{⊨⟦\_⟧\_}
is once again more interesting: it is an implementation of simultaneous
substitution.

\begin{code}
subst : {Γ Δ : Cx} {σ : Ty} (t : Tm σ Γ) (ρ : (Γ -Env) Tm Δ) → Tm σ Δ
subst t ρ = let open Eval Substitution in sem ρ t
\end{code}

\section{Printing with Names}
\label{prettyprint}

Before considering the various model constructions involved in defining
normalisation functions deciding different equational theories, let us
make a detour to a perhaps slightly more surprising example of a
\AF{Semantics}: printing with names. A user-facing project would naturally
avoid directly building a \AD{String} and rather construct an inhabitant of
a more sophisticated datatype in order to generate a prettier output~\cite{hughes1995design,wadler2003prettier}.
But we stick to the simpler setup as pretty printing is not our focus here.


This example is quite interesting for two reasons. Firstly, the distinction
between the type of values in the environment and the ones in the model is
once more instrumental in giving the procedure a precise type guiding our
implementation. Indeed, the environment carries \emph{names} for the variables
currently in scope whilst the inhabitants of the model are \emph{computations}
threading a stream to be used as a source of fresh names every time a new variable
is introduced by a λ-abstraction. If the values in the environment were allowed
to be computations too, we would not root out all faulty implementations: the
typechecker would for instance quite happily accept a program picking a new
name every time a variable appears in the term.

\AgdaHide{
\begin{code}
open import Data.Char using (Char)
open import Data.String hiding (show)
open import Data.Nat.Show
open import Data.List as List hiding (_++_ ; zipWith ; [_])
open import Coinduction
open import Data.Stream as Stream using (Stream ; head ; tail ; zipWith ; _∷_)
open import Category.Monad
open import Category.Monad.State
open RawIMonadState (StateMonadState (Stream String)) hiding (zipWith ; pure)
open import Relation.Binary.PropositionalEquality as PEq using (_≡_)
\end{code}
}

\begin{code}
record Name (σ : Ty) (Γ : Cx) : Set where
  constructor mkN
  field getN : String

record Printer (σ : Ty) (Γ : Cx) : Set where
  constructor mkP
  field runP : State (Stream String) String
\end{code}
\AgdaHide{
\begin{code}
open Name
open Printer
\end{code}}

Secondly, the fact that values in the model are computations and that this
poses no problem whatsoever in this framework means it is appropriate for
handling languages with effects~\cite{moggi1991notions}, or effectful
semantics e.g. logging the various function calls. Here is the full definition
of the printer assuming the existence of \AF{formatλ}, \AF{format\$}, and
\AF{formatIf} picking a way to display these constructors.

\AgdaHide{
\begin{code}
formatλ : String → String → String
formatλ x b = "λ" ++ x ++ ". " ++ b

format$ : String → String → String
format$ f t = f ++ " (" ++ t ++ ")"

formatIf : String → String → String → String
formatIf b l r = "if (" ++ b  ++ ") then (" ++ l ++ ") else (" ++ r ++ ")"
\end{code}}
\begin{code}
Printing : Semantics Name Printer
Printing = record
  { embed   = mkN ∘ show ∘ deBruijn
  ; wk      = λ _ _ → mkN ∘ getN
  ; ⟦var⟧   = mkP ∘ return ∘ getN
  ; _⟦$⟧_   =  λ mf mt → mkP (
               format$ <$> runP mf ⊛ runP mt)
  ; ⟦λ⟧     =  λ {_} {σ} mb → mkP (
       get >>= λ ns → let x′ = head ns in
       put (tail ns)                               >>= λ _ →
       runP (mb (step {σ = σ} refl) (mkN x′))  >>= λ b′ →
       return (formatλ x′ b′))
  ; ⟦⟨⟩⟧    = mkP (return "⟨⟩")
  ; ⟦tt⟧    = mkP (return "tt")
  ; ⟦ff⟧    = mkP (return "ff")
  ; ⟦if⟧  =  λ mb ml mr → mkP (
       formatIf  <$> runP mb ⊛ runP ml ⊛ runP mr) }
\end{code}

Our definition of \ARF{embed} erases the membership proofs to
recover the corresponding de Bruijn indices which are then turned
into strings using \AF{show}, defined in Agda's standard library.
This means that, using \AF{Printing} \AF{⊨eval\_}, the free
variables will be displayed as numbers whilst the bound ones will
be given names taken from the name supply. This is quite clearly
a rather crude name generation strategy and our approach to naming
would naturally be more sophisticated in a user-facing language.
We can for instance imagine that the binders arising from a user
input would carry naming hints based on the name the user picked
and that binders manufactured by the machine would be following
a type-based scheme: functions would be \AB{f}s or \AB{g}s, natural
numbers \AB{m}s, \AB{n}s, etc.

\begin{code}
  where
    deBruijn : {Γ : Cx} {σ : Ty} → Var σ Γ → ℕ
    deBruijn ze    = 0
    deBruijn (su n)  = 1 + deBruijn n
\end{code}

We still need to provide a \AD{Stream} of fresh
names to this computation in order to run it. Given that \ARF{embed} erases
free variables to numbers, we'd rather avoid using numbers if we want to
avoid capture. We define \AF{names} (not shown here) as the stream
cycling through the letters of the alphabet and keeping the identifiers
unique by appending a natural number incremented by 1 each time we are
back to the beginning of the cycle.

\AgdaHide{
\begin{code}
flatten : {A : Set} → Stream (A × List A) → Stream A
flatten ((a , as) ∷ aass) = go a as (♭ aass) where
  go : {A : Set} → A → List A → Stream (A × List A) → Stream A
  go a []        aass = a ∷ ♯ flatten aass
  go a (b ∷ as)  aass = a ∷ ♯ go b as aass
names : Stream String
names = flatten (zipWith cons letters ("" ∷ ♯ Stream.map show (allNatsFrom 0)))
  where
    cons : (Char × List Char) → String → (String × List String)
    cons (c , cs) suffix = appendSuffix c , map appendSuffix cs where
      appendSuffix : Char → String
      appendSuffix c  = fromList (c ∷ []) ++ suffix

    letters = Stream.repeat ('a' , toList "bcdefghijklmnopqrstuvwxyz")
    
    allNatsFrom : ℕ → Stream ℕ
    allNatsFrom k = k ∷ ♯ allNatsFrom (1 + k)
\end{code}}

Before defining \AF{print}, we introduce \AF{init} (implementation
omitted here) which is a function delivering a stateful computation using
the provided stream of fresh names to generate an environment of names
for a given context. This means that we are now able to define a printing
function using names rather than numbers for the variables appearing free
in a term.

\AgdaHide{
\begin{code}
nameContext : ∀ Δ Γ → State (Stream String) ((Γ -Env) Name Δ)
nameContext Δ ε        =  return `ε
nameContext Δ (Γ ∙ σ)  =  nameContext Δ Γ >>= λ g →
                          get >>= λ names → put (tail names) >>
                          return (g `∙ mkN (head names))
\end{code}}
\begin{code}
init : ∀ Γ → State (Stream String) ((Γ -Env) Name Γ)
\end{code}
\AgdaHide{
\begin{code}
init Γ = nameContext Γ Γ
\end{code}}\vspace{ -2em}%ugly but it works!
\begin{code}
print : {Γ : Cx} {σ : Ty} → Tm σ Γ → String
print {Γ} t = proj₁ (  (init Γ >>= λ ρ →
                       runP (sem ρ t)) names)
  where open Eval Printing
\end{code}

We can observe \AF{print}'s behaviour by writing a test.
If we state this test as a propositional equality and prove it using \AIC{refl},
the typechecker will have to check that both expressions indeed compute
to the same value. Here we display a term corresponding to the η-expansion
of the first free variable in the context \AIC{ε} \AIC{∙} (\AB{σ} \AIC{`→} \AB{τ}).
As we can see, it receives the name \AStr{"a"} whilst the binder introduced by
the η-expansion is called \AStr{"b"}.

\begin{code}
pretty$ : {σ τ : Ty} → print {Γ = ε ∙ σ `→ τ} (`λ (`var (su ze) `$ `var ze)) ≡ "λb. a (b)"
pretty$ = PEq.refl
\end{code}

\section{Normalisation by Evaluation}

\todo{This section should take one page only}

Normalisation by Evaluation is a technique exploiting the computational
power of a host language in order to normalise expressions of a deeply
embedded one. The process is based on a model construction describing a
family of types \AB{𝓜} indexed by a context \AB{Γ} and a type \AB{σ}. Two
procedures are then defined: the first one (\AF{eval}) constructs an element
of \AB{𝓜} \AB{Γ} \AB{σ} provided a well typed term of the corresponding
\AB{Γ} \AD{⊢} \AB{σ} type whilst the second one (\AF{reify}) extracts, in
a type-directed manner, normal forms \AB{Γ} \AD{⊢^{nf}} \AB{σ} from elements
of the model \AB{𝓜} \AB{Γ} \AB{σ}. Normalisation is achieved by composing
the two procedures. The definition of this \AF{eval} function is a natural
candidate for our \AF{Semantics} framework. Normalisation is always defined
for a given equational theory so we are going to start by recalling the
various rules a theory may satisfy.

Thanks to \AF{Renaming} and \AF{Substitution} respectively, we can formally
define η-expansion and β-reduction. The η-rules are saying that for some types,
terms have a canonical form: functions will all be λ-headed whilst record will
be a collection of fields which translates here to all the elements of the
\AIC{`1} type being equal to \AIC{`⟨⟩}.

\AgdaHide{
\begin{code}
infixl 10 _⟨_/var₀⟩
\end{code}}
\begin{code}
eta : (σ τ : Ty) → [ Tm (σ `→ τ) ⟶ Tm (σ `→ τ) ]
eta σ τ t = `λ (wk^⊢ (σ `→ τ) (step refl) t `$ `var ze)
\end{code}

\begin{mathpar}
\inferrule{
  }{\text{\AB{t} ↝ \AF{eta} \AB{t}}
  }{η_1}
\and \inferrule{\text{\AB{t} \AgdaSymbol{:} \AB{Γ} \AD{⊢} \AIC{`1}}
  }{\text{\AB{t} ↝ \AIC{`⟨⟩}}
  }{η_2}
\end{mathpar}

\begin{code}
_⟨_/var₀⟩ : {σ τ : Ty} → [ σ ⊢ Tm τ ⟶ Tm σ ⟶ Tm τ ] 
t ⟨ u /var₀⟩ = subst t (pack `var `∙ u)
\end{code}

\begin{mathpar}
\inferrule{
  }{\text{(\AIC{`λ} \AB{t}) \AIC{`\$} \AB{u} ↝ \AB{t} \AF{⟨} \AB{u} \AF{/var₀⟩}}
  }{β}
\end{mathpar}

The β-rule is the main driving force when it comes to actually computing
but the presence of an inductive data type (\AIC{`2}) and its eliminator
(\AIC{`if}) means we have an extra opportunity for redexes: whenever the
boolean the eliminator is branching over is in canonical form, we may apply
a ι-rule. Finally, the ξ-rule is the one making it possible to reduce under
λ-abstractions which is the distinction between weak-head normalisation and
strong normalisation.
\begin{mathpar}
\inferrule{
  }{\text{\AIC{`if} \AIC{`tt} \AB{l} \AB{r} ↝ \AB{l}}
  }{ι_1}
\and
\inferrule{
  }{\text{\AIC{`if} \AIC{`ff} \AB{l} \AB{r} ↝ \AB{r}}
  }{ι_2}
\and
\inferrule{\text{\AB{t} ↝ \AB{u}}
  }{\text{\AIC{`λ} \AB{t} ↝ \AIC{`λ} \AB{u}}
  }{ξ}
\end{mathpar}

Now that we have recalled all these rules, we can talk precisely
about the sort of equational theory decided by the model construction
we choose to perform. We start with the usual definition of Normalisation
by Evaluation which goes under λs and produces η-long βι-short normal
forms.

\subsection{Normalisation by Evaluation for βιξη}
\label{normbye}

In the case of Normalisation by Evaluation, the elements of the model
and the ones carried by the environment will both have the same type:
\AF{\_⊨^{βιξη}\_}, defined by induction on its second argument. In
order to formally describe this construction, we need to have a precise
notion of normal forms. Indeed if the η-rules guarantee that we can
represent functions (respectively inhabitants of \AIC{`1}) in the
source language as function spaces (respectively \AR{⊤}) in Agda, there
are no such rules for \AIC{`2}ean values which will be represented
as normal forms of the right type i.e. as either \AIC{`tt}, \AIC{`ff}
or a neutral expression.

These normal forms can be formally described by two mutually defined
inductive families: \AD{\_⊢[\_]^{ne}\_} is the type of stuck terms made
up of a variable to which a spine of eliminators in normal forms is
applied; and \AD{\_⊢[\_]^{nf}\_} describes the normal forms. These
families are parametrised by a predicate \AB{R} characterising the
types at which the user is allowed to turn a neutral expression into a
normal form as demonstrated by the constructor \AIC{`ne}'s first argument.

\begin{code}
module NormalForms (R : Ty → Set) where

  mutual

    data Ne : Model L.zero  where
      `var   : {σ : Ty} → [ Var σ ⟶ Ne σ ]
      _`$_   : {σ τ : Ty} → [ Ne (σ `→ τ) ⟶ Nf σ ⟶ Ne τ ]
      `if  : {σ : Ty} → [ Ne `2 ⟶ Nf σ ⟶ Nf σ ⟶ Ne σ ]

    data Nf : Model L.zero where
      `ne  : {σ : Ty} → R σ → [ Ne σ ⟶ Nf σ ]
      `⟨⟩     : [ Nf `1 ]
      `tt     : [ Nf `2 ]
      `ff     : [ Nf `2 ]
      `λ      : {σ τ : Ty} → [ σ ⊢ Nf τ ⟶ Nf (σ `→ τ) ]
\end{code}

Once more, context inclusions induce the expected notions of weakening \AF{wk^{ne}}
and \AF{wk^{nf}}. We omit their purely structural implementation here and would
thoroughly enjoy doing so in the source file too: our constructions so far have
been syntax-directed and could hopefully be leveraged by a generic account of syntaxes
with binding.

\AgdaHide{
\begin{code}
  wk^ne : (σ : Ty) → Thinnable (Ne σ)
  wk^nf : (σ : Ty) → Thinnable (Nf σ)
  wk^ne σ inc (`var v)        = `var (wk^∈ σ inc v)
  wk^ne σ inc (ne `$ u)       = wk^ne _ inc ne `$ wk^nf _ inc u
  wk^ne σ inc (`if ne l r)  = `if (wk^ne `2 inc ne) (wk^nf σ inc l) (wk^nf σ inc r)

  wk^nf σ         inc (`ne pr t) = `ne pr (wk^ne σ inc t)
  wk^nf `1     inc `⟨⟩           = `⟨⟩
  wk^nf `2     inc `tt           = `tt
  wk^nf `2     inc `ff           = `ff
  wk^nf (σ `→ τ)  inc (`λ nf)       = `λ (wk^nf τ (pop! inc) nf)

  infix 5 [_,,_]
  [_,,_] : {ℓ^A : Level} {Γ : Cx} {τ : Ty} {P : (σ : Ty) (pr : Var σ (Γ ∙ τ)) → Set ℓ^A} →
          (p0 : P τ ze) →
          (pS : (σ : Ty) (n : Var σ Γ) → P σ (su n)) →
          (σ : Ty) (pr : Var σ (Γ ∙ τ)) → P σ pr
  [ p0 ,, pS ] σ ze    = p0
  [ p0 ,, pS ] σ (su n)  = pS σ n

  mutual

    wk^nf-refl′ : {Γ : Cx} {σ : Ty} {f : Γ ⊆ Γ}
                  (prf : (σ : Ty) (pr : Var σ Γ) → lookup f pr ≡ pr) →
                  (t : Nf σ Γ) → wk^nf σ f t ≡ t
    wk^nf-refl′ prf (`ne pr t)  = PEq.cong (`ne pr) (wk^ne-refl′ prf t)
    wk^nf-refl′ prf `⟨⟩            = PEq.refl
    wk^nf-refl′ prf `tt            = PEq.refl
    wk^nf-refl′ prf `ff            = PEq.refl
    wk^nf-refl′ prf (`λ t)         = PEq.cong `λ (wk^nf-refl′ ([ PEq.refl ,, (λ σ → PEq.cong su ∘ prf σ) ]) t)

    wk^ne-refl′ : {Γ : Cx} {σ : Ty} {f : Γ ⊆ Γ}
                  (prf : (σ : Ty) (pr : Var σ Γ) → lookup f pr ≡ pr) →
                  (t : Ne σ Γ) → wk^ne σ f t ≡ t
    wk^ne-refl′ prf (`var v)       = PEq.cong `var (prf _ v)
    wk^ne-refl′ prf (t `$ u)       = PEq.cong₂ _`$_ (wk^ne-refl′ prf t) (wk^nf-refl′ prf u)
    wk^ne-refl′ prf (`if b l r)  = PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ (wk^ne-refl′ prf b) (wk^nf-refl′ prf l)) (wk^nf-refl′ prf r)

  mutual

    wk^nf-trans′ : {Θ Δ Γ : Cx} {σ : Ty} {inc₁ : Γ ⊆ Δ} {inc₂ : Δ ⊆ Θ}
                   {f : Γ ⊆ Θ} (prf : (σ : Ty) (pr : Var σ Γ) → lookup (trans inc₁ inc₂) pr ≡ lookup f pr)
                   (t : Nf σ Γ) →  wk^nf σ inc₂ (wk^nf σ inc₁ t) ≡ wk^nf σ f t
    wk^nf-trans′ prf (`ne pr t)  = PEq.cong (`ne pr) (wk^ne-trans′ prf t)
    wk^nf-trans′ prf `⟨⟩            = PEq.refl 
    wk^nf-trans′ prf `tt            = PEq.refl
    wk^nf-trans′ prf `ff            = PEq.refl
    wk^nf-trans′ prf (`λ t)         = PEq.cong `λ (wk^nf-trans′ ([ PEq.refl ,, (λ σ → PEq.cong su ∘ prf σ) ]) t)

    wk^ne-trans′ : {Θ Δ Γ : Cx} {σ : Ty} {inc₁ : Γ ⊆ Δ} {inc₂ : Δ ⊆ Θ}
                   {f : Γ ⊆ Θ} (prf : (σ : Ty) (pr : Var σ Γ) → lookup (trans inc₁ inc₂) pr ≡ lookup f pr)
                   (t : Ne σ Γ) →  wk^ne σ inc₂ (wk^ne σ inc₁ t) ≡ wk^ne σ f t
    wk^ne-trans′ prf (`var v)       = PEq.cong `var (prf _ v)
    wk^ne-trans′ prf (t `$ u)       = PEq.cong₂ _`$_ (wk^ne-trans′ prf t) (wk^nf-trans′ prf u)
    wk^ne-trans′ prf (`if b l r)  = PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ (wk^ne-trans′ prf b) (wk^nf-trans′ prf l)) (wk^nf-trans′ prf r)

  wk^nf-refl : {Γ : Cx} {σ : Ty} (t : Nf σ Γ) → wk^nf σ refl t ≡ t
  wk^nf-refl = wk^nf-refl′ (λ _ _ → PEq.refl)

  wk^ne-refl : {Γ : Cx} {σ : Ty} (t : Ne σ Γ) → wk^ne σ refl t ≡ t
  wk^ne-refl = wk^ne-refl′ (λ _ _ → PEq.refl)

  wk^nf-trans : {Θ Δ Γ : Cx} {σ : Ty} (inc₁ : Γ ⊆ Δ) (inc₂ : Δ ⊆ Θ)
               (t : Nf σ Γ) →  wk^nf σ inc₂ (wk^nf σ inc₁ t) ≡ wk^nf σ (trans inc₁ inc₂) t
  wk^nf-trans inc₁ inc₂ = wk^nf-trans′ (λ _ _ → PEq.refl)

  wk^ne-trans : {Θ Δ Γ : Cx} {σ : Ty} (inc₁ : Γ ⊆ Δ) (inc₂ : Δ ⊆ Θ)
               (t : Ne σ Γ) →  wk^ne σ inc₂ (wk^ne σ inc₁ t) ≡ wk^ne σ (trans inc₁ inc₂) t
  wk^ne-trans inc₁ inc₂ = wk^ne-trans′ (λ _ _ → PEq.refl)
\end{code}}

We now come to the definition of the model. We introduce the predicate
\AF{R^{βιξη}} characterising the types for which we may turn a neutral
expression into a normal form. It is equivalent to the unit type \AR{⊤}
for \AIC{`2} and to the empty type \AD{⊥} otherwise. This effectively
guarantees that we use the η-rules eagerly: all inhabitants of
\AB{Γ} \AF{⊢[} \AF{R^{βιξη}} \AF{]^{nf}} \AIC{`1} and
\AB{Γ} \AF{⊢[} \AF{R^{βιξη}} \AF{]^{nf}} (\AB{σ} \AIC{`→} \AB{τ}) are
equal to \AIC{`⟨⟩} and a \AIC{`λ}-headed term respectively.

The model construction then follows the usual pattern pioneered by
Berger~\cite{berger1993program} and formally analysed and thoroughly
explained by Catarina Coquand~\cite{coquand2002formalised} in the case
of a simply typed lambda calculus with explicit substitutions. We proceed by
induction on the type and make sure that η-expansion is applied eagerly: all
inhabitants of \AB{Γ} \AF{⊨^{βιξη}} \AIC{`1} are indeed equal and all elements
of \AB{Γ} \AF{⊨^{βιξη}} (\AB{σ} \AIC{`→} \AB{τ}) are functions in Agda.

\begin{code}
module βιξη where

  R : Ty → Set
  R `2  = ⊤
  R _      = ⊥

  open NormalForms R public
\end{code}

%<*sem>
\begin{code}
  Kr : Model _
  Kr `1     = const ⊤
  Kr `2     = Nf `2
  Kr (σ `→ τ)  = □ (Kr σ ⟶ Kr τ)
\end{code}
%</sem>

Normal forms may be weakened, and context inclusions may be composed hence
the rather simple definition of weakening for inhabitants of the model.

\begin{code}
  wk^Kr : (σ : Ty) → Thinnable (Kr σ)
  wk^Kr `1        = const id
  wk^Kr `2        = wk^nf `2
  wk^Kr (σ `→ τ)  = th^□
\end{code}

The semantic counterpart of application combines two elements of the model:
a functional part of type \AB{Γ} \AF{⊨^{βιξη}} \AS{(}\AB{σ} \AIC{`→} \AB{τ}\AS{)}
and its argument of type \AB{Γ} \AF{⊨^{βιξη}} \AB{σ} which can be fed to the
functional given a proof that \AB{Γ} \AF{⊆} \AB{Γ}. But we already have
proven that \AF{\_⊆\_} is a preorder (see Section ~\ref{preorder}) so this
is not at all an issue.

\AgdaHide{
\begin{code}
  infixr 5 _$$_
\end{code}}
\begin{code}
  _$$_ : Applicative Kr
  t $$ u = t refl u
\end{code}

Conditional Branching on the other hand is a bit more subtle: because the boolean
value \AIC{`if} is branching over may be a neutral term, we are forced to define
the reflection and reification mechanisms first. These functions, also known as
unquote and quote respectively, are showing the interplay between neutral terms,
model values and normal forms. \AF{reflect^{βιξη}} performs a form of semantical
η-expansion: all stuck \AIC{`1} terms have the same image and all stuck functions
are turned into functions in the host language.

\AgdaHide{
\begin{code}
  mutual
\end{code}}
\begin{code}
    var‿0 : (σ : Ty) → [ σ ⊢ Kr σ ]
    var‿0 σ = reflect σ (`var ze)

    reflect : (σ : Ty) → [ Ne σ ⟶ Kr σ ]
    reflect `1     t = ⟨⟩
    reflect `2     t = `ne _ t
    reflect (σ `→ τ)  t = λ inc u → reflect τ (wk^ne (σ `→ τ) inc t `$ reify σ u)

    reify : (σ : Ty) → [ Kr σ ⟶ Nf σ ]
    reify `1     T = `⟨⟩
    reify `2     T = T
    reify (σ `→ τ)  T = `λ (reify τ (T (step refl) (var‿0 σ)))
\end{code}

The semantic counterpart of \AIC{`if} can then be defined: if the boolean
is a value, the appropriate branch is picked; if it is stuck the whole expression
is reflected in the model.

\begin{code}
  if : {σ : Ty} → [ Kr `2 ⟶ Kr σ ⟶ Kr σ ⟶ Kr σ ]
  if `tt           l r = l
  if `ff           l r = r
  if {σ} (`ne _ T)  l r = reflect σ (`if T (reify σ l) (reify σ r))
\end{code}

The \AF{Semantics} corresponding to Normalisation by Evaluation for βιξη-rules
uses \AF{\_⊨^{βιξη}\_} for values in the environment as well as the ones in the
model. The semantic counterpart of a λ-abstraction is simply the identity: the
structure of the functional case in the definition of the model matches precisely
the shape expected in a \AF{Semantics}. Because the environment carries model values,
the variable case is trivial.

\begin{code}
  Normalise : Semantics Kr Kr
  Normalise = record
    { embed = reflect _ ∘ `var; wk = wk^Kr; ⟦var⟧ = id
    ; _⟦$⟧_ = λ {σ} {τ} → _$$_ {σ} {τ} ; ⟦λ⟧ = id
    ; ⟦⟨⟩⟧ = ⟨⟩; ⟦tt⟧ = `tt; ⟦ff⟧ = `ff; ⟦if⟧  = λ {σ} → if {σ} }
\end{code}

The diagonal environment built up in \AF{Normalise^{βιξη}} \AF{⊨eval\_}
consists of η-expanded variables. Normalisation is obtained by reifying
the result of evaluation.

\begin{code}
  norm : (σ : Ty) → [ Tm σ ⟶ Nf σ ]
  norm σ t = let open Eval Normalise in reify σ (lemma′ t)
\end{code}

\subsection{Normalisation by Evaluation for βιξ}

As we have just seen, the traditional typed model construction leads to a
normalisation procedure outputting βι-normal η-long terms. However evaluation
strategies implemented in actual proof systems tend to avoid applying η-rules
as much as possible: unsurprisingly, it is a rather bad idea to η-expand proof
terms which are already large when typechecking complex developments. Garillot\todo{not true, fix up: normalise and compare\cite{coquand1991algorithm}}
and colleagues~\cite{garillot2009packaging} report that common mathematical
structures packaged in records can lead to terms of such a size that theorem
proving becomes impractical.

In these systems, normal forms are neither η-long nor η-short: the η-rule is
actually never considered except when comparing two terms for equality, one of
which is neutral whilst the other is constructor-headed. Instead of declaring
them distinct, the algorithm will perform one step of η-expansion on the
neutral term and compare their subterms structurally. The conversion test
will only fail when confronted with two neutral terms with distinct head
variables or two normal forms with different head constructors.

To reproduce this behaviour, the normalisation procedure needs to be amended.
It is possible to alter the model definition described earlier so that it
avoids unnecessary η-expansions. We proceed by enriching the traditional
model with extra syntactical artefacts in a manner reminiscent of Coquand
and Dybjer's approach to defining a Normalisation by Evaluation procedure
for the SK combinator calculus~\cite{CoqDybSK}. Their resorting to glueing
terms to elements of the model was dictated by the sheer impossibily to write
a sensible reification procedure but, in hindsight, it provides us with a
powerful technique to build models internalizing alternative equational
theories. This leads us to mutually defining the model (\AF{\_⊨^{βιξ}\_})
together with the \emph{acting} model (\AF{\_⊨^{βιξ⋆}\_}):

\begin{code}
module βιξ where

  R : Ty → Set
  R = const ⊤
  
  open NormalForms R public

  mutual

    Kr : Model _
    Kr σ = Ne σ ∙⊎ Go σ

    Go : Model _
    Go `1        = const ⊤
    Go `2        = const Bool
    Go (σ `→ τ)  = □ (Kr σ ⟶ Kr τ)
\end{code}

These mutual definitions allow us to make a careful distinction between values
arising from (non expanded) stuck terms and the ones wich are constructor headed
and have a computational behaviour associated to them. The values in the acting
model are storing these behaviours be it either actual proofs of \AF{⊤}, actual
\AF{2}eans or actual Agda functions depending on the type of the term. It is
important to note that the functions in the acting model have the model as both
domain and codomain: there is no reason to exclude the fact that both the argument
or the body may or may not be stuck.


\todo{drop the following}
(σ : Ty) → Thinnable for these structures is rather straightforward
albeit slightly more complex than for the usual definition of Normalisation
by Evaluation seen in Section ~\ref{normbye}.

\begin{code}
  wk^Go : (σ : Ty) → Thinnable (Go σ)
  wk^Go `1        = const id
  wk^Go `2        = const id
  wk^Go (σ `→ τ)  = th^□

  wk^Kr : (σ : Ty) → Thinnable (Kr σ)
  wk^Kr σ inc (inj₁ ne)  = inj₁ (wk^ne σ inc ne)
  wk^Kr σ inc (inj₂ T)   = inj₂ (wk^Go σ inc T)
\end{code}

What used to be called reflection in the previous model is now trivial:
stuck terms are indeed perfectly valid model values. Reification becomes
quite straightforward too because no η-expansion is needed. When facing
a stuck term, we simply embed it in the set of normal forms. Even though
\AF{reify^{βιξ⋆}} may look like it is performing some η-expansions, it
is not the case: all the values in the acting model are notionally obtained
from constructor-headed terms.

\begin{code}
  reflect : (σ : Ty) → [ Ne σ ⟶ Kr σ ]
  reflect σ = inj₁

  reify   : (σ : Ty) → [ Kr σ ⟶ Nf σ ]
  reify⋆  : (σ : Ty) → [ Go σ ⟶ Nf σ ]

  reify σ (inj₁ ne)  = `ne _ ne
  reify σ (inj₂ T)   = reify⋆ σ T

  reify⋆ `1     T = `⟨⟩
  reify⋆ `2     T = if T then `tt else `ff
  reify⋆ (σ `→ τ)  T = `λ (reify τ (T (step refl) var‿0))
    where var‿0 = inj₁ (`var ze)

\end{code}

Semantic application is slightly more interesting: we have to dispatch
depending on whether the function is a stuck term or not. In case it is,
we can reify its argument and grow the spine of the stuck term. Otherwise
we have an Agda function ready to be applied. We proceed similarly for
the definition of the semantical ``if then else''.

\begin{code}
  _$$_ : Applicative Kr
  (inj₁ ne)  $$ u = inj₁ (ne `$ reify _ u)
  (inj₂ F)   $$ u = F refl u

  if : {σ : Ty} → [ Kr `2 ⟶ Kr σ ⟶ Kr σ ⟶ Kr σ ]
  if (inj₁ ne) l r = inj₁ (`if ne (reify _ l) (reify _ r))
  if (inj₂ T)  l r = if T then l else r
\end{code}

Finally, we have all the necessary components to show that evaluating
the term whilst not η-expanding all stuck terms is a perfectly valid
\AR{Semantics}. As usual, normalisation is defined by composing
reification and evaluation on the diagonal environment.

\begin{code}
  Normalise : Semantics Kr Kr
  Normalise = record
    { embed = reflect _ ∘ `var; wk = wk^Kr; ⟦var⟧   = id
    ; _⟦$⟧_ = _$$_; ⟦λ⟧ = inj₂
    ; ⟦⟨⟩⟧ = inj₂ ⟨⟩; ⟦tt⟧ = inj₂ true; ⟦ff⟧ = inj₂ false; ⟦if⟧  = if }
          
  norm : (σ : Ty) → [ Tm σ ⟶ Nf σ ]
  norm σ t = let open Eval Normalise in reify σ (lemma′ t)
\end{code}

\subsection{Normalisation by Evaluation for βι}

The decision to lazily apply the η-rule can be pushed even further: one may
forgo using the ξ-rule too and simply perform weak-head normalisation. This
leads to pursuing the computation only when absolutely necessary e.g.
when two terms compared for equality have matching head constructors
and one needs to inspect these constructors' arguments to conclude. For
that purpose, we introduce an inductive family describing terms in weak-head
normal forms. Naturally, it is possible to define the corresponding weakenings
\AF{wk^{whne}} and \AF{wk^{whnf}} as well as erasure functions \AF{erase^{whnf}}
and \AF{erase^{whne}} with codomain \AD{\_⊢\_} (we omit their simple definitions here).

\begin{code}
module βι where

  data Whne : Model L.zero where
    `var   : {σ : Ty} → [ Var σ ⟶ Whne σ ]
    _`$_   : {σ τ : Ty} → [ Whne (σ `→ τ) ⟶ Tm σ ⟶ Whne τ ]
    `if  : {σ : Ty} → [ Whne `2 ⟶ Tm σ ⟶ Tm σ ⟶ Whne σ ]

  data Whnf : Model L.zero where
    `ne   : {σ : Ty} → [ Whne σ ⟶ Whnf σ ]
    `⟨⟩      : [ Whnf `1 ]
    `tt `ff  : [ Whnf `2 ]
    `λ       : {σ τ : Ty} → [ σ ⊢ Tm τ ⟶ Whnf (σ `→ τ) ]
\end{code}
\AgdaHide{
\begin{code}
  wk^whne : (σ : Ty) → Thinnable (Whne σ)
  wk^whnf : (σ : Ty) → Thinnable (Whnf σ)
  wk^whne σ inc (`var v)        = `var (wk^∈ σ inc v)
  wk^whne σ inc (ne `$ u)       = wk^whne _ inc ne `$ wk^⊢ _ inc u
  wk^whne σ inc (`if ne l r)  = `if (wk^whne `2 inc ne) (wk^⊢ σ inc l) (wk^⊢ σ inc r)

  wk^whnf σ         inc (`ne t)  = `ne (wk^whne σ inc t)
  wk^whnf `1     inc `⟨⟩         = `⟨⟩
  wk^whnf `2     inc `tt         = `tt
  wk^whnf `2     inc `ff         = `ff
  wk^whnf (σ `→ τ)  inc (`λ b)      = `λ (wk^⊢ τ (pop! inc) b)

  erase^whne : {σ : Ty} → [ Whne σ ⟶ Tm σ ]
  erase^whne (`var v)       = `var v
  erase^whne (t `$ u)       = erase^whne t `$ u
  erase^whne (`if t l r)  = `if (erase^whne t) l r

\end{code}}

The model construction is quite similar to the previous one except
that source terms are now stored in the model too. This means that
from an element of the model, one can pick either the reduced version
of the original term (i.e. a stuck term or the term's computational
content) or the original term itself. We exploit this ability most
notably at reification time where once we have obtained either a
head constructor (respectively a head variable), none of the subterms
need to be evaluated.

\begin{code}
  mutual

    Kr : Model _
    Kr σ  = Tm σ ∙× (Whne σ ∙⊎ Go σ)

    Go : Model _
    Go `1     = const ⊤
    Go `2     = const Bool
    Go (σ `→ τ)  = □ (Kr σ ⟶ Kr τ)
\end{code}

\AgdaHide{
\begin{code}
  wk^Go : (σ : Ty) → Thinnable (Go σ)
  wk^Go `1        inc T = T
  wk^Go `2        inc T = T
  wk^Go (σ `→ τ)  inc T = λ inc′ → T (trans inc inc′)

  wk^Kr : (σ : Ty) → Thinnable (Kr σ)
  wk^Kr σ inc (t , inj₁ ne)  = wk^⊢ σ inc t , inj₁ (wk^whne σ inc ne)
  wk^Kr σ inc (t , inj₂ T)   = wk^⊢ σ inc t , inj₂ (wk^Go σ inc T)

  reflect : (σ : Ty) → [ Whne σ ⟶ Kr σ ]
  reflect σ t = erase^whne t , inj₁ t

  var‿0 : {σ : Ty} → [ σ ⊢ Kr σ ]
  var‿0 = reflect _ (`var ze)

  mutual

    reify⋆ : (σ : Ty) → [ Go σ ⟶ Whnf σ ]
    reify⋆ `1     T = `⟨⟩
    reify⋆ `2     T = if T then `tt else `ff
    reify⋆ (σ `→ τ)  T = `λ (proj₁ (T (step refl) var‿0))

    reify : (σ : Ty) → [ Kr σ ⟶ Whnf σ ]
    reify σ (t , inj₁ ne) = `ne ne
    reify σ (t , inj₂ T)  = reify⋆ σ T
\end{code}}

(σ : Ty) → Thinnable, reflection, and reification can all be defined rather
straightforwardly based on the template provided by the previous
section. The application and conditional branching rules are more
interesting: one important difference with respect to the previous
subsection is that we do not grow the spine of a stuck term using
reified versions of its arguments but rather the corresponding
\emph{source} term thus staying true to the idea that we only head
reduce enough to expose either a constructor or a variable.

\begin{code}
  _$$_ : Applicative Kr
  (t , inj₁ ne)  $$ (u , U) = t `$ u , inj₁ (ne `$ u)
  (t , inj₂ T)   $$ (u , U) = t `$ u , proj₂ (T refl (u , U))

  if : {σ : Ty} → [ Kr `2 ⟶ Kr σ ⟶ Kr σ ⟶ Kr σ ]
  if (b , inj₁ ne)  (l , L) (r , R) = `if b l r , inj₁ (`if ne l r)
  if (b , inj₂ B)   (l , L) (r , R) = `if b l r , (if B then L else R)
\end{code}

We can finally put together all of these semantic counterpart to
obtain a \AR{Semantics} corresponding to weak-head normalisation.
We omit the now self-evident definition of \AF{norm^{βι}} as the
composition of evaluation and reification.

\begin{code}
  Normalise : Semantics Kr Kr
  Normalise = record
    { embed = reflect _ ∘ `var; wk = wk^Kr; ⟦var⟧ = id
    ; _⟦$⟧_ = _$$_; ⟦λ⟧ = λ t → `λ (proj₁ (t (step refl) (reflect _ (`var ze)))) , inj₂ t
   ; ⟦⟨⟩⟧ = `⟨⟩ , inj₂ ⟨⟩; ⟦tt⟧ = `tt  , inj₂ true; ⟦ff⟧ = `ff  , inj₂ false; ⟦if⟧  = if }
\end{code}
\AgdaHide{
\begin{code}
  whnorm : (σ : Ty) → [ Tm σ ⟶ Whnf σ ]
  whnorm σ t = let open Eval Normalise in reify σ (lemma′ t)
\end{code}}

\section{Proving Properties of Semantics}
\label{properties}

Thanks to the introduction of \AF{Semantics}, we have already saved
quite a bit of work by not reimplementing the same traversals over
and over again. But this disciplined approach to building models and
defining the associated evaluation functions can also help us refactor
the process of proving some properties of these semantics.

Instead of using proof scripts as Benton et al.~\cite{benton2012strongly}
do, we describe abstractly the constraints the logical relations~\cite{reynolds1983types}
defined on model (and environment) values have to respect for us to be
able to conclude that the evaluation of a term in related environments
produces related outputs. This gives us a generic proof framework to
state and prove, in one go, properties about all of these semantics.

Our first example of such a framework will stay simple on purpose.
However this does not entail that it is a meaningless exercise: the
result proven here will actually be useful in the following subsections
when considering more complex properties.

\subsection{The Synchronisation Relation}

This first example is basically describing the relational interpretation
of the terms. It should give the reader a good idea of the structure of
this type of setup before we move on to a more complex one. The types
involved might look a bit scary because of the level of generality that
we adopt but the idea is rather simple: two \AR{Semantics} are said to
be \emph{synchronisable} if, when evaluating a term in related environments,
they output related values. The bulk of the work is to make this intuition
formal.

The evidence that two \AR{Semantics} are \AR{Synchronisable} is
packaged in a record. The record is indexed by the two semantics
as well as two relations. The first relation (\AB{𝓔^R})
characterises the elements of the (respective) environment types
which are to be considered synchronised, and the second one (\AB{𝓜^R})
describes what synchronisation means in the model. We can lift
\AB{𝓔^R} in a pointwise manner to talk about entire environments
using the \AF{`∀[\_,\_]} predicate transformer omitted here.

\AgdaHide{
\begin{code}
record `∀[_] {ℓ^A ℓ^B ℓ^R : Level} {𝓔^A : Model ℓ^A} {𝓔^B : Model ℓ^B}
             (𝓔^R : RModel 𝓔^A 𝓔^B ℓ^R)
             {Γ Δ : Cx} (ρ^A : (Γ -Env) 𝓔^A Δ) (ρ^B : (Γ -Env) 𝓔^B Δ) : Set ℓ^R where
  constructor pack^R
  field lookup^R : {σ : Ty} (v : Var σ Γ) → rmodel 𝓔^R (lookup ρ^A v) (lookup ρ^B v)
open `∀[_]
\end{code}}
\begin{code}
record Synchronisable {ℓ^EA ℓ^MA ℓ^EB ℓ^MB ℓ^RE ℓ^RM : Level} {𝓔^A : Model ℓ^EA} {𝓜^A : Model ℓ^MA} {𝓔^B : Model ℓ^EB} {𝓜^B : Model ℓ^MB}
  (𝓢^A : Semantics 𝓔^A 𝓜^A) (𝓢^B : Semantics 𝓔^B 𝓜^B)
  (𝓔^R  : RModel 𝓔^A 𝓔^B ℓ^RE) (𝓜^R  : RModel 𝓜^A 𝓜^B ℓ^RM) : Set (ℓ^RE ⊔ ℓ^RM ⊔ ℓ^EA ⊔ ℓ^EB ⊔ ℓ^MA ⊔ ℓ^MB) where
\end{code}
\AgdaHide{
\begin{code}
  module 𝓢^A = Semantics 𝓢^A
  module 𝓢^B = Semantics 𝓢^B
  field
\end{code}}

The record's fields are describing the structure these relations
need to have. \ARF{𝓔^R‿wk} states that two synchronised environments
can be weakened whilst staying synchronised.

\begin{code}
    𝓔^R‿wk  :  {Γ Δ Θ : Cx} (inc : Δ ⊆ Θ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Γ -Env) 𝓔^B Δ} (ρ^R : `∀[ 𝓔^R ] ρ^A ρ^B) →
               `∀[ 𝓔^R ] (wk[ 𝓢^A.wk ] inc ρ^A) (wk[ 𝓢^B.wk ] inc ρ^B)
\end{code}

We then have the relational counterparts of the term constructors.
To lighten the presentation, we will focus on the most interesting
ones and give only one example quite characteristic of the remaining
ones. Our first interesting case is the relational counterpart of
\AIC{`var}: it states that given two synchronised environments, we
indeed get synchronised values in the model by applying \ARF{⟦var⟧}
to the looked up values.

\begin{code}
    R⟦var⟧    :  {Γ Δ : Cx} {σ : Ty} (v : Var σ Γ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Γ -Env) 𝓔^B Δ} (ρ^R : `∀[ 𝓔^R ] ρ^A ρ^B) →
                 rmodel 𝓜^R (𝓢^A.⟦var⟧ (lookup ρ^A v)) (𝓢^B.⟦var⟧ (lookup ρ^B v))
\end{code}

The second, and probably most interesting case, is the relational counterpart
to the \ARF{⟦λ⟧} combinator. The ability to evaluate the body of a \AIC{`λ} in
weakened environments, each extended by related values, and deliver synchronised
values is enough to guarantee that evaluating the lambdas in the original
environments will produce synchronised values.

\begin{code}
    R⟦λ⟧      :  {Γ : Cx} {σ τ : Ty} {f^A : □ (𝓔^A σ ⟶ 𝓜^A τ) Γ} {f^B : □ (𝓔^B σ ⟶ 𝓜^B τ) Γ} → (f^r :  {Δ : Cx} (inc : Γ ⊆ Δ) {u^A : 𝓔^A σ Δ} {u^B : 𝓔^B σ Δ} (u^R : rmodel 𝓔^R u^A u^B) → rmodel 𝓜^R  (f^A inc u^A) (f^B inc u^B)) →
                 rmodel 𝓜^R (𝓢^A.⟦λ⟧ f^A) (𝓢^B.⟦λ⟧ f^B)
\end{code}

All the remaining cases are similar. We show here the relational
counterpart of the application constructor: it states that given
two induction hypotheses (and the knowledge that the two environment
used are synchronised), one can combine them to obtain a proof
about the evaluation of an application-headed term.

\begin{code}
    R⟦$⟧      :  {Γ : Cx} {σ τ : Ty} {f^A : 𝓜^A (σ `→ τ) Γ} {f^B : 𝓜^B (σ `→ τ) Γ} {u^A : 𝓜^A σ Γ} {u^B : 𝓜^B σ Γ} → rmodel 𝓜^R f^A f^B → rmodel 𝓜^R u^A u^B → rmodel 𝓜^R (f^A 𝓢^A.⟦$⟧ u^A) (f^B 𝓢^B.⟦$⟧ u^B)
\end{code}
\AgdaHide{
\begin{code}
    R⟦⟨⟩⟧     :  {Γ : Cx} → rmodel 𝓜^R {_} {Γ} 𝓢^A.⟦⟨⟩⟧ 𝓢^B.⟦⟨⟩⟧
    R⟦tt⟧     :  {Γ : Cx} → rmodel 𝓜^R {_} {Γ} 𝓢^A.⟦tt⟧ 𝓢^B.⟦tt⟧
    R⟦ff⟧     :  {Γ : Cx} → rmodel 𝓜^R {_} {Γ} 𝓢^A.⟦ff⟧ 𝓢^B.⟦ff⟧
    R⟦if⟧   :  {Γ : Cx} {σ : Ty} {b^A : _} {b^B : _} {l^A r^A : _} {l^B r^B : _} → rmodel 𝓜^R {_} {Γ} b^A b^B → rmodel 𝓜^R l^A l^B → rmodel 𝓜^R {σ} r^A r^B →
                 rmodel 𝓜^R (𝓢^A.⟦if⟧ b^A l^A r^A) (𝓢^B.⟦if⟧ b^B l^B r^B)
infixl 10 _∙^R_
\end{code}}

For this specification to be useful, we need to verify that we can indeed
benefit from its introduction. This is witnessed by two facts. First, our
ability to prove a fundamental lemma stating that given relations satisfying
this specification, the evaluation of a term in related environments yields
related values; second, our ability to find with various instances of such
synchronised semantics. Let us start with the fundamental lemma.

\paragraph{Fundamental Lemma of Synchronisable Semantics}
The fundamental lemma is indeed provable. We introduce a \AM{Synchronised}
module parametrised by a record packing the evidence that two semantics are
\AR{Synchronisable}. This allows us to bring all of the corresponding relational
counterpart of term constructors into scope by \AK{open}ing the record. The
traversal then uses them to combine the induction hypotheses arising structurally.
We use \AF{[\_,\_,\_]\_∙^R\_} as a way to circumvent Agda's inhability to
infer \AR{𝓔^A}, \AR{𝓔^B} and \AR{𝓔^R}.

\begin{code}
_∙^R_ :  {ℓ^EA ℓ^EB ℓ^ER : Level} {𝓔^A : Model ℓ^EA} {𝓔^B : Model ℓ^EB} {𝓔^R : RModel 𝓔^A 𝓔^B ℓ^ER} {Δ Γ : Cx} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Γ -Env) 𝓔^B Δ} {σ : Ty} {u^A : 𝓔^A σ Δ} {u^B : _} → `∀[ 𝓔^R ] ρ^A ρ^B → rmodel 𝓔^R u^A u^B → `∀[ 𝓔^R ] (ρ^A `∙ u^A) (ρ^B `∙ u^B)
lookup^R (ρ^R ∙^R u^R) ze    = u^R
lookup^R (ρ^R ∙^R u^R) (su v)  = lookup^R ρ^R v

module Synchronised {ℓ^EA ℓ^MA ℓ^EB ℓ^MB : Level} {𝓔^A : Model ℓ^EA} {𝓜^A : Model ℓ^MA} {𝓢^A : Semantics 𝓔^A 𝓜^A} {𝓔^B : Model ℓ^EB} {𝓜^B : Model ℓ^MB} {𝓢^B : Semantics 𝓔^B 𝓜^B} {ℓ^RE ℓ^RM : Level} {𝓔^R : RModel 𝓔^A 𝓔^B ℓ^RE} {𝓜^R : RModel 𝓜^A 𝓜^B ℓ^RM} (𝓡 : Synchronisable 𝓢^A 𝓢^B 𝓔^R 𝓜^R) where
  open Synchronisable 𝓡
\end{code}\vspace{ -2.5em}
%<*relational>
\begin{code}
  lemma :  {Γ Δ : Cx} {σ : Ty} (t : Tm σ Γ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Γ -Env) 𝓔^B Δ} (ρ^R : `∀[ 𝓔^R ] ρ^A ρ^B) →
           rmodel 𝓜^R (let open Eval 𝓢^A in sem ρ^A t) (let open Eval 𝓢^B in sem ρ^B t)
  lemma (`var v)       ρ^R = R⟦var⟧ v ρ^R
  lemma (f `$ t)       ρ^R = R⟦$⟧ (lemma f ρ^R) (lemma t ρ^R)
  lemma (`λ t)         ρ^R = R⟦λ⟧ (λ inc u^R → lemma t (𝓔^R‿wk inc ρ^R ∙^R u^R))
  lemma `⟨⟩            ρ^R = R⟦⟨⟩⟧
  lemma `tt            ρ^R = R⟦tt⟧
  lemma `ff            ρ^R = R⟦ff⟧
  lemma (`if b l r)  ρ^R = R⟦if⟧ (lemma b ρ^R) (lemma l ρ^R) (lemma r ρ^R)
\end{code}
%</relational>

\paragraph{Examples of Synchronisable Semantics}

Our first example of two synchronisable semantics is proving the
fact that \AF{Renaming} and \AF{Substitution} have precisely the
same behaviour whenever the environment we use for \AF{Substitution}
is only made up of variables. The (mundane) proofs which mostly
consist of using the congruence of propositional equality are
left out.

\begin{code}
SynchronisableRenamingSubstitution :  Synchronisable Renaming Substitution
                                      (mkRModel (_≡_ ∘ `var)) (mkRModel _≡_)
\end{code}
\AgdaHide{
\begin{code}
SynchronisableRenamingSubstitution =
  record
    { 𝓔^R‿wk  = λ inc ρ^R → pack^R (PEq.cong (wk^⊢ _ inc) ∘ lookup^R ρ^R)
    ; R⟦var⟧    = λ v ρ^R → lookup^R ρ^R v
    ; R⟦$⟧      = PEq.cong₂ _`$_
    ; R⟦λ⟧      = λ r → PEq.cong `λ (r (step refl) PEq.refl)
    ; R⟦⟨⟩⟧     = PEq.refl
    ; R⟦tt⟧     = PEq.refl
    ; R⟦ff⟧     = PEq.refl
    ; R⟦if⟧   = λ eqb eql → PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ eqb eql)
    }
\end{code}}

We show with the lemma \AF{RenamingIsASubstitution} how the result
we meant to prove is derived directly from the fundamental lemma of
\AR{Synchronisable} semantics:

\begin{code}
RenamingIsASubstitution : {Γ Δ : Cx} {σ : Ty} (t : Tm σ Γ) (ρ : Γ ⊆ Δ) →
  wk^⊢ σ ρ t ≡ subst t (trans ρ (pack `var))
RenamingIsASubstitution t ρ = lemma t (pack^R (λ _ → PEq.refl))
  where open Synchronised SynchronisableRenamingSubstitution
\end{code}


Another example of a synchronisable semantics is Normalisation by Evaluation
which can be synchronised with itself. This may appear like mindless symbol
pushing but it is actually crucial to prove such a theorem: we can only
define a Partial Equivalence Relation~\cite{mitchell1996foundations} (PER)
on the model used to implement Normalisation by Evaluation. The proofs of
the more complex properties of the procedure will rely heavily on the fact
that the exotic elements that may exist in the host language are actually
never produced by the evaluation function run on a term as long as all the
elements of the environment used were, themselves, not exotic i.e. equal to
themselves according to the PER.

We start with the definition of the PER for the model. It is constructed
by induction on the type and ensures that terms which behave the same
extensionally are declared equal. Two values of type \AIC{`1} are
always trivially equal;  values of type \AIC{`2} are normal forms
and are declared equal when they are effectively syntactically the same;
finally functions are equal whenever given equal inputs they yield equal
outputs.

\begin{code}
open βιξη

EQREL : (σ : Ty) → [ Kr σ ⟶ Kr σ ⟶ const Set ]
EQREL `1     T U = ⊤
EQREL `2     T U = T ≡ U
EQREL (σ `→ τ)  T U =  {Δ : Cx} (inc : _ ⊆ Δ) {V W : Kr σ Δ} (eqVW : EQREL σ V W) →
                        EQREL τ (T inc V) (U inc W)

EQREL′ : RModel Kr Kr L.zero
EQREL′ = mkRModel (λ {σ} → EQREL σ)

PropEq : {C : Ty → Cx → Set} → RModel C C L.zero
PropEq = mkRModel _≡_
\end{code}

It is indeed a PER as witnessed by the (omitted here) \AF{symEQREL} and
\AF{transEQREL} functions and it respects weakening as \AF{wk^{EQREL}} shows.

\begin{code}
symEQREL : {Γ : Cx} (σ : Ty) {S T : Kr σ Γ} → EQREL σ S T → EQREL σ T S
\end{code}
\AgdaHide{
\begin{code}
symEQREL `1     eq = ⟨⟩
symEQREL `2     eq = PEq.sym eq
symEQREL (σ `→ τ)  eq = λ inc eqVW → symEQREL τ (eq inc (symEQREL σ eqVW))
\end{code}}\vspace{ -2.5em}%ugly but it works!
\begin{code}
transEQREL : {Γ : Cx} (σ : Ty) {S T U : Kr σ Γ} → EQREL σ S T → EQREL σ T U → EQREL σ S U
\end{code}
\AgdaHide{
\begin{code}
  -- We are in PER so reflEQREL is not provable
  -- but as soon as EQREL σ V W then EQREL σ V V
reflEQREL : {Γ : Cx} (σ : Ty) {S T : Kr σ Γ} → EQREL σ S T → EQREL σ S S

transEQREL `1     eq₁ eq₂ = ⟨⟩
transEQREL `2     eq₁ eq₂ = PEq.trans eq₁ eq₂
transEQREL (σ `→ τ)  eq₁ eq₂ =
  λ inc eqVW → transEQREL τ (eq₁ inc (reflEQREL σ eqVW)) (eq₂ inc eqVW)

reflEQREL σ eq = transEQREL σ eq (symEQREL σ eq)
\end{code}}\vspace{ -2.5em}%ugly but it works!
\begin{code}
wk^EQREL :  {Δ Γ : Cx} (σ : Ty) (inc : Γ ⊆ Δ) {T U : Kr σ Γ} → EQREL σ T U → EQREL σ (wk^Kr σ inc T) (wk^Kr σ inc U)
\end{code}
\AgdaHide{
\begin{code}
wk^EQREL `1     inc eq = ⟨⟩
wk^EQREL `2     inc eq = PEq.cong (wk^nf `2 inc) eq
wk^EQREL (σ `→ τ)  inc eq = λ inc′ eqVW → eq (trans inc inc′) eqVW
\end{code}}

The interplay of reflect and reify with this notion of equality has
to be described in one go because of their being mutually defined.
It confirms our claim that \AF{EQREL} is indeed an appropriate notion
of semantic equality: values related by \AF{EQREL} are reified to
propositionally equal normal forms whilst propositionally equal neutral
terms are reflected to values related by \AF{EQREL}.

\begin{code}
reify^EQREL    :  {Γ : Cx} (σ : Ty) {T U : Kr σ Γ} → EQREL σ T U → reify σ T ≡ reify σ U
reflect^EQREL  :  {Γ : Cx} (σ : Ty) {t u : Ne σ Γ} → t ≡ u → EQREL σ (reflect σ t) (reflect σ u)
\end{code}
\AgdaHide{
\begin{code}
reify^EQREL `1     EQTU = PEq.refl
reify^EQREL `2     EQTU = EQTU
reify^EQREL (σ `→ τ)  EQTU = PEq.cong `λ (reify^EQREL τ (EQTU (step refl) (reflect^EQREL σ PEq.refl)))

reflect^EQREL `1     eq = ⟨⟩
reflect^EQREL `2     eq = PEq.cong (`ne _) eq
reflect^EQREL (σ `→ τ)  eq = λ inc rel → reflect^EQREL τ (PEq.cong₂ _`$_ (PEq.cong (wk^ne (σ `→ τ) inc) eq) (reify^EQREL σ rel))

ifRelNorm :
      let open Semantics Normalise in
      {σ : Ty} {Γ : Cx} {b^A b^B : Kr `2 Γ} {l^A l^B r^A r^B : Kr σ Γ} →
      EQREL `2 b^A b^B → EQREL σ l^A l^B → EQREL σ r^A r^B →
      EQREL σ {Γ} (⟦if⟧ {σ} b^A l^A r^A) (⟦if⟧ {σ} b^B l^B r^B)
ifRelNorm {b^A = `tt}             PEq.refl l^R r^R = l^R
ifRelNorm {b^A = `ff}             PEq.refl l^R r^R = r^R
ifRelNorm {σ} {b^A = `ne _ ne} PEq.refl l^R r^R =
  reflect^EQREL σ (PEq.cong₂ (`if ne) (reify^EQREL σ l^R) (reify^EQREL σ r^R))
\end{code}}

And that's enough to prove that evaluating a term in two
environments related in a pointwise manner by \AF{EQREL}
yields two semantic objects themselves related by \AF{EQREL}.

%<*synchroexample>
\begin{code}
SynchronisableNormalise :  Synchronisable Normalise Normalise EQREL′ EQREL′
\end{code}
%</synchroexample>
\AgdaHide{
\begin{code}
SynchronisableNormalise =
  record  { 𝓔^R‿wk  = λ inc ρ^R → pack^R (wk^EQREL _ inc ∘ lookup^R ρ^R)
          ; R⟦var⟧   = λ v ρ^R → lookup^R ρ^R v
          ; R⟦$⟧     = λ f → f refl
          ; R⟦λ⟧     = λ r → r
          ; R⟦⟨⟩⟧    = ⟨⟩
          ; R⟦tt⟧    = PEq.refl
          ; R⟦ff⟧    = PEq.refl
          ; R⟦if⟧  = ifRelNorm
          }
\end{code}}

We omit the details of the easy proof but still recall the type
of the corollary of the fundamental lemma one obtains in this
case:

%<*synchroexample2>
\begin{code}
refl^Kr :  {Γ Δ : Cx} {σ : Ty} (t : Tm σ Γ) {ρ^A ρ^B : (Γ -Env) Kr Δ} (ρ^R : `∀[ EQREL′ ] ρ^A ρ^B) → let open Eval Normalise in EQREL σ (sem ρ^A t) (sem ρ^B t)
refl^Kr t ρ^R = lemma t ρ^R where open Synchronised SynchronisableNormalise
\end{code}
%</synchroexample2>


We can now move on to the more complex example of a proof
framework built generically over our notion of \AF{Semantics}

\subsection{Fusions of Evaluations}

When studying the meta-theory of a calculus, one systematically
needs to prove fusion lemmas for various semantics. For instance,
Benton et al.~\cite{benton2012strongly} prove six such lemmas
relating renaming, substitution and a typeful semantics embedding
their calculus into Coq. This observation naturally led us to
defining a fusion framework describing how to relate three semantics:
the pair we want to run sequentially and the third one they correspond
to. The fundamental lemma we prove can then be instantiated six times
to derive the corresponding corollaries.

The evidence that \AB{𝓢^A}, \AB{𝓢^B} and \AB{𝓢^C} are such
that \AB{𝓢^A} followed by \AB{𝓢^B} can be said to be equivalent
to \AB{𝓢^C} (e.g. think \AF{Substitution} followed by \AF{Renaming}
can be reduced to \AF{Substitution}) is packed in a record
\AR{Fusable} indexed by the three semantics but also three
relations. The first one (\AB{𝓔^R_{BC}}) states what it means
for two environment values of \AB{𝓢^B} and \AB{𝓢^C} respectively
to be related. The second one (\AB{𝓔^R}) characterises the triples
of environments (one for each one of the semantics) which are
compatible. Finally, the last one (\AB{𝓜^R}) relates values
in \AB{𝓢^B} and \AB{𝓢^C}'s respective models.

\begin{code}
record Fusable
  {ℓ^EA ℓ^MA ℓ^EB ℓ^MB ℓ^EC ℓ^MC ℓ^RE ℓ^REBC ℓ^RM : Level} {𝓔^A : Model ℓ^EA} {𝓔^B : Model ℓ^EB} {𝓔^C : Model ℓ^EC} {𝓜^A : Model ℓ^MA} {𝓜^B : Model ℓ^MB} {𝓜^C : Model ℓ^MC} (𝓢^A : Semantics 𝓔^A 𝓜^A) (𝓢^B : Semantics 𝓔^B 𝓜^B) (𝓢^C : Semantics 𝓔^C 𝓜^C)
  (𝓔^R‿BC : RModel 𝓔^B 𝓔^C ℓ^REBC)
  (𝓔^R :  {Θ Δ Γ : Cx} → (Γ -Env) 𝓔^A Δ → (Δ -Env) 𝓔^B Θ → (Γ -Env) 𝓔^C Θ → Set ℓ^RE)
  (𝓜^R : RModel 𝓜^B 𝓜^C ℓ^RM)
  : Set (ℓ^RM ⊔ ℓ^RE ⊔ ℓ^EC ⊔ ℓ^EB ⊔ ℓ^EA ⊔ ℓ^MA ⊔ ℓ^REBC) where
\end{code}
\AgdaHide{
\begin{code}
  module 𝓢^A = Semantics 𝓢^A
  module 𝓢^B = Semantics 𝓢^B
  module 𝓢^C = Semantics 𝓢^C
  field
\end{code}}

Similarly to the previous section, most of the fields of this
record describe what structure these relations need to have.
However, we start with something slightly different: given that
we are planing to run the \AR{Semantics} \AB{𝓢^B} \emph{after}
having run \AB{𝓢^A}, we need a way to extract a term from an
element of \AB{𝓢^A}'s model. Our first field is therefore
\ARF{reify^A}:

\begin{code}
    reify^A    : {σ : Ty} → [ 𝓜^A σ ⟶ Tm σ ]


  𝓡 : {Γ Δ Θ : Cx} {σ : Ty} (t : Tm σ Γ) → (Γ -Env) 𝓔^A Δ → (Δ -Env) 𝓔^B Θ → (Γ -Env) 𝓔^C Θ → Set _
  𝓡 t ρ^A ρ^B ρ^C =
    let eval^A = let open Eval 𝓢^A in sem
        eval^B = let open Eval 𝓢^B in sem
        eval^C = let open Eval 𝓢^C in sem
    in rmodel 𝓜^R (eval^B ρ^B (reify^A (eval^A ρ^A t))) (eval^C ρ^C t)

  field
\end{code}

Then come two constraints dealing with the relations talking
about evaluation environments. \ARF{𝓔^R‿∙} tells us how to
extend related environments: one should be able to push related
values onto the environments for \AB{𝓢^B} and \AB{𝓢^C} whilst
merely extending the one for \AB{𝓢^A} with a token value generated
using \ARF{embed}.

\ARF{𝓔^R‿wk} guarantees that it is always possible to weaken
the environments for \AB{𝓢^B} and \AB{𝓢^C} in a \AB{𝓔^R}
preserving manner.

\begin{code}
    𝓔^R‿∙   :  {Γ Δ Θ : Cx} {σ : Ty} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} {u^B : 𝓔^B σ Θ} {u^C : 𝓔^C σ Θ} → 𝓔^R ρ^A ρ^B ρ^C → rmodel 𝓔^R‿BC u^B u^C →
               𝓔^R  (wk[ 𝓢^A.wk ] (step refl) ρ^A `∙ 𝓢^A.embed ze)
                    (ρ^B `∙ u^B) (ρ^C `∙ u^C)

    𝓔^R‿wk  :  {Γ Δ Θ E : Cx} (inc : Θ ⊆ E) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
               𝓔^R ρ^A (wk[ 𝓢^B.wk ] inc ρ^B) (wk[ 𝓢^C.wk ] inc ρ^C)
\end{code}

Then we have the relational counterpart of the various term
constructors. As with the previous section, only a handful of
them are out of the ordinary. We will start with the \AIC{`var}
case. It states that fusion indeed happens when evaluating a
variable using related environments.

\begin{code}
    R⟦var⟧  :  {Γ Δ Θ : Cx} {σ : Ty} (v : Var σ Γ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} → 𝓔^R ρ^A ρ^B ρ^C → 𝓡 (`var v) ρ^A ρ^B ρ^C
\end{code}

The \AIC{`λ}-case puts some rather strong restrictions on the way
the λ-abstraction's body may be used by \AB{𝓢^A}: we assume it
is evaluated in an environment weakened by one variable and extended
using \AB{𝓢^A}'s \ARF{embed}. But it is quite natural to have these
restrictions: given that \ARF{reify^A} quotes the result back, we are
expecting this type of evaluation in an extended context (i.e. under
one lambda). And it turns out that this is indeed enough for all of
our examples.
The evaluation environments used by the semantics \AB{𝓢^B} and \AB{𝓢^C}
on the other hand can be arbitrarily weakened before being extended with
related values to be substituted for the variable bound by the \AIC{`λ}.

\begin{code}
    R⟦λ⟧    :
      {Γ Δ Θ : Cx} {σ τ : Ty} (t : Tm τ (Γ ∙ σ)) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
      (r :  {E : Cx} (inc : Θ ⊆ E) {u^B : 𝓔^B σ E} {u^C : 𝓔^C σ E} → rmodel 𝓔^R‿BC u^B u^C →
            let  ρ^A′ =  wk[ 𝓢^A.wk ] (step refl) ρ^A `∙ 𝓢^A.embed ze
                 ρ^B′ =  wk[ 𝓢^B.wk ] inc ρ^B `∙ u^B
                 ρ^C′ =  wk[ 𝓢^C.wk ] inc ρ^C `∙ u^C
            in 𝓡 t ρ^A′ ρ^B′ ρ^C′) →
       𝓡 (`λ t) ρ^A ρ^B ρ^C
\end{code}

The other cases are just a matter of stating that, given the
expected induction hypotheses, one can deliver a proof that
fusion can happen on the compound expression.

\AgdaHide{
\begin{code}
    R⟦$⟧    : {Γ Δ Θ : Cx} {σ τ : Ty} (f : Tm (σ `→ τ) Γ) (t : Tm σ Γ)
            {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} →
             (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
            𝓡 f ρ^A ρ^B ρ^C → 𝓡 t ρ^A ρ^B ρ^C → 𝓡 (f `$ t) ρ^A ρ^B ρ^C

    R⟦⟨⟩⟧   : {Γ Δ Θ : Cx} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} → 𝓔^R ρ^A ρ^B ρ^C → 𝓡 `⟨⟩ ρ^A ρ^B ρ^C
    R⟦tt⟧   : {Γ Δ Θ : Cx} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} → 𝓔^R ρ^A ρ^B ρ^C → 𝓡 `tt ρ^A ρ^B ρ^C
    R⟦ff⟧   : {Γ Δ Θ : Cx} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} → 𝓔^R ρ^A ρ^B ρ^C → 𝓡 `ff ρ^A ρ^B ρ^C
    R⟦if⟧ : {Γ Δ Θ : Cx} {σ : Ty} (b : Tm `2 Γ) (l r : Tm σ Γ)
            {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} →
            𝓔^R ρ^A ρ^B ρ^C →
            𝓡 b ρ^A ρ^B ρ^C →
            𝓡 l ρ^A ρ^B ρ^C →
            𝓡 r ρ^A ρ^B ρ^C →
            𝓡 (`if b l r) ρ^A ρ^B ρ^C
\end{code}}

\paragraph{Fundamental Lemma of Fusable Semantics}

As with synchronisation, we measure the usefulness of this framework
by the fact that we can prove its fundamental lemma first and that
we get useful theorems out of it second. Once again, having carefully
identified what the constraints should be, proving the fundamental
lemma turns out to amount to a simple traversal we choose to omit here.

\begin{code}
module Fusion {ℓ^EA ℓ^MA ℓ^EB ℓ^MB ℓ^EC ℓ^MC ℓ^RE ℓ^REB ℓ^RM : Level} {𝓔^A : Model ℓ^EA} {𝓔^B : Model ℓ^EB} {𝓔^C : Model ℓ^EC} {𝓜^A : Model ℓ^MA} {𝓜^B : Model ℓ^MB} {𝓜^C : Model ℓ^MC} {𝓢^A : Semantics 𝓔^A 𝓜^A} {𝓢^B : Semantics 𝓔^B 𝓜^B} {𝓢^C : Semantics 𝓔^C 𝓜^C} {𝓔^R‿BC : RModel 𝓔^B 𝓔^C ℓ^REB} {𝓔^R : {Θ Δ Γ : Cx} (ρ^A : (Γ -Env) 𝓔^A Δ) (ρ^B : (Δ -Env) 𝓔^B Θ) (ρ^C : (Γ -Env) 𝓔^C Θ) → Set ℓ^RE} {𝓜^R : RModel 𝓜^B 𝓜^C ℓ^RM} (fusable : Fusable 𝓢^A 𝓢^B 𝓢^C 𝓔^R‿BC 𝓔^R 𝓜^R) where
  open Fusable fusable

  lemma :  {Γ Δ Θ : Cx} {σ : Ty} (t : Tm σ Γ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
           𝓡 t ρ^A ρ^B ρ^C
\end{code}
\AgdaHide{
\begin{code}
  lemma (`var v)       ρ^R = R⟦var⟧ v ρ^R
  lemma (f `$ t)       ρ^R = R⟦$⟧ f t ρ^R (lemma f ρ^R) (lemma t ρ^R)
  lemma (`λ t)         ρ^R = R⟦λ⟧ t ρ^R (λ inc u^R → lemma t (𝓔^R‿∙ (𝓔^R‿wk inc ρ^R) u^R))
  lemma `⟨⟩            ρ^R = R⟦⟨⟩⟧ ρ^R
  lemma `tt            ρ^R = R⟦tt⟧ ρ^R
  lemma `ff            ρ^R = R⟦ff⟧ ρ^R
  lemma (`if b l r)  ρ^R = R⟦if⟧ b l r ρ^R (lemma b ρ^R) (lemma l ρ^R) (lemma r ρ^R)
\end{code}}

\paragraph{The Special Case of Syntactic Semantics}

Given that \AR{Syntactic} semantics use a lot of constructors
as their own semantic counterpart, it is possible to generate
evidence of them being fusable with much fewer assumptions.
We isolate them and prove the result generically in order to
avoid repeating ourselves.
A \AR{SyntacticFusable} record packs the evidence necessary to
prove that the \AR{Syntactic} semantics \AB{syn^A} and \AB{syn^B}
can be fused using the \AR{Syntactic} semantics \AB{syn^C}. It
is indexed by these three \AR{Syntactic}s as well as two relations
corresponding to the \AB{𝓔^R_{BC}} and \AB{𝓔^R} ones of the
\AR{Fusable} framework.

It contains the same \ARF{𝓔^R‿∙}, \ARF{𝓔^R‿wk} and \ARF{R⟦var⟧}
fields as a \AR{Fusable} as well as a fourth one (\ARF{embed^{BC}})
saying that \AB{syn^B} and \AB{syn^C}'s respective \ARF{embed}s are
producing related values.

\AgdaHide{
\begin{code}
record SyntacticFusable
  {ℓ^EA ℓ^EB ℓ^EC ℓ^REBC ℓ^RE : Level} {𝓔^A : Model ℓ^EA} {𝓔^B : Model ℓ^EB} {𝓔^C : Model ℓ^EC} (synA : Syntactic 𝓔^A)
  (synB : Syntactic 𝓔^B)
  (synC : Syntactic 𝓔^C)
  (𝓔^R‿BC : RModel 𝓔^B 𝓔^C ℓ^REBC)
  (𝓔^R : {Θ Δ Γ : Cx} (ρ^A : (Γ -Env) 𝓔^A Δ) (ρ^B : (Δ -Env) 𝓔^B Θ) (ρ^C : (Γ -Env) 𝓔^C Θ) → Set ℓ^RE)
  : Set (ℓ^RE ⊔ ℓ^REBC ⊔ ℓ^EC ⊔ ℓ^EB ⊔ ℓ^EA)
  where
  module Syn^A = Syntactic synA
  module Syn^B = Syntactic synB
  module Syn^C = Syntactic synC
  field
    𝓔^R‿∙ : ({Γ Δ Θ : Cx} {σ : Ty} {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ}
               {u^B : 𝓔^B σ Θ} {u^C : 𝓔^C σ Θ} (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) (u^R : rmodel 𝓔^R‿BC u^B u^C) →
               𝓔^R (wk[ Syn^A.wk ] (step refl) ρ^A `∙ Syn^A.embed ze)
                      (ρ^B `∙ u^B)
                      (ρ^C `∙ u^C))
    𝓔^R‿wk : {Γ Δ Θ E : Cx} (inc : Θ ⊆ E)
               {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ} (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
               𝓔^R ρ^A(wk[ Syn^B.wk ] inc ρ^B) (wk[ Syn^C.wk ] inc ρ^C)
    R⟦var⟧  : {Γ Δ Θ : Cx} {σ : Ty} (v : Var σ Γ) {ρ^A : (Γ -Env) 𝓔^A Δ} {ρ^B : (Δ -Env) 𝓔^B Θ} {ρ^C : (Γ -Env) 𝓔^C Θ}
              (ρ^R : 𝓔^R ρ^A ρ^B ρ^C) →
              Eval.sem (syntactic synB) ρ^B (Eval.sem (syntactic synA) ρ^A (`var v))
              ≡ Eval.sem (syntactic synC) ρ^C (`var v)
\end{code}}
\begin{code}
    embed^BC : {Γ : Cx} {σ : Ty} → rmodel 𝓔^R‿BC {_} {Γ ∙ σ} (Syn^B.embed ze) (Syn^C.embed ze)
\end{code}

The important result is that given a \AR{SyntacticFusable} relating
three \AR{Syntactic} semantics, one can deliver a \AR{Fusable} relating
the corresponding \AR{Semantics} where \AB{𝓜^R} is the propositional
equality.

\begin{code}
syntacticFusable :  {ℓ^EA ℓ^EB ℓ^EC ℓ^RE ℓ^REBC : Level} {𝓔^A : Model ℓ^EA} {𝓔^B : Model ℓ^EB} {𝓔^C : Model ℓ^EC} {syn^A : Syntactic 𝓔^A} {syn^B : Syntactic 𝓔^B} {syn^C : Syntactic 𝓔^C} {𝓔^R‿BC : RModel 𝓔^B 𝓔^C ℓ^REBC} {𝓔^R : {Θ Δ Γ : Cx} (ρ^A : (Γ -Env) 𝓔^A Δ) (ρ^B : (Δ -Env) 𝓔^B Θ) (ρ^C : (Γ -Env) 𝓔^C Θ) → Set ℓ^RE} (syn^R : SyntacticFusable syn^A syn^B syn^C 𝓔^R‿BC 𝓔^R) →
  Fusable (syntactic syn^A) (syntactic syn^B) (syntactic syn^C) 𝓔^R‿BC 𝓔^R PropEq
\end{code}
\AgdaHide{
\begin{code}
syntacticFusable synF =
  let open SyntacticFusable synF in
  record
    { reify^A    = id
    ; 𝓔^R‿∙   = 𝓔^R‿∙
    ; 𝓔^R‿wk  = 𝓔^R‿wk
    ; R⟦var⟧    = R⟦var⟧
    ; R⟦$⟧      = λ f t ρ^R → PEq.cong₂ _`$_
    ; R⟦λ⟧      = λ t ρ^R r → PEq.cong `λ (r (step refl) embed^BC)
    ; R⟦⟨⟩⟧     = λ ρ^R → PEq.refl
    ; R⟦tt⟧     = λ ρ^R → PEq.refl
    ; R⟦ff⟧     = λ ρ^R → PEq.refl
    ; R⟦if⟧   = λ b l r ρ^R eqb eql → PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ eqb eql)
    }

`var-inj : {Γ : Cx} {σ : Ty} {pr₁ pr₂ : Var σ Γ} (eq : (Tm σ Γ F.∋ `var pr₁) ≡ `var pr₂) → pr₁ ≡ pr₂
`var-inj PEq.refl = PEq.refl
\end{code}}

It is then trivial to prove that \AR{Renaming} can be fused with itself
to give rise to another renaming (obtained by composing the two context
inclusions): \ARF{𝓔^R‿∙} uses \AF{[\_,\_]}, a case-analysis combinator
for \AB{σ} \AD{∈} (\AB{Γ} \AIC{∙} τ) distinguishing the case where \AB{σ}
\AD{∈} \AB{Γ} and the one where \AB{σ} equals \AB{τ}, whilst the other connectives
are either simply combining induction hypotheses using the congruence of
propositional equality or even simply its reflexivity (the two \ARF{embed}s
we use are identical: they are both the one of \AF{syntacticRenaming} hence
why \ARF{embed^{BC}} is so simple).

\begin{code}
RenamingFusable :
  SyntacticFusable  syntacticRenaming syntacticRenaming syntacticRenaming
                    PropEq (λ ρ^A ρ^B ρ^C → ∀ σ pr → lookup (trans ρ^A ρ^B) pr ≡ lookup ρ^C pr)
RenamingFusable = record
  { 𝓔^R‿∙     = λ ρ^R eq → [ eq ,, ρ^R ]
  ; 𝓔^R‿wk    = λ inc ρ^R σ pr → PEq.cong (lookup inc) (ρ^R σ pr)
  ; R⟦var⟧    = λ v ρ^R → PEq.cong `var (ρ^R _ v)
  ; embed^BC  = PEq.refl }
\end{code}

Similarly, a \AR{Substitution} following a \AR{Renaming} is equivalent to
a \AR{Substitution} where the evaluation environment is the composition of
the two previous ones.

\begin{code}
RenamingSubstitutionFusable :
  SyntacticFusable syntacticRenaming syntacticSubstitution syntacticSubstitution
  PropEq (λ ρ^A ρ^B ρ^C → ∀ σ pr → lookup ρ^B (lookup ρ^A pr) ≡ lookup ρ^C pr)
\end{code}
\AgdaHide{
\begin{code}
RenamingSubstitutionFusable =
  record { 𝓔^R‿∙   = λ ρ^R eq → [ eq ,, ρ^R ]
         ; 𝓔^R‿wk  = λ inc ρ^R σ pr → PEq.cong (wk^⊢ σ inc) (ρ^R σ pr)
         ; R⟦var⟧    = λ v ρ^R → ρ^R _ v
         ; embed^BC   = PEq.refl }
\end{code}}

Using the newly established fact about fusing two \AR{Renamings} together,
we can establish that a \AR{Substitution} followed by a \AR{Renaming} is
equivalent to a \AR{Substitution} where the elements in the evaluation
environment have been renamed.

\begin{code}
SubstitutionRenamingFusable :
  SyntacticFusable syntacticSubstitution syntacticRenaming syntacticSubstitution
  (mkRModel (_≡_ ∘ `var)) (λ ρ^A ρ^B ρ^C → ∀ σ pr → wk^⊢ σ ρ^B (lookup ρ^A pr) ≡ lookup ρ^C pr)
\end{code}
\AgdaHide{
\begin{code}
SubstitutionRenamingFusable =
  let module RenRen = Fusion (syntacticFusable RenamingFusable) in
  record { 𝓔^R‿∙   = λ {_} {_} {_} {_} {ρ^A} {ρ^B} {ρ^C} ρ^R eq → [ eq ,, (λ σ pr →
                         PEq.trans (RenRen.lemma (lookup ρ^A pr) (λ _ _ → PEq.refl))
                                   (ρ^R σ pr)) ]
         ; 𝓔^R‿wk  = λ inc {ρ^A} {ρ^B} {ρ^C} ρ^R σ pr →
                         PEq.trans (PEq.sym (RenRen.lemma (lookup ρ^A pr) (λ _ _ → PEq.refl)))
                                   (PEq.cong (wk^⊢ σ inc) (ρ^R σ pr))
         ; R⟦var⟧    = λ v ρ^R → ρ^R _ v
         ; embed^BC   = PEq.refl }
\end{code}}

Finally, using the fact that we now know how to fuse a \AR{Substitution}
and a \AR{Renaming} together no matter in which order they are performed,
we can prove that two \AR{Substitution}s can be fused together to give
rise to another \AR{Substitution}.

\begin{code}
SubstitutionFusable :
  SyntacticFusable syntacticSubstitution syntacticSubstitution syntacticSubstitution
  PropEq (λ ρ^A ρ^B ρ^C → ∀ σ pr → subst (lookup ρ^A pr) ρ^B ≡ lookup ρ^C pr)
\end{code}
\AgdaHide{
\begin{code}
SubstitutionFusable =
  let module RenSubst = Fusion (syntacticFusable RenamingSubstitutionFusable)
      module SubstRen = Fusion (syntacticFusable SubstitutionRenamingFusable) in
  record { 𝓔^R‿∙   = λ {_} {_} {_} {_} {ρ^A} {ρ^B} {ρ^C} ρ^R eq → [ eq ,, (λ σ pr →
                         PEq.trans (RenSubst.lemma (lookup ρ^A pr) (λ _ _ → PEq.refl))
                                   (ρ^R σ pr)) ]
         ; 𝓔^R‿wk  = λ inc {ρ^A} {ρ^B} {ρ^C} ρ^R σ pr →
                         PEq.trans (PEq.sym (SubstRen.lemma (lookup ρ^A pr) (λ _ _ → PEq.refl)))
                                   (PEq.cong (wk^⊢ σ inc) (ρ^R σ pr))
         ; R⟦var⟧    = λ v ρ^R → ρ^R _ v
         ; embed^BC   = PEq.refl }

ifRenNorm :
      {Γ Δ Θ : Cx} {σ : Ty} (b : Tm `2 Γ) (l r : Tm σ Γ)
      {ρ^A : Γ ⊆ Δ} {ρ^B : (Δ -Env) Kr Θ}
      {ρ^C : (Γ -Env) Kr Θ} →
      (ρ^R : (σ : Ty) (pr : Var σ Γ) → EQREL σ (lookup ρ^B (lookup ρ^A pr)) (lookup ρ^C pr)) →
      Eval.sem Normalise ρ^B (wk^⊢ `2 ρ^A b) ≡ Eval.sem Normalise ρ^C b →
      EQREL σ (Eval.sem Normalise ρ^B (wk^⊢ σ ρ^A l)) (Eval.sem Normalise ρ^C l) →
      EQREL σ (Eval.sem Normalise ρ^B (wk^⊢ σ ρ^A r)) (Eval.sem Normalise ρ^C r) →
      EQREL σ (Eval.sem Normalise ρ^B (wk^⊢ σ ρ^A (`if b l r))) (Eval.sem Normalise ρ^C (`if b l r))
ifRenNorm b l r {ρ^A} {ρ^B} {ρ^C} ρ^R eqb eql eqr
  with Eval.sem Normalise  ρ^B (wk^⊢ _ ρ^A b)
     | Eval.sem Normalise ρ^C b
ifRenNorm b l r ρ^R PEq.refl eql eqr | `ne _ t | `ne _ .t =
  reflect^EQREL _ (PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ PEq.refl (reify^EQREL _ eql)) (reify^EQREL _ eqr))
ifRenNorm b l r ρ^R () eql eqr | `ne _ t | `tt
ifRenNorm b l r ρ^R () eql eqr | `ne _ t | `ff
ifRenNorm b l r ρ^R () eql eqr | `tt | `ne _ t
ifRenNorm b l r ρ^R PEq.refl eql eqr | `tt | `tt = eql
ifRenNorm b l r ρ^R () eql eqr | `tt | `ff
ifRenNorm b l r ρ^R () eql eqr | `ff | `ne _ t
ifRenNorm b l r ρ^R () eql eqr | `ff | `tt
ifRenNorm b l r ρ^R PEq.refl eql eqr | `ff | `ff = eqr
\end{code}}

These four lemmas are usually painfully proven one after the other. Here
we managed to discharge them by simply instantiating our framework four
times in a row, using the former instances to discharge the constraints
arising in the later ones. But we are not at all limited to proving
statements about \AR{Syntactic}s only.

\paragraph{Examples of Fusable Semantics}

The most simple example of \AR{Fusable} \AR{Semantics} involving a non
\AR{Syntactic} one is probably the proof that \AR{Renaming} followed
by \AR{Normalise^{βιξη}} is equivalent to Normalisation by Evaluation
where the environment has been tweaked.

\begin{code}
RenamingNormaliseFusable : Fusable Renaming Normalise Normalise EQREL′
  (λ ρ^A ρ^B ρ^C → ∀ σ pr → EQREL σ (lookup ρ^B (lookup ρ^A pr)) (lookup ρ^C pr)) EQREL′
\end{code}
\AgdaHide{
\begin{code}
RenamingNormaliseFusable =
  record
    { reify^A   = id
    ; 𝓔^R‿∙  = λ ρ^R u^R → [ u^R ,, ρ^R ]
    ; 𝓔^R‿wk = λ inc ρ^R → λ σ pr → wk^EQREL σ inc (ρ^R σ pr)
    ; R⟦var⟧   = λ v ρ^R → ρ^R _ v
    ; R⟦$⟧     = λ _ _ _ r → r refl
    ; R⟦λ⟧     = λ _ _ r → r
    ; R⟦⟨⟩⟧    = λ _ → ⟨⟩
    ; R⟦tt⟧    = λ _ → PEq.refl
    ; R⟦ff⟧    = λ _ → PEq.refl
    ; R⟦if⟧  = ifRenNorm
    }


ifSubstNorm :
     {Γ Δ Θ : Cx} {σ : Ty} (b : Tm `2 Γ) (l r : Tm σ Γ)
      {ρ^A : (Γ -Env) Tm Δ} {ρ^B : (Δ -Env) Kr Θ}
      {ρ^C : (Γ -Env) Kr Θ} →
      (`∀[ EQREL′ ] ρ^B ρ^B) ×
      ((σ₁ : Ty) (pr : Var σ₁ Γ) {Θ₁ : Cx} (inc : Θ ⊆ Θ₁) →
       EQREL σ₁
       (Eval.sem Normalise (pack (λ {σ} → wk^Kr σ inc ∘ lookup ρ^B)) (lookup ρ^A pr))
       (wk^Kr σ₁ inc (lookup ρ^C pr)))
      ×
      ((σ₁ : Ty) (pr : Var σ₁ Γ) →
       EQREL σ₁ (Eval.sem Normalise ρ^B (lookup ρ^A  pr)) (lookup ρ^C pr)) →
      Eval.sem Normalise ρ^B (subst b ρ^A) ≡ Eval.sem Normalise ρ^C b →
      EQREL σ (Eval.sem Normalise ρ^B (subst l ρ^A)) (Eval.sem Normalise ρ^C l) →
      EQREL σ (Eval.sem Normalise ρ^B (subst r ρ^A)) (Eval.sem Normalise ρ^C r) →
      EQREL σ (Eval.sem Normalise ρ^B (subst (`if b l r) ρ^A)) (Eval.sem Normalise ρ^C (`if b l r))
ifSubstNorm b l r {ρ^A} {ρ^B} {ρ^C} ρ^R eqb eql eqr
  with Eval.sem Normalise ρ^B (subst b ρ^A)
     | Eval.sem Normalise ρ^C b
ifSubstNorm b l r ρ^R PEq.refl eql eqr | `ne _ t | `ne _ .t =
  reflect^EQREL _ (PEq.cong₂ (uncurry `if) (PEq.cong₂ _,_ PEq.refl (reify^EQREL _ eql)) (reify^EQREL _ eqr))
ifSubstNorm b l r ρ^R () eql eqr | `ne _ t | `tt
ifSubstNorm b l r ρ^R () eql eqr | `ne _ t | `ff
ifSubstNorm b l r ρ^R () eql eqr | `tt | `ne _ t
ifSubstNorm b l r ρ^R PEq.refl eql eqr | `tt | `tt = eql
ifSubstNorm b l r ρ^R () eql eqr | `tt | `ff
ifSubstNorm b l r ρ^R () eql eqr | `ff | `ne _ t
ifSubstNorm b l r ρ^R () eql eqr | `ff | `tt
ifSubstNorm b l r ρ^R PEq.refl eql eqr | `ff | `ff = eqr

wk-refl : {Γ : Cx} (σ : Ty) {T U : Kr σ Γ} →
          EQREL σ T U → EQREL σ (wk^Kr σ refl T) U
wk-refl `1     eq = ⟨⟩
wk-refl `2     eq = PEq.trans (wk^nf-refl _) eq
wk-refl (σ `→ τ)  eq = eq

wk^2 : {Θ Δ Γ : Cx} (σ : Ty) (inc₁ : Γ ⊆ Δ) (inc₂ : Δ ⊆ Θ) {T U : Kr σ Γ} →
       EQREL σ T U → EQREL σ (wk^Kr σ inc₂ (wk^Kr σ inc₁ T)) (wk^Kr σ (trans inc₁ inc₂) U)
wk^2 `1     inc₁ inc₂ eq = ⟨⟩
wk^2 `2     inc₁ inc₂ eq = PEq.trans (wk^nf-trans inc₁ inc₂ _) (PEq.cong (wk^nf `2 (trans inc₁ inc₂)) eq)
wk^2 (σ `→ τ)  inc₁ inc₂ eq = λ inc₃ → eq (trans inc₁ (trans inc₂ inc₃))
\end{code}}

Then, we use the framework to prove that to \AR{Normalise^{βιξη}} by
Evaluation after a \AR{Substitution} amounts to normalising the original
term where the substitution has been evaluated first. The constraints
imposed on the environments might seem quite restrictive but they are
actually similar to the Uniformity condition described by C. Coquand~\cite{coquand2002formalised}
in her detailed account of Normalisation by Evaluation for a simply typed
$λ$-calculus with explicit substitution.


\begin{code}
SubstitutionNormaliseFusable : Fusable  Substitution Normalise Normalise
  EQREL′
  (λ ρ^A ρ^B ρ^C → `∀[ EQREL′ ] ρ^B ρ^B
                 × ((σ : Ty) (pr : Var σ _) {Θ : Cx} (inc : _ ⊆ Θ) →
                      EQREL σ (Eval.sem Normalise (pack (λ {σ} pr → wk^Kr σ inc (lookup ρ^B pr))) (lookup ρ^A pr)) (wk^Kr σ inc (lookup ρ^C pr)))
                 × ((σ : Ty) (pr : Var σ _) → EQREL σ (Eval.sem Normalise ρ^B (lookup ρ^A pr)) (lookup ρ^C pr)))
  EQREL′
\end{code}
\AgdaHide{
\begin{code}
SubstitutionNormaliseFusable =
  let module RenNorm = Fusion RenamingNormaliseFusable
      module EqNorm  = Synchronised SynchronisableNormalise in
  record
    { reify^A   = id
    ; 𝓔^R‿∙  = λ {_} {_} {_} {_} {ρ^A} {ρ^B} {ρ^C} ρ^R u^R →
                     (proj₁ ρ^R ∙^R reflEQREL _ u^R)
                   , [ (λ {Θ} inc → wk^EQREL _ inc u^R)
                     ,, (λ σ pr {Θ} inc →
                       transEQREL σ (RenNorm.lemma (lookup ρ^A pr)
                                                    (λ σ pr → wk^EQREL σ inc (lookup^R (proj₁ ρ^R) pr)))
                                    ((proj₁ ∘ proj₂) ρ^R σ pr inc)) ]
                     , [ u^R ,, (λ σ pr → transEQREL σ (RenNorm.lemma (lookup ρ^A pr) (λ _ → lookup^R (proj₁ ρ^R)))
                                          ((proj₂ ∘ proj₂) ρ^R σ pr)) ]
    ; 𝓔^R‿wk = λ inc {ρ^A} ρ^R → pack^R (λ pr → wk^EQREL _ inc (lookup^R (proj₁ ρ^R) pr))
                          , (λ σ pr inc′ →
       transEQREL σ (EqNorm.lemma (lookup ρ^A pr) (pack^R (λ {τ} v → transEQREL τ (wk^2 τ inc inc′ (lookup^R (proj₁ ρ^R) v)) (wk^EQREL τ (trans inc inc′) (lookup^R (proj₁ ρ^R) v)))))
       (transEQREL σ ((proj₁ (proj₂ ρ^R)) σ pr (trans inc inc′))
       (symEQREL σ (wk^2 σ inc inc′ (reflEQREL σ (symEQREL σ (proj₂ (proj₂ ρ^R) σ pr)))))))
                          , (λ σ pr → (proj₁ ∘ proj₂) ρ^R σ pr inc)
    ; R⟦var⟧   = λ v ρ^R → (proj₂ ∘ proj₂) ρ^R _ v
    ; R⟦$⟧     = λ _ _ _ r → r refl
    ; R⟦λ⟧     = λ _ _ r → r
    ; R⟦⟨⟩⟧    = λ _ → ⟨⟩
    ; R⟦tt⟧    = λ _ → PEq.refl
    ; R⟦ff⟧    = λ _ → PEq.refl
    ; R⟦if⟧  = ifSubstNorm
    }

both : {A B : Set} {a₁ a₂ : A} {b₁ b₂ : B} (eq : (A × B F.∋ a₁ , b₁) ≡ (a₂ , b₂)) → a₁ ≡ a₂ × b₁ ≡ b₂
both PEq.refl = PEq.refl , PEq.refl

∷-inj : {A : Set} {a b : A} {as bs : ∞ (Stream A)} (eq : (Stream A F.∋ a ∷ as) ≡ b ∷ bs) → a ≡ b × as ≡ bs
∷-inj PEq.refl = PEq.refl , PEq.refl
\end{code}}

Finally, we may use the notion of \AR{Fusable} to prove that our
definition of pretty-printing ignores \AR{Renamings}. In other
words, as long as the names provided for the free variables are
compatible after the renaming and as long as the name supplies
are equal then the string produced, as well as the state of the
name supply at the end of the process, are equal.

\begin{code}
RenamingPrettyPrintingFusable : Fusable Renaming Printing Printing PropEq
  (λ ρ^A ρ^B → `∀[ PropEq ] (trans ρ^A ρ^B))
  (mkRModel (λ p q → ∀ {names₁ names₂} → names₁ ≡ names₂ → runP p names₁ ≡ runP q names₂))
\end{code}
\AgdaHide{
\begin{code}
RenamingPrettyPrintingFusable = record
  { reify^A   = id
  ; 𝓔^R‿∙   = λ {Γ} {Δ} {Θ} {σ} {ρ^A} {ρ^B} {ρ^C} {u^B} {u^C} ρ^R eq → pack^R ((λ {σ} v → [_,,_] {P = λ σ v → lookup (trans (step ρ^A `∙ ze) (ρ^B `∙ u^B)) v ≡ lookup (ρ^C `∙ u^C) v} eq (λ σ v → lookup^R ρ^R v) σ v))
  ; 𝓔^R‿wk  = λ _ ρ^R → pack^R (PEq.cong (mkN ∘ getN) ∘ lookup^R ρ^R)
  ; R⟦var⟧   = λ v ρ^R → PEq.cong₂ (λ n ns → getN n , ns) (lookup^R ρ^R v)
  ; R⟦λ⟧     = λ t ρ^R r → λ { {n₁ ∷ n₁s} {n₂ ∷ n₂s} eq →
                        let (neq   , nseq) = ∷-inj eq
                            (ihstr , ihns) = both (r (step refl) (PEq.cong mkN neq) (PEq.cong ♭ nseq))
                        in PEq.cong₂ _,_ (PEq.cong₂ (λ n str → "λ" ++ n ++ ". " ++ str) neq ihstr) ihns }
  ; R⟦$⟧     = λ f t {ρ^A} {ρ^B} {ρ^C} ρ^R ihf iht eq →
                        let (ihstrf , eq₁) = both (ihf eq)
                            (ihstrt , eq₂) = both (iht eq₁)
                        in PEq.cong₂ _,_ (PEq.cong₂ (λ strf strt → strf ++ " (" ++ strt ++ ")") ihstrf ihstrt) eq₂
  ; R⟦⟨⟩⟧    = λ _ → PEq.cong _
  ; R⟦tt⟧    = λ _ → PEq.cong _
  ; R⟦ff⟧    = λ _ → PEq.cong _
  ; R⟦if⟧    = λ b l r {ρ^A} {ρ^B} {ρ^C} ρ^R ihb ihl ihr eq →
                       let (ihstrb , eq₁) = both (ihb eq)
                           (ihstrl , eq₂) = both (ihl eq₁)
                           (ihstrr , eq₃) = both (ihr eq₂)
                       in PEq.cong₂ _,_ (PEq.cong₂ (λ strb strlr → "if (" ++ strb ++ ") then (" ++ strlr)
                                        ihstrb (PEq.cong₂ (λ strl strr → strl ++ ") else (" ++ strr ++ ")")
                                        ihstrl ihstrr)) eq₃ }

tailComm : (Δ Γ : Cx) {names : Stream String} →
           tail (proj₂ (nameContext Δ Γ names)) ≡ proj₂ (nameContext Δ Γ (tail names))
tailComm Δ ε        = PEq.refl
tailComm Δ (Γ ∙ _)  = PEq.cong tail (tailComm Δ Γ)

proof : (Δ Γ : Cx) {names : Stream String} → proj₂ (nameContext Δ Γ names) ≡ Stream.drop (size Γ) names
proof Δ ε                = PEq.refl
proof Δ (Γ ∙ x) {n ∷ ns} = PEq.trans (tailComm Δ Γ) (proof Δ Γ)
\end{code}}
A direct corollary is that pretty printing a weakened closed term
amounts to pretty printing the term itself in a dummy environment.

\begin{code}
PrettyRenaming : {Γ : Cx} {σ : Ty} (t : Tm σ ε) (inc : ε ⊆ Γ) →
  print (wk^⊢ σ inc t) ≡ proj₁ (runP (Eval.sem Printing `ε t) (Stream.drop (size Γ) names))
PrettyRenaming {Γ} t inc = PEq.cong proj₁ (lemma t (pack^R (λ ())) (proof Γ Γ))
  where open Fusion RenamingPrettyPrintingFusable
\end{code}

\section{Related Work}

This work is at the intersection of two traditions: the formal treatment
of programming languages and the implementation of embedded Domain Specific
Languages (eDSL)~\cite{hudak1996building} both require the designer to
deal with name binding and the associated notions of renaming and substitution
but also partial evaluation~\cite{danvy1999type}, or even printing when
emitting code or displaying information back to the user~\cite{wiedijk2012pollack}.
The mechanisation of a calculus in a \emph{meta language} can use either
a shallow or a deep embedding~\cite{svenningsson2013combining,gill2014domain}.

The well-scoped and well typed final encoding described by Carette, Kiselyov,
and Shan~\cite{carette2009finally} allows the mechanisation of a calculus in
Haskell or OCaml by representing terms as expressions built up from the
combinators provided by a ``Symantics''. The correctness of the encoding
relies on parametricity~\cite{reynolds1983types} and although there exists
an ongoing effort to internalise parametricity~\cite{bernardy2013type} in
Type Theory, this puts a formalisation effort out of the reach of all the
current interactive theorem provers.

Because of the strong restrictions on the structure our \AF{Model}s may have,
we cannot represent all the interesting traversals imaginable. Chapman and
Abel's work on normalisation by evaluation~\cite{chapman2009type,abel2014normalization}
which decouples the description of the big-step algorithm and its termination
proof is for instance out of reach for our system. Indeed, in their development
the application combinator may \emph{restart} the computation by calling the
evaluator recursively whereas the \AF{Applicative} constraint we impose means
that we may only combine induction hypotheses.

McBride's original unpublished work~\cite{mcbride2005type} implemented
in Epigram~\cite{mcbride2004view} was inspired by Goguen and McKinna's
Candidates for Substitution~\cite{goguen1997candidates}. It focuses on
renaming and substitution for the simply typed $λ$-calculus and was later
extended to a formalisation of System F~\cite{girard1972interpretation}
in Coq~\cite{Coq:manual} by Benton, Hur, Kennedy and McBride~\cite{benton2012strongly}.
Benton et al. both implement a denotational semantics for their language
and prove the properties of their traversals. However both of these things
are done in an ad-hoc manner: the meaning function associated to their
denotational semantics is not defined in terms of the generic traversal
and the proofs are manually discharged one by one. 

Goguen and McKinna's Candidates for Substitution~\cite{goguen1997candidates}
begot work by McBride~\cite{mcbride2005type} 
and Benton, Hur, Kennedy and McBride~\cite{benton2012strongly} in Coq~\cite{Coq:manual}
showing how to alleviate the programmer's burden when she opts for the strongly typed
approach based on inductive families. Reasoning
about these definitions is still mostly done in an ad-hoc manner: Coq's tactics
do help them to discharge the four fusion lemmas involving renaming and substitution,
but the same work has to be repeated when studying the evaluation function. They
choose to prove the evaluation function correct by using propositional equality and
assuming function extensionality rather than resorting to the traditional Partial
Equivalence Relation approach we use.

\section{Conclusion}

We have explained how to make using an inductive family to only represent
the terms of an eDSL which are well-scoped and well typed by construction
more tractable. We proceeded by factoring out a common notion of \AR{Semantics}
encompassing a wide range of type and scope preserving traversals such as
renaming and substitution, which were already handled by the state of the
art~\cite{mcbride2005type,benton2012strongly}, but also pretty printing, or
various variations on normalisation by evaluation.
Our approach crucially relied on the careful distinction we made between
values in the environment and values in the model, as well as the slight
variation on the structure typical of Kripke-style models. Indeed, in our
formulation, the domain of a binder's interpretation is an environment
value rather than a model one.

We have then demonstrated that, having this shared structure, one could
further alleviate the implementer's pain by tackling the properties of
these \AR{Semantics} in a similarly abstract approach. We characterised,
using a first logical relation, the traversals which were producing
related outputs provided they were fed related inputs. A more involved
second logical relation gave us a general description of triples of
\AR{Fusable} semantics such that composing the two first ones would
yield an instance of the third one.


\bibliographystyle{abbrvnat}
\bibliography{main}

\appendix{}

\section{}


This yields, to the best of our knowledge, the
first tagless and typeful implementation of a Kripke-style Normalisation by Evaluation in Haskell. The
subtleties of working with dependent types in Haskell~\cite{lindley2014hasochism} are
outside the scope of this paper but we do provide a (commented) Haskell module containing
all the translated definitions. It should be noted that Danvy, Keller and Puech have achieved~\todo{\cite{atkey2009syntax}}
a similar goal in OCaml~\cite{danvytagless} but their formalisation uses parametric higher
order abstract syntax~\cite{chlipala2008parametric} which frees them from having to deal
with variable binding, contexts and use models à la Kripke. However we consider these to be
primordial: they can still guide the implementation of more complex type theories where,
until now, being typeful is still out of reach. Type-level guarantees about scope preservation
can help root out bugs related to fresh name generation, name capture or arithmetic on de
Bruijn levels to recover de Bruijn indices.


\end{document}
