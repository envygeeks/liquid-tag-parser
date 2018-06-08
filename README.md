[![Code Climate](https://img.shields.io/codeclimate/maintainability/envygeeks/liquid-tag-parser.svg?style=for-the-badge)](https://codeclimate.com/github/envygeeks/liquid-tag-parser/maintainability)
[![Code Climate](https://img.shields.io/codeclimate/c/envygeeks/liquid-tag-parser.svg?style=for-the-badge)](https://codeclimate.com/github/envygeeks/liquid-tag-parser/coverage)
[![Travis CI](https://img.shields.io/travis/envygeeks/liquid-tag-parser/master.svg?style=for-the-badge)](https://travis-ci.org/envygeeks/liquid-tag-parser)
[![Donate](https://img.shields.io/badge/-DONATE-yellow.svg?style=for-the-badge)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LKGZAWXLZ8ZPG)
![Gem Version](https://img.shields.io/gem/v/liquid-tag-parser.svg?style=for-the-badge)
![Gem DL](https://img.shields.io/gem/dt/liquid-tag-parser.svg?style=for-the-badge)

# Liquid Tag Parser

Liquid Tag parser provides a robust interface to parsing your tag syntax in a way that makes sense, it uses `Shellwords`, along with escapes to allow users to do extremely robust arguments, giving you back a hash, that you get to play with.  It also has the concept of `argv1`, deep hashes, and even defaults if you give them to us.

## Installation

```ruby
gem "liquid-tag-parser", "~> 1.9"
```

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

#### Escaping `argv1`

```ruby
https://www.googletagmanager.com/gtag/js?id=UA-18997298-1
Liquid::Tag::Parser.new("'a=1'").args
# => {
#   argv1: "a=1"
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

### Booleans
#### True

```ruby
Liquid::Tag::Parser.new("@true").args
# => {
#   true: true
# }
```

```ruby
Liquid::Tag::Parser.new("@key1:key2").args
# => {
#   key1: {
#     key2: true
#   }
# }
```

#### False

```ruby
Liquid::Tag::Parser.new("!false").args
# => {
#   false: false
# }
```

```ruby
Liquid::Tag::Parser.new("!key1:key2").args
# => {
#   key1: {
#     key2: false
#   }
# }
```
