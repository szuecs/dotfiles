var printf = function(s) {
    console.log(s);
};

var foo3 = function(bar) {
    {
        at: "foo";
        blah: function() {
            return this.at;
        }
    }
};

var an_f = function(b) {
    return b;
}

// TODO: use these variables
var a,
    c = 2;
var x,
    y = undefined;

c = 5 ;
/*
 * yet another
 * comment
 */
var just_a_test = function() {
    return "blah";
};
// this
// will be colapsed
// too
foo3.blah();
/*
 * here
 * is
 * a coment
 */
var saf = function(args) {
    return args + "";
};

saf('foo');

function foo() {
    var test = "Something";
    throw function() {
        return test;
    };
};

try {
    foo();
} catch(ex) {
    if (ex instanceof Function) {
        console.log(ex()); // displays "Something"
    } else {
        throw ex;
    }
}
