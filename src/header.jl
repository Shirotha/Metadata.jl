using TextParse, Nullables
using CatViews

import Base: Fix1, Fix2
import Base: ==
import Base: getindex, iterate, haskey, length, eltype, merge, size
import Base: @propagate_inbounds
import Base: _nextpow2 as nextpow2
import Base: parent
import Base: Ordering, Forward, ord, lt

import TextParse: AbstractToken, Numeric, StringToken, Quoted
import TextParse: LocalOpts, WrapLocalOpts, StrRange
import TextParse: tryparsenext

import Base: show


export readfromstring, readfromfile