<p align=center>
  <a href=https://goo.gl/BhrgjW>
    <img src=https://envygeeks.io/badges/paypal-large_1.png alt=Donate>
  </a>
  <br>
  <a href=https://travis-ci.org/envygeeks/liquid-tag-parser>
    <img src="https://travis-ci.org/envygeeks/liquid-tag-parser.svg?branch=master">
  </a>
</div>

# Liquid Tag Parser

Liquid Tag parser provides a robust interface to parsing your tag syntax in a way that makes sense, it uses `Shellwords`, along with escapes to allow users to do extremely robust arguments, giving you back a hash, that you get to play with.  It also has the concept of `argv1`, deep hashes, and even defaults if you give them to us.

## Usage

Typically you would take the raw argument data you get from Liquid and ship that to us, we will parse it, and return to you the data, as a class.  You can access hash keys with `#args` or you can access it with `#[]` on the class.

### With `argv1`

```ruby
Liquid::Tag::Parser.new("a b=1 c=2 !false d:e:f='3 4' @true").args
# => {
#   argv1: "a",
#   false: false,
#   true: true,
#   b: "1",
#   c: "2",
#   d: {
#     e: {
#       f: "3 4"
#     }
#   }
# }
```

### Without argv1

```ruby
Liquid::Tag::Parser.new("a=1 b=2 !false c:d:e=3:4:5 @true").args
# => {
#   false: false,
#   true: true,
#   a: "1",
#   b: "2",
#   c: {
#     d: {
#       e: "3:4:5"
#     }
#   }
# }
```

### With Array's

```ruby
Liquid::Tag::Parser.new("a=1 a=2 a=3").args
# => {
#   a: [
#     1, 2, 3
#   ]
# }
```

### Escaping

```ruby
Liquid::Tag::Parser.new("a=1=2").args
# => {
#   "a=1": 2
# }
```

```ruby
Liquid::Tag::Parser.new("a='1=2'").args
# => {
#   "a": "1=2"
# }
```
# }
```
