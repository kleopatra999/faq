# Perl 6 FAQ

Source can be found [on github](https://github.com/perl6/faq).

<span id="language" />
## Language Features

<span id="so" />
### What is `so`?

`so` is a loose precedence operator that coerces to `Bool`.

It has the same semantics as the `?` prefix operator, just like
`and` is the low-precedence version of `&&`.

Example usage:

    say so 1|2 == 2;    # Bool::True

In this example, the result of the comparison (which is a `Junction`), is
converted to Bool before being printed.

<span id="eigenstate" />
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


<span id="immutable" />
### If Str is immutable, how does `s///` work? if Int is immutable, how does `$i++` work?

In Perl 6, many basic types are immutable, but the variables holding them are
not. The `s///` operator works on a variable, into which it puts a newly
creates string object. Likewise `$i++` works on the `$i` variable, not
just on the value in it.

<span id="ref" />
### What's up with array references and automatic derferencing? Do I still need the `@` sigil?

In Perl 6, nearly everything is a reference, so talking about taking
references doesn't make much sense. Unlike Perl 5, scalar variables
can also contain arrays directly:

    my @a = 1, 2, 3;
    say @a;                 # "1 2 3\n"
    say @a.WHAT;            # Array()

    my $scalar = @a;
    say $scalar;            # "1 2 3\n"
    say $scalar.WHAT;       # Array()

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


<span id="sigils" />
### Why sigils? Couldn't you do without them?

There are several reasons:

* they make it easy to interpolate variables into strings
* they form micro-namespaces for different variables, thus avoiding name clashes
* they allow easy single/plural distinction
* many natural languages use mandatory noun markers, so our brains are built to handle it


<span id="coroutine" />
### Does Perl 6 have coroutines? What about `yield`?

Perl 6 has no `yield` statement like python does, but it does offer similar
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

<span id="privattr">
### Why can't I initialize private attributes from the new method, and how can I fix this?

A code like

    class A {
        has $!x;
        method show-x {
            say $!x;
        }
    }
    A.new(x => 5).show-x;

does not print 5. Private attributes are /private/, which means invisible to
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

<span id="say" />
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
of the type, followed by an empty pair of parenthesis (to indicate there's
nothing in that value except the type).

    my Date $x;     # $x now contains the Date type object
    print $x;       # empty string plus warning
    say $x;         # Date()\n

So `say` is optimized for debugging and display to people, `print` 
is more suitable for producing output for other programs to consume.

<span id="tokenrule" /> <span id="token" /> <span id="rule" />
### What's the difference between `token` and `rule` ?

`regex`, `token` and `rule` all three introduce regexes, but with
slightly different semantics.

`token` implies the `:ratchet` or `:r` modifier, which prevents the
rule from backtracking.

`rule` implies both the `:ratchet` and `:sigspace` (short `:s`)
modifer, which means a rule doesn't backtrace, and it treats
whitespace in the text of the regex as  `<.ws>` calls (ie
matches whitespace, which is optional except between two word
characters). Whitespace at the start of the regex and at the start
of each branch of an alternation is ignored.

`regex` declares a plain regex without any implied modifiers.

<span id="diefail" /><span id="fail">
### What's the difference between `die` and `fail`?

`die` throws an exception.

If `use fatal;` (which is dynamically scoped) is in scope, `fail` also
throws an exception. Otherwise it returns a `Failure` from the routine
it is called from. 

A `Failure` is an "unthrown" or "soft" exception. It is an object that
contains the exception, and throws the exception when the Failure is used
as an ordinary object.

A Failure returns False from a `defined` check, and you can exctract
the exception with the `exception` method.

<span id="want" /><span id="wantarray" />
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

<span id="meta" />
## Meta Questions and Advocacy

<span id="ready" />
### When will Perl 6 be ready? Is it ready now?

Readiness of programming languages and their compilers is not a binary
decision. As they (both the language and the implementations) evolve, they
grow steadily more usable. Depending on your demands on a programming
language, Perl 6 and its compilers might or might not be ready for you.

Please see the [feature comparison
matrix](http://perl6.org/compilers/features) for an overview of implemented
features.


<span id="features" />
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
* optional type annotations
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

<span id="needanswers" />
## Questions still wanting answers

(none at the moment)
