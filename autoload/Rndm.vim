" Rndm:
"  Author:  Charles E. Campbell, Jr.
"  Date:    Aug 12, 2008
"  Version: 4f	ASTRO-ONLY
"
"  Discussion:  algorithm developed at MIT
"
"           <Rndm.vim> uses three pseudo-random seed variables
"              g:rndm_m1 g:rndm_m2 g:rndm_m3
"           Each should be on the interval 0 - 100,000,000
"
" RndmInit(s1,s2,s3): takes three arguments to set the three seeds (optional)
" Rndm()            : generates a pseudo-random variate on [0,100000000)
" Urndm(a,b)        : generates a uniformly distributed pseudo-random variate
"                     on the interval [a,b]
" Dice(qty,sides)   : emulates a variate from sum of "qty" user-specified
"                     dice, each of which can take on values [1,sides]
" SetDeck(N)        : returns a pseudo-random "deck" of integers from 1..N
"                     (actually, a list of pseudo-randomly distributed integers)
"
"Col 2:8: Be careful that you don't let anyone rob you through his philosophy
"         and vain deceit, after the tradition of men, after the elements of
"         the world, and not after Christ.

" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("loaded_Rndm")
 finish
endif
let g:loaded_Rndm = "v4f"
let s:keepcpo     = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Randomization Variables: {{{1
" with a little extra randomized start from localtime()
let g:rndm_m1 = 32007779 + (localtime()%100 - 50)
let g:rndm_m2 = 23717810 + (localtime()/86400)%100
let g:rndm_m3 = 52636370 + (localtime()/3600)%100

" ---------------------------------------------------------------------
" RndmInit: allow user to initialize pseudo-random number generator seeds {{{1
fun! RndmInit(...)
"  call Dfunc("RndmInit() a:0=".a:0)

  if a:0 >= 3
   " set seed to specified values
   let g:rndm_m1 = a:1
   let g:rndm_m2 = a:2
   let g:rndm_m3 = a:3
"   call Decho("set seeds to [".g:rndm_m1.",".g:rndm_m2.",".g:rndm_m3."]")

  elseif filereadable($HOME."/.seed")
   " initialize the pseudo-random seeds by reading the .seed file
   " when doing this, one should also save seeds at the end-of-script
   " by calling RndmSave().
   let keeplz= &lz
   let eikeep= &ei
   set lz ei=all

   1split
   exe "silent! e ".expand("$HOME")."/.seed"
   let curbuf= bufnr("%")
"   call Decho("curbuf=".curbuf." fname<".expand("%").">")
   silent! s/ /\r/g
   exe "let g:rndm_m1=".getline(1)
   exe "let g:rndm_m2=".getline(2)
   exe "let g:rndm_m3=".getline(3)
"   call Decho("set seeds to [".g:rndm_m1.",".g:rndm_m2.",".g:rndm_m3."]")
   silent! q!
   if bufexists(curbuf)
    exe curbuf."bw!"
   endif

   let &lz= keeplz
   let &ei= eikeep
  endif
"  call Dret("RndmInit")
endfun

" ---------------------------------------------------------------------
" RndmSave: this function saves the current pseudu-random number seeds {{{2
fun! RndmSave()
"  call Dfunc("RndmSave()")
  if expand("$HOME") != "" && exists("g:rndm_m1") && exists("g:rndm_m2") && exists("g:rndm_m3")
   let keeplz= &lz
   let eikeep= &ei
   set lz ei=all

   1split
   enew
   call setline(1,"".g:rndm_m1." ".g:rndm_m2." ".g:rndm_m3)
   exe "w! ".expand("$HOME")."/.seed"
   let curbuf= bufnr(".")
   silent! q!
   if curbuf > 0
    exe "silent! ".curbuf."bw!"
   endif

   let &lz= keeplz
   let &ei= eikeep
  endif
"  call Dret("RndmSave")
endfun

" ---------------------------------------------------------------------
" Rndm: generate pseudo-random variate on [0,100000000) {{{1
fun! Rndm()
  let m4= g:rndm_m1 + g:rndm_m2 + g:rndm_m3
  if( g:rndm_m2 < 50000000 )
    let m4= m4 + 1357
  endif
  if( m4 >= 100000000 )
    let m4= m4 - 100000000
    if( m4 >= 100000000 )
      let m4= m4 - 100000000
    endif
  endif
  let g:rndm_m1 = g:rndm_m2
  let g:rndm_m2 = g:rndm_m3
  let g:rndm_m3 = m4
  return g:rndm_m3
endfun

" ---------------------------------------------------------------------
" Urndm: generate uniformly-distributed pseudo-random variate on [a,b] {{{1
fun! Urndm(a,b)

  " sanity checks
  if a:b < a:a
   return 0
  endif
  if a:b == a:a
   return a:a
  endif

  " Using modulus: rnd%(b-a+1) + a  loses high-bit information
  " and makes for a poor random variate.  Following code uses
  " rejection technique to adjust maximum interval range to
  " a multiple of (b-a+1)
  let amb       = a:b - a:a + 1
  let maxintrvl = 100000000 - ( 100000000 % amb)
  let isz       = maxintrvl / amb

  let rnd= Rndm()
  while rnd > maxintrvl
   let rnd= Rndm()
  endw

  return a:a + rnd/isz
endfun

" ---------------------------------------------------------------------
" Dice: assumes one is rolling a qty of dice with "sides" sides. {{{1
"       Example - to roll 5 four-sided dice, call Dice(5,4)
fun! Dice(qty,sides)
  let roll= 0

  let sum= 0
  while roll < a:qty
   let sum = sum + Urndm(1,a:sides)
   let roll= roll + 1
  endw

  return sum
endfun

" ---------------------------------------------------------------------
" SetDeck: this function returns a "deck" of integers from 1-N (actually, a list) {{{1
fun! SetDeck(N)
"  call Dfunc("SetDeck(N=".a:N.")")
  let deck = []
  let n    = 1
  " generate a sequential list of integers
  while n <= a:N
   let deck= add(deck,n)
   let n       = n + 1
  endwhile
  " generate a random deck using swaps
  let n= a:N-1
  while n > 0
   let p= Urndm(0,a:N-1)
   if n != p
	let swap    = deck[n]
	let deck[n] = deck[p]
	let deck[p] = swap
   endif
   let n= n - 1
  endwhile
"  call Dret("SetDeck")
  return deck
endfun

" ---------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
"  Modelines: {{{1
"  vim: fdm=marker
doc/Rndm.txt	[[[1
117
*rndm.txt*	Pseudo-Random Number Generator		Oct 03, 2008

Author:  Charles E. Campbell, Jr.  <cec@NgrOyphSon.gPsfAc.nMasa.gov>
	  (remove NOSPAM from Campbell's email first)
Copyright: (c) 2004-2008 by Charles E. Campbell, Jr.	*rndm-copyright*
           The VIM LICENSE applies to Rndm.vim and Rndm.txt
           (see |copyright|) except use "Rndm" instead of "Vim"
	   No warranty, express or implied.  Use At-Your-Own-Risk.

==============================================================================
1. Contents						*rndm* *rndm-contents*

	1. Contents......................: |rndm-contents|
	2. Rndm Manual...................: |rndm-manual|
	3. History.......................: |rndm-history|

==============================================================================

2. Rndm Manual			*rndmman* *rndmmanual* *rndm-manual*

	To Enable: put <Rndm.vim> into your .vim/plugin

 /=============+============================================================\
 || Commands   |      Explanation                                          ||
 ++------------+-----------------------------------------------------------++
 || RndmInit() |  RndmInit(m1,m2,m3)                                       ||
 || RndmInit() |  RndmInit()                                               ||
 ||            +-----------------------------------------------------------++
 ||            | RndmInit takes three integers between [0-100,000,000)     ||
 ||            | to initialize the pseudo-random number generator          ||
 ||            |                                                           ||
 ||            | If no arguments are given, then RmdmInit() will attempt   ||
 ||            | to read the $HOME/.seed file which should contain three   ||
 ||            | numbers, also [0,100 000 000).  With this format, the     ||
 ||            | script should call RndmSave() when done.                  ||
 ||            |                                                           ||
 ++============+===========================================================++
 || RndmSave() | This function saves the current values of the three       ||
 ||            | pseudo-random number generator seeds in $HOME/.seed       ||
 ||            | Use call RndmInit() (no arguments) to initialize the      ||
 ||            | generator with these seeds.                               ||
 ||            |                                                           ||
 ++============+===========================================================++
 || Rndm()     |  Rndm()                                                   ||
 ||            +-----------------------------------------------------------++
 ||            | Generates a pseudo-random variable on [0 - 100,000,000)   ||
 ||            |                                                           ||
 ++============+===========================================================++
 || Urndm()    |  Urndm(a,b)                                               ||
 ||            +-----------------------------------------------------------++
 ||            | Generates a uniformly distributed pseudo-random variable  ||
 ||            | on the interval [a,b]                                     ||
 ||            |                                                           ||
 ++============+===========================================================++
 || Dice()     |  Dice(qty,sides)                                          ||
 ||            +-----------------------------------------------------------++
 ||            | Assumes one is rolling a quantity "qty" of dice, each     ||
 ||            | having "sides" sides.                                     ||
 ||            | Example: dice(5,4) returns a variate based on rolling     ||
 ||            |          5 4-sided dice and summing the results           ||
 ||            |                                                           ||
 \==========================================================================/

The pseudo-random number generator used herein was developed at MIT.

I used D. Knuth's ent program (http://www.fourmilab.ch/random/) and generated
one million (1,000,000) values using a C program variant: >
	rv= Rndm()/3906.25   (which divides one million into 256 equal regions)
and converted the result into a byte.  The report from Knuth's ent program:

    Entropy = 7.999825 bits per byte.

    Optimum compression would reduce the size
    of this 1000000 byte file by 0 percent.

    Chi square distribution for 1000000 samples is 242.41, and randomly
    would exceed this value 70.44 percent of the times.

    Arithmetic mean value of data bytes is 127.5553 (127.5 = random).
    Monte Carlo value for Pi is 3.135732543 (error 0.19 percent).
    Serial correlation coefficient is 0.001313 (totally uncorrelated = 0.0).

These values are quite good (a true random source, for example, had a
chi square distribution value of 249.51, for example -- from Knuth's page).

However, the results for the low-order byte aren't good: >
	rv=Rndm()%8     (which essentially looks at just the low order byte)
The report from Knuth's ent program:

    Entropy = 2.999996 bits per byte.

    Optimum compression would reduce the size
    of this 1000000 byte file by 62 percent.

    Chi square distribution for 1000000 samples is 31000155.62, and randomly
    would exceed this value less than 0.01 percent of the times.

    Arithmetic mean value of data bytes is 3.4987 (127.5 = random).
    Monte Carlo value for Pi is 4.000000000 (error 27.32 percent).
    Serial correlation coefficient is 0.000782 (totally uncorrelated = 0.0).

The Urndm() function, which generates pseudo-random variates from [a,b],
preferentially uses the high order bits, and so has good near-random behavior.

==============================================================================

3. History							*rndm-history*

   4 May 23, 2005 : * cpo use standardized while loading
     Feb 16, 2007   * RndmInit() (no arguments) now reads $HOME/.seed
     Feb 16, 2007   * wrote RndmSave()
   3 May 28, 2004 : * now supports initial "extra randomization" by using the
                      localtime() clock.

==============================================================================

vim:tw=78:ts=8:ft=help
