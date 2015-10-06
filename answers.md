# Perl 6 FAQ

Source can be found [on GitHub](https://github.com/perl6/faq).

<span id="language"></span>
## Language Features

<span id="so"></span>
### What is `so`?

[so](http://doc.perl6.org/routine/so) is a loose precedence operator
that coerces to [Bool](http://doc.perl6.org/type/Bool). The
logical opposite of [not](http://doc.perl6.org/routine/not), it returns
a `Bool` with a preserved
boolean value instead of the opposite one.

`so` has the same semantics as the `?` prefix operator, just like
`and` is the low-precedence version of `&&`.

Example usage:

    say so 1|2 == 2;    # Bool::True

In this example, the result of the comparison (which is a [Junction](http://doc.perl6.org/type/Junction)), is
converted to Bool before being printed.

<span id="mu"></span>
### What is the difference between `Any` and `Mu`?

[Mu](http://doc.perl6.org/type/Mu) is the base type from which all
other types are derived. [Any](http://doc.perl6.org/type/Mu) is
derived from `Mu`, and represents just about any kind of Perl 6
value.  The major distinction is that `Any` excludes `Junction`.

The default type for subroutine parameters is `Any`, so that when you
declare `sub foo ($a)`, you're really saying `sub foo (Any $a)`.  Similarly,
class declarations are presumed to inherit from `Any`, unless told 
otherwise with a trait like `is Mu`.

<span id="eigenstate"></span>
### How can I extract the values from a `Junction`?

If you want to extract the values (eigenstates) from a junction, you 
are probably doing something wrong. Junctions are meant as matchers, 
not for doing algebra with them.

If you want to do it anyway, you can abuse autothreading for that:

    sub eigenstates(Mu $j) {
        my @states;
        -> Any $s { @states.push: $s }.($j);
        @states;
    }

    say eigenstates(1|2|3).join(', ');
    # prints 1, 2, 3 or a permutation thereof


<span id="immutable"></span>
### If Str is immutable, how does `s///` work? if Int is immutable, how does `$i++` work?

In Perl 6, many basic types are immutable, but the variables holding them are
not. The `s///` operator works on a variable, into which it puts a newly
created string object. Likewise `$i++` works on the `$i` variable, not
just on the value in it.

See also: [documentation on
containers](http://doc.perl6.org/language/containers).

<span id="ref"></span>
### What's up with array references and automatic dereferencing? Do I still need the `@` sigil?

In Perl 6, nearly everything is a reference, so talking about taking
references doesn't make much sense. Unlike Perl 5, scalar variables
can also contain arrays directly:

    my @a = 1, 2, 3;
    say @a;                 # "1 2 3\n"
    say @a.WHAT;            # (Array)

    my $scalar = @a;
    say $scalar;            # "1 2 3\n"
    say $scalar.WHAT;       # (Array)

The big difference is that arrays inside a scalar variable do not flatten in
list context:

    my @a = 1, 2, 3;
    my $s = @a;

    for @a { ... }          # loop body executed 3 times
    for $s { ... }          # loop body executed only once

    my @flat = @a, @a;
    say @flat.elems;        # 6

    my @nested = $s, $s;
    say @nested.elems;      # 2

You can force flattening with `@( ... )` or by calling the `.list` method
on an expression, and item context (not flattening) with `$( ... )`
or by calling the `.item` method on an expression.

`[...]` array literals do not flatten into lists.

See also [the documentation on containers and
flattening](http://doc.perl6.org/language/containers).


<span id="sigils"></span>
### Why sigils? Couldn't you do without them?

There are several reasons:

* they make it easy to interpolate variables into strings
* they form micro-namespaces for different variables, thus avoiding name clashes
* they allow easy single/plural distinction
* many natural languages use mandatory noun markers, so our brains are built to handle it


<span id="coroutine"></span>
### Does Perl 6 have coroutines? What about `yield`?

Perl 6 has no `yield` statement like Python does, but it does offer similar
functionality through lazy lists. There are two popular ways to write
routines that return lazy lists:

    # first method, gather/take
    my @values := gather while have_data() {
        # do some computations
        take some_data();
        # do more computations
    }

    # second method, use .map or similar method
    # on a lazy list
    my @squares := (1..*).map(-> $x { $x * $x });

<span id="unspace"></span>
### Why do I need a backslash (unspace) to split method calls across multiple lines?

In Perl 6, a method call is like any other postfix operator. And all postfix
operators in Perl 6 disallow whitespace between the operator and its term:

    sub do-safely($codestr) {
        EVAL('$codestr');
        CATCH {
            default {
                say "error occurred"
            }
        }
    }

    do-safely('my $a = 41; say $a++');   # says "41"
    do-safely('my $a = 41; say $a ++');  # says "error occurred"

And the reason for that is because it can cause confusion between postfix
operators and infix operators. The standard operators in Perl 6 are laid out so
that the infix/postfix confusion can't result in using them, but it's all too
easy to make it happen.

Let's say you were to define your own `infix:<++>` for some reason. When you do
this, the infix operator *needs* space before it, lest it gets confused with the
postfix version:

    #| Post-increment the left side $b times
    sub infix:<++>($a is rw, $b) { my $old = $a; $a++ for ^$b; $old }

    my $a = 35;

    say $a ++ 7;  # says 35 ($a is now 42)
    say $a ++7;   # says 42 ($a is now 49)
    say $a++7;    # parse error (compiler sees $a++ followed by a stray 7)
    say $a++ 7;   # parse error (same reason as above)

(Just to note, space isn't always required around an infix operator, it's only a
requirement when there's a postfix operator with the same name.)

So, we use space to distinguish a postfix operator and infix operator. If we
allowed whitespace before a postfix operator, then whenever you defined your own
`infix:<++>` your postfix operators could get confused:

    sub infix:<++>($a is rw, $b) { my $old = $a; $a++ for ^$b; $old }
    my $a = 41;

    say $a ++;  # "Missing required term after infix", because there's an infix:<++> now

Imagine using a module that suddenly added an infix operator spelled the same as
a postfix. In a world where you could put space before a postfix operator, that
"Missing required term" error would suddenly start showing up everywhere.

Fortunately, the unspace lets you tell the compiler to ignore whitespace between
two tokens (in the grammatical sense of "token") where it would otherwise cause
problems:

    my $a = 41;
    say $a\ ++;  # just like $a++

And this is what lets you line up method calls on a dot, or even right after it:

    say (-42.6).abs\
               .round.\  # yeah, .round. is weird. Just for illustration here.
                atan;

<span id="privattr"></span>
### Why can't I initialize private attributes from the new method, and how can I fix this?

A code like

    class A {
        has $!x;
        method show-x {
            say $!x;
        }
    }
    A.new(x => 5).show-x;

does not print 5. Private attributes are *private*, which means invisible to
the outside. If the default constructor could initialize them, they would leak
into the public API.

If you still want it to work, you can add a `submethod BUILD` that 
initializes them:

    class B {
        has $!x;
        submethod BUILD(:$!x) { }
        method show-x {
            say $!x;
        }
    }
    A.new(x => 5).show-x;

`BUILD` is called by the default constructor (indirectly, see
<http://perlgeek.de/blog-en/perl-6/object-construction-and-initialization.html>
for more details) with all the named arguments that the user passes to the
constructor. `:$!x` is a named parameter with name `x`, and when called
with a named argument of name `x`, its value is bound to the attribute `$!x`.

But if you allow setting private attributes from the outside, maybe they
should really be public instead?

<span id="say"></span>
### How and why do `say` and `print` differ?

The most obvious difference is that `say` appends a newline at the
end of the output, and `print` does not.

But there is another difference: `print` converts its arguments to
a string by calling the `Str` method on each item passed to, `say`
uses the `gist` method instead. The former is meant for computers,
the latter for human interpretation.

Or phrased differently, `$obj.Str` gives a string representation,
`$obj.gist` a short summary of that object suitable for fast recognition
by the programmer, and `$obj.perl` gives a Perlish representation.

For example type objects, also known as "undefined values", stringify
to an empty string and warn, whereas the `gist` method returns the name
of the type inside a pair of parenthesis (to indicate there's
nothing in that value except the type).

    my Date $x;     # $x now contains the Date type object
    print $x;       # empty string plus warning
    say $x;         # (Date)\n

So `say` is optimized for debugging and display to people, `print` 
is more suitable for producing output for other programs to consume.

<span id="tokenrule"></span> <span id="token"></span> <span id="rule"></span>
### What's the difference between `token` and `rule` ?

`regex`, `token` and `rule` all three introduce regexes, but with
slightly different semantics.

`token` implies the `:ratchet` or `:r` modifier, which prevents the
rule from backtracking.

`rule` implies both the `:ratchet` and `:sigspace` (short `:s`)
modifer, which means a rule doesn't backtrack, and it treats
whitespace in the text of the regex as  `<.ws>` calls (ie
matches whitespace, which is optional except between two word
characters). Whitespace at the start of the regex and at the start
of each branch of an alternation is ignored.

`regex` declares a plain regex without any implied modifiers.

<span id="diefail"></span><span id="fail"></span>
### What's the difference between `die` and `fail`?

`die` throws an exception.

If `use fatal;` (which is dynamically scoped) is in scope, `fail` also
throws an exception. Otherwise it returns a `Failure` from the routine
it is called from. 

A `Failure` is an "unthrown" or "soft" exception. It is an object that
contains the exception, and throws the exception when the Failure is used
as an ordinary object.

A Failure returns False from a `defined` check, and you can extract
the exception with the `exception` method.

<span id="want"></span><span id="wantarray"></span>
### Why is `wantarray` or `want` gone? Can I return different things in different contexts?

Perl has the `wantarray` function that tells you whether it is called in
void, scalar or list context. Perl 6 has no equivalent construct,
because context does not flow inwards, i.e. a routine cannot know which
context it is called in.

One reason is that Perl 6 has multi dispatch, and in a code example like

    multi w(Int $x) { say 'Int' }
    multi w(Str $x) { say 'Str' }
    w(f());

there is no way to determine if the caller of sub `f` wants a string or
an integer, because it is not yet known what the caller is. In general
this requires solving the halting problem, which even Perl 6 compiler
writers have trouble with.

The way to achieve context sensitivity in Perl 6 is to return an object
that knows how to respond to method calls that are typical for a context.

For example regex matches return [Match objects that know how to respond
to list indexing, hash indexing, and that can turn into the matched
string](http://doc.perl6.org/type/Match).

<span id="num"></span>
### Why can't I assign all numbers to variable typed `Num`?

    my Num $x = 42;
    # dies with
    # Type check failed in assignment to '$x'; expected 'Num' but got 'Int'

[Num](http://doc.perl6.org/type/Num) is a floating-point type, and not
compatible with [integers](http://doc.perl6.org/type/Int). If you want a type
constraint that allows any numeric values, use
[Numeric](http://doc.perl6.org/type/Numeric) (which also allows
[complex numbers](http://doc.perl6.org/type/Complex)), or
[Real](http://doc.perl6.org/type/Real) if you want to exclude complex numbers.

<span id="meta"></span>
## Meta Questions and Advocacy

<span id="ready"></span>
### When will Perl 6 be ready? Is it ready now?

Readiness of programming languages and their compilers is not a binary
decision. As they (both the language and the implementations) evolve, they
grow steadily more usable. Depending on your demands on a programming
language, Perl 6 and its compilers might or might not be ready for you.

Please see the [feature comparison
matrix](http://perl6.org/compilers/features) for an overview of implemented
features.

Please note that Larry Wall has announced at the FOSDEM in 2015, that a
production release of Rakudo Perl 6 is planned for Christmas *2015*.


<span id="features"></span>
### Why should I learn Perl 6? What's so great about it?

Perl 6 unifies many great ideas that aren't usually found in other programming
languages. While several other languages offer some of these features, none of
them offer all.

Unlike most languages, it offers

* cleaned up regular expressions
* [PEG](http://en.wikipedia.org/wiki/Parsing_expression_grammar) like grammars for parsing
* lazy lists
* a powerful meta object system
* junctions of values
* easy access to higher-order functional features like partial application and currying
* separate mechanism for subtyping (inheritance) and code reuse (role application)
* optional type annotations (gradual typing)
* powerful run-time multi dispatch for both subroutines and methods based on
  arity, types and additional code constraints
* lexical imports

It also offers

* closures
* anonymous types
* roles and traits
* named arguments
* nested signatures
* object unpacking in signatures
* intuitive, nice syntax (unlike Lisp)
* easy to understand, explicit scoping rules (unlike Python)
* a strong meta object system that does not rely on eval (unlike Ruby)
* expressive routine signatures (unlike Perl 5)
* state variables
* named regexes for easy reuse
* unlike many dynamic languages, calls to missing subroutines are caught
  at compile time, and in some cases even signature mismatches can be
  caught at compile time.

Please see the [feature comparison
matrix](http://perl6.org/compilers/features) for an overview of implemented
features.

<span id="cpan"></span><span id="CPAN"></span>
## Is there a CPAN for Perl 6? Or will Perl 6 use the Perl 5 CPAN?

There isn't yet a module repository for Perl 6 as sophisticated as CPAN.
But [modules.perl6.org](http://modules.perl6.org/) has a list of known
Perl 6 modules, and [panda](https://github.com/tadzik/panda/) can install
and precompile those that work with [rakudo](http://rakudo.org/).

<span id="naming"></span>
## Why not renaming to something other than "Perl"?

Many people have suggested that Perl 6 is different enough from the previous
Perl versions that we should consider renaming it, often also in the context
of implying that Perl 6 hurts Perl 5, simply by having the same name
and a larger version number.

The original reason for naming it "Perl 6" was that Perl 6 was, in fact, meant
to be the successor to Perl 5. It all started when Perl 5 was in a slump, in
terms of community interest and activity, and [the throwing of some coffee
mugs](http://strangelyconsistent.org/blog/happy-10th-anniversary-perl-6) led to
work on Perl 6 starting, a sequel meant to revitalize the Perl community.

A few years in, however, renewed interest in Perl 5 appeared when Perl 6
appeared to be taking too long to develop. So with Perl 5 being improved
concurrently alongside Perl 6's development, we end up where we are today: two
languages, neither the successor to the other.

So the name in the first place is a historical artifact, like anything that
still has the word "new" in its title (e.g. "New York", "new object model").

The main reasons that Perl 6 still has "Perl" in the name are:

* Perl 6 is still a very perlish language, following the same underlying ideas
  as previous versions (sigils for mini-namespaces, There Is More Than One Way
  To Do It, caring about both [manipulexity and
  whipuptitude](http://www.perl.com/pub/2006/01/12/what_is_perl_6.html),
  taking many ideas from natural language (like disambiguation through
  context))
* Perl 6 code feels very perlish. A Perl 5 program using Moose or a similar
  object system feels closer to Perl 6 than to Perl 1 code
* Even if Perl 6 changed its name, an incremental update to Perl 5 likely
  couldn't claim the version 6, because the name Perl 6 sticks in people's
  heads, and will long be associated with what it is today
* "Perl" is still a strong brand name, which we don't want to throw away
  lightly
* It is very hard to find a good alternative name. And no, "camelia"
  and "rakudo" are not good names for a programming language (even if they are
  fine for our mascot and the leading compiler)

<span id="needanswers"></span>
## Questions still wanting answers

(none at the moment)
